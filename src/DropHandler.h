#pragma once

#include <QObject>
#include <QPointer>
#include <QWindow>
#include <QList>

#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>

class DropHandler : public QObject,
                    public IDropTarget
{

    Q_OBJECT

public:
    explicit DropHandler(QObject *parent = nullptr);

    ~DropHandler();

    // 简单注册(无回调, 仅启用 OLE drop)
    void registerWindow(QWindow *window);

    // 带目标回调的注册: drop 时自动调用 target->method(path)
    Q_INVOKABLE
    void registerWindowTarget(
        QWindow *window,
        QObject *target,
        const QString &method);

    void unregisterWindow();

    // 反注册单个窗口
    Q_INVOKABLE
    void unregisterWindowTarget(
        QWindow *window);

    // IDropTarget
    HRESULT __stdcall QueryInterface(
        REFIID riid,
        void **ppvObject) override;

    ULONG __stdcall AddRef() override;

    ULONG __stdcall Release() override;

    HRESULT __stdcall DragEnter(
        IDataObject *,
        DWORD,
        POINTL,
        DWORD *) override;

    HRESULT __stdcall DragOver(
        DWORD,
        POINTL,
        DWORD *) override;

    HRESULT __stdcall DragLeave()
        override;

    HRESULT __stdcall Drop(
        IDataObject *,
        DWORD,
        POINTL,
        DWORD *) override;

signals:

    // 通用信号(无窗口信息时使用)
    void fileDropped(QString path);

private:
    struct WindowEntry
    {
        HWND hwnd;
        QPointer<QObject> target;
        QString method;
    };

    LONG m_refCount = 1;

    QList<WindowEntry> m_entries;

    QStringList extractFilePaths(
        IDataObject *pDataObj);

    // 根据屏幕坐标查找已注册窗口的 entry
    WindowEntry *findEntryByPoint(
        LONG x,
        LONG y);
};
