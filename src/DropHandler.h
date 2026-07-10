#pragma once

#include <QObject>
#include <QString>
#include <QWindow>

#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>

class DropHandler : public QObject, public IDropTarget
{
    Q_OBJECT

public:
    explicit DropHandler(QObject *parent = nullptr);
    ~DropHandler() override;

    void registerWindow(QWindow *window);
    void unregisterWindow();

    // IDropTarget
    HRESULT __stdcall QueryInterface(REFIID riid, void **ppvObject) override;
    ULONG __stdcall AddRef() override;
    ULONG __stdcall Release() override;
    HRESULT __stdcall DragEnter(IDataObject *pDataObj, DWORD grfKeyState, POINTL pt, DWORD *pdwEffect) override;
    HRESULT __stdcall DragOver(DWORD grfKeyState, POINTL pt, DWORD *pdwEffect) override;
    HRESULT __stdcall DragLeave() override;
    HRESULT __stdcall Drop(IDataObject *pDataObj, DWORD grfKeyState, POINTL pt, DWORD *pdwEffect) override;

signals:
    void fileDropped(QString path);

private:
    LONG m_refCount = 1;
    HWND m_hwnd = nullptr;
    bool m_registered = false;

    QStringList extractFilePaths(IDataObject *pDataObj);
};
