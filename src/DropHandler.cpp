#include "DropHandler.h"

#include <QDebug>
#include <QUrl>

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
    if (!window || m_registered)
    {
        return;
    }

    m_hwnd = reinterpret_cast<HWND>(window->winId());

    HRESULT hr = RegisterDragDrop(m_hwnd, this);
    if (SUCCEEDED(hr))
    {
        m_registered = true;
        qDebug() << "DropHandler: Registered OLE drop target on HWND" << m_hwnd;
    }
    else
    {
        qWarning() << "DropHandler: RegisterDragDrop failed, HRESULT:" << Qt::hex << hr;
    }
}

void DropHandler::unregisterWindow()
{
    if (m_registered && m_hwnd)
    {
        RevokeDragDrop(m_hwnd);
        m_registered = false;
        m_hwnd = nullptr;
    }
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

    if (pDataObj->QueryGetData(&fmt) == S_OK)
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

HRESULT __stdcall DropHandler::Drop(
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

    QStringList files = extractFilePaths(pDataObj);

    for (const QString &file : files)
    {
        emit fileDropped(file);
    }

    *pdwEffect = files.isEmpty() ? DROPEFFECT_NONE : DROPEFFECT_COPY;
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

    if (FAILED(pDataObj->GetData(&fmt, &medium)))
    {
        return result;
    }

    HDROP hDrop = static_cast<HDROP>(medium.hGlobal);

    UINT fileCount = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);

    for (UINT i = 0; i < fileCount; ++i)
    {
        UINT pathLen = DragQueryFileW(hDrop, i, nullptr, 0);
        if (pathLen > 0)
        {
            wchar_t *buffer = new wchar_t[pathLen + 1];
            DragQueryFileW(hDrop, i, buffer, pathLen + 1);
            result.append(QString::fromWCharArray(buffer));
            delete[] buffer;
        }
    }

    ReleaseStgMedium(&medium);
    return result;
}
