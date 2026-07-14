# DesktopFolderLauncher

一个基于 Qt 6 / Qt Quick 的 Windows 桌面文件分组启动器。每个分组显示为独立置顶窗口，支持拖放文件、图标位置调整和窗口位置恢复。

## 构建

需要 Qt 6.5+、CMake 3.21+ 和支持 C++17 的编译器。

```powershell
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
```

## 数据

配置保存在 `QStandardPaths::AppLocalDataLocation`，图标缓存在 `QStandardPaths::CacheLocation`。配置通过原子写入保存；无法解析的文件会保留并复制为 `.corrupt`，便于人工恢复。

## 目前的平台范围

原生 OLE 拖放实现依赖 Windows API，因此当前正式支持 Windows。QML 内也提供了标准 URL 拖放路径。
