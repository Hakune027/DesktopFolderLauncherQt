#include "DropHandler.h"

#include <QDebug>
#include <QMetaObject>
#include <QUrl>
#include <QFileInfo>
#include <QScopedArrayPointer>
#include <QStandardPaths>
#include <QDir>
#include <QCryptographicHash>
#include <QRegularExpression>
#include <shobjidl.h>

namespace {
FORMATETC shellIdListFormat()
{
    FORMATETC format = {};
    format.cfFormat = static_cast<CLIPFORMAT>(RegisterClipboardFormatW(CFSTR_SHELLIDLIST));
    format.dwAspect = DVASPECT_CONTENT;
    format.lindex = -1;
    format.tymed = TYMED_HGLOBAL;
    return format;
}

QString materializeShellShortcut(PCIDLIST_ABSOLUTE absolute, IShellItem *shellItem)
{
    if (!absolute || !shellItem)
        return {};

    PWSTR displayName = nullptr;
    QString name = QStringLiteral("Store App");
    if (SUCCEEDED(shellItem->GetDisplayName(SIGDN_NORMALDISPLAY, &displayName))) {
        name = QString::fromWCharArray(displayName).trimmed();
        CoTaskMemFree(displayName);
    }
    name.replace(QRegularExpression(QStringLiteral("[<>:\"/\\\\|?*\\x00-\\x1f]")),
                 QStringLiteral("_"));
    if (name.isEmpty())
        name = QStringLiteral("Store App");

    QString dataDirectory = qEnvironmentVariable("DESK_FOLDER_DATA_DIR");
    if (dataDirectory.isEmpty())
        dataDirectory = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    const QString shortcutDirectory = QDir(dataDirectory).filePath(QStringLiteral("shortcuts"));
    if (!QDir().mkpath(shortcutDirectory))
        return {};

    const UINT idListSize = ILGetSize(absolute);
    const QByteArray idListBytes(reinterpret_cast<const char *>(absolute),
                                 static_cast<qsizetype>(idListSize));
    const QString hash = QString::fromLatin1(QCryptographicHash::hash(
        idListBytes, QCryptographicHash::Sha256).toHex().left(16));
    const QString shortcutPath = QDir(shortcutDirectory).filePath(
        QStringLiteral("%1-%2.lnk").arg(name.left(80), hash));
    if (QFileInfo::exists(shortcutPath))
        return shortcutPath;

    IShellLinkW *shellLink = nullptr;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&shellLink))))
        return {};
    QString result;
    if (SUCCEEDED(shellLink->SetIDList(absolute))) {
        const std::wstring description = name.toStdWString();
        shellLink->SetDescription(description.c_str());
        IPersistFile *persistFile = nullptr;
        if (SUCCEEDED(shellLink->QueryInterface(IID_PPV_ARGS(&persistFile)))) {
            const std::wstring nativePath = QDir::toNativeSeparators(shortcutPath).toStdWString();
            if (SUCCEEDED(persistFile->Save(nativePath.c_str(), TRUE)))
                result = shortcutPath;
            persistFile->Release();
        }
    }
    shellLink->Release();
    return result;
}
}

DropHandler::DropHandler(QObject *parent)
    : QObject(parent)
{
}

DropHandler::~DropHandler()
{
    unregisterWindow();
}

void DropHandler::registerWindow(QWindow *window)
{

    if (!window)
        return;

    HWND hwnd =
        reinterpret_cast<HWND>(
            window->winId());

    // 检查是否已注册
    for (auto &entry : m_entries)
    {

        if (entry.hwnd == hwnd)
            return;
    }

    HRESULT hr =
        RegisterDragDrop(
            hwnd,
            this);

    if (SUCCEEDED(hr))
    {

        WindowEntry entry;

        entry.hwnd = hwnd;

        m_entries.append(entry);

        qDebug()
            << "DropHandler: 注册窗口"
            << hwnd;
    }
    else if (hr == DRAGDROP_E_ALREADYREGISTERED)
    {
        // Qt 内部已注册 IDropTarget, 无需重复注册
        qDebug()
            << "DropHandler: 窗口已有拖放目标, 跳过注册"
            << hwnd;
    }
    else
    {

        qWarning()
            << "DropHandler: RegisterDragDrop 失败"
            << Qt::hex << hr;
    }
}

void DropHandler::registerWindowTarget(
    QWindow *window,
    QObject *target,
    const QString &method)
{

    if (!window || !target)
        return;

    HWND hwnd =
        reinterpret_cast<HWND>(
            window->winId());

    // 查找已有 entry 或创建新 entry
    WindowEntry *existing = nullptr;

    for (auto &entry : m_entries)
    {

        if (entry.hwnd == hwnd)
        {
            existing = &entry;

            break;
        }
    }

    if (existing)
    {

        existing->target = target;

        existing->method = method;
    }
    else
    {

        HRESULT hr =
            RegisterDragDrop(
                hwnd,
                this);

        if (SUCCEEDED(hr))
        {

            WindowEntry entry;

            entry.hwnd = hwnd;

            entry.target = target;

            entry.method = method;

            m_entries.append(entry);

            qDebug()
                << "DropHandler: 注册窗口(带目标)"
                << hwnd
                << target->metaObject()->className();
        }
        else if (hr == DRAGDROP_E_ALREADYREGISTERED)
        {
            // Dynamic folder windows need a deterministic native target. Replace
            // Qt's target because external Explorer drops are not always routed
            // to a QML DropArea on frameless transparent windows.
            RevokeDragDrop(hwnd);
            hr = RegisterDragDrop(hwnd, this);
            if (SUCCEEDED(hr)) {
                WindowEntry entry;
                entry.hwnd = hwnd;
                entry.target = target;
                entry.method = method;
                m_entries.append(entry);
                qDebug() << "DropHandler: replaced existing window drop target" << hwnd;
            } else {
                qWarning() << "DropHandler: failed to replace window drop target"
                           << Qt::hex << hr;
            }
        }
        else
        {

            qWarning()
                << "DropHandler: RegisterDragDrop 失败"
                << Qt::hex << hr;
        }
    }
}

void DropHandler::unregisterWindowTarget(
    QWindow *window)
{

    if (!window)
        return;

    HWND hwnd =
        reinterpret_cast<HWND>(
            window->winId());

    for (int i = 0; i < m_entries.size(); ++i)
    {

        if (m_entries[i].hwnd == hwnd)
        {

            RevokeDragDrop(hwnd);

            m_entries.removeAt(i);

            qDebug()
                << "DropHandler: 反注册窗口"
                << hwnd;

            return;
        }
    }
}

void DropHandler::unregisterWindow()
{

    for (auto &entry : m_entries)
    {

        RevokeDragDrop(entry.hwnd);
    }

    m_entries.clear();
}

// IUnknown
HRESULT __stdcall DropHandler::QueryInterface(REFIID riid, void **ppvObject)
{
    if (!ppvObject)
    {
        return E_POINTER;
    }

    if (riid == IID_IUnknown || riid == IID_IDropTarget)
    {
        *ppvObject = static_cast<IDropTarget *>(this);
        AddRef();
        return S_OK;
    }

    *ppvObject = nullptr;
    return E_NOINTERFACE;
}

ULONG __stdcall DropHandler::AddRef()
{
    return InterlockedIncrement(&m_refCount);
}

ULONG __stdcall DropHandler::Release()
{
    // NOTE: lifetime is managed externally (heap-allocated), not via COM ref-count
    LONG count = InterlockedDecrement(&m_refCount);
    Q_UNUSED(count);
    return m_refCount;
}

HRESULT __stdcall DropHandler::DragEnter(
    IDataObject *pDataObj,
    DWORD grfKeyState,
    POINTL pt,
    DWORD *pdwEffect)
{
    Q_UNUSED(grfKeyState);
    Q_UNUSED(pt);

    if (!pDataObj || !pdwEffect)
    {
        return E_INVALIDARG;
    }

    // Check if the data object contains file paths
    FORMATETC fmt = {};
    fmt.cfFormat = CF_HDROP;
    fmt.dwAspect = DVASPECT_CONTENT;
    fmt.lindex = -1;
    fmt.tymed = TYMED_HGLOBAL;

    FORMATETC shellFormat = shellIdListFormat();
    if (pDataObj->QueryGetData(&fmt) == S_OK
        || pDataObj->QueryGetData(&shellFormat) == S_OK)
    {
        *pdwEffect = DROPEFFECT_COPY;
    }
    else
    {
        *pdwEffect = DROPEFFECT_NONE;
    }

    return S_OK;
}

HRESULT __stdcall DropHandler::DragOver(
    DWORD grfKeyState,
    POINTL pt,
    DWORD *pdwEffect)
{
    Q_UNUSED(grfKeyState);
    Q_UNUSED(pt);

    if (!pdwEffect)
    {
        return E_INVALIDARG;
    }

    *pdwEffect = DROPEFFECT_COPY;
    return S_OK;
}

HRESULT __stdcall DropHandler::DragLeave()
{
    return S_OK;
}

DropHandler::WindowEntry *
DropHandler::findEntryByPoint(
    LONG x,
    LONG y)
{

    POINT screenPt = {x, y};

    HWND hwnd = WindowFromPoint(screenPt);

    // 向上遍历父窗口链, 查找已注册的 window
    while (hwnd)
    {

        for (auto &entry : m_entries)
        {

            if (entry.hwnd == hwnd)
            {

                return &entry;
            }
        }

        hwnd = GetParent(hwnd);
    }

    return nullptr;
}

HRESULT __stdcall DropHandler::Drop(
    IDataObject *pDataObj,
    DWORD grfKeyState,
    POINTL pt,
    DWORD *pdwEffect)
{
    Q_UNUSED(grfKeyState);

    if (!pDataObj || !pdwEffect)
    {
        return E_INVALIDARG;
    }

    QStringList files = extractFilePaths(pDataObj);

    if (files.isEmpty())
    {
        *pdwEffect = DROPEFFECT_NONE;
        return S_OK;
    }

    // 根据屏幕坐标找到目标窗口
    WindowEntry *entry =
        findEntryByPoint(pt.x, pt.y);

    if (entry && entry->target)
    {

        // 直接调用目标的 addFile 方法
        for (const QString &file : files)
        {

            const bool invoked = QMetaObject::invokeMethod(
                entry->target,
                entry->method.toUtf8().constData(),
                Q_ARG(QString, file));
            if (!invoked)
                qWarning() << "DropHandler: target method invocation failed" << entry->method;
        }
    }
    else
    {

        // 无目标回调, 发射通用信号
        for (const QString &file : files)
        {

            emit fileDropped(file);
        }
    }

    *pdwEffect = DROPEFFECT_COPY;
    return S_OK;
}

QStringList DropHandler::extractFilePaths(IDataObject *pDataObj)
{
    QStringList result;

    FORMATETC fmt = {};
    fmt.cfFormat = CF_HDROP;
    fmt.dwAspect = DVASPECT_CONTENT;
    fmt.lindex = -1;
    fmt.tymed = TYMED_HGLOBAL;

    STGMEDIUM medium = {};

    if (SUCCEEDED(pDataObj->GetData(&fmt, &medium))) {
        HDROP hDrop = static_cast<HDROP>(medium.hGlobal);
        const UINT fileCount = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
        for (UINT i = 0; i < fileCount; ++i)
        {
            const UINT pathLen = DragQueryFileW(hDrop, i, nullptr, 0);
            if (pathLen > 0) {
                QScopedArrayPointer<wchar_t> buffer(new wchar_t[pathLen + 1]);
                DragQueryFileW(hDrop, i, buffer.data(), pathLen + 1);
                result.append(QString::fromWCharArray(buffer.data()));
            }
        }
        ReleaseStgMedium(&medium);
        if (!result.isEmpty())
            return result;
    }

    // Store applications and some Start-menu shortcuts expose Shell ID lists
    // instead of CF_HDROP, even when the visible item is a desktop .lnk file.
    FORMATETC shellFormat = shellIdListFormat();
    STGMEDIUM shellMedium = {};
    if (FAILED(pDataObj->GetData(&shellFormat, &shellMedium)))
        return result;

    const auto *cida = static_cast<const CIDA *>(GlobalLock(shellMedium.hGlobal));
    if (!cida) {
        ReleaseStgMedium(&shellMedium);
        return result;
    }
    const auto *base = reinterpret_cast<const BYTE *>(cida);
    const auto *parent = reinterpret_cast<PCIDLIST_ABSOLUTE>(base + cida->aoffset[0]);
    for (UINT i = 0; i < cida->cidl; ++i) {
        const auto *child = reinterpret_cast<PCUIDLIST_RELATIVE>(base + cida->aoffset[i + 1]);
        PIDLIST_ABSOLUTE absolute = ILCombine(parent, child);
        if (!absolute)
            continue;
        IShellItem *shellItem = nullptr;
        if (SUCCEEDED(SHCreateItemFromIDList(absolute, IID_PPV_ARGS(&shellItem)))) {
            bool itemAdded = false;
            PWSTR displayName = nullptr;
            if (SUCCEEDED(shellItem->GetDisplayName(SIGDN_FILESYSPATH, &displayName))) {
                const QString path = QString::fromWCharArray(displayName);
                if (QFileInfo::exists(path)) {
                    result.append(path);
                    itemAdded = true;
                }
                CoTaskMemFree(displayName);
            }
            if (!itemAdded) {
                const QString shortcut = materializeShellShortcut(absolute, shellItem);
                if (!shortcut.isEmpty())
                    result.append(shortcut);
            }
            shellItem->Release();
        }
        ILFree(absolute);
    }
    GlobalUnlock(shellMedium.hGlobal);
    ReleaseStgMedium(&shellMedium);
    return result;
}
