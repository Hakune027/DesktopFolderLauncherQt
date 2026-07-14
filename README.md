# DeskFolder

一个轻量、可定制的 Windows 桌面文件夹工具。把常用程序、文件和快捷方式整理成桌面卡片，需要时展开，不需要时保持紧凑。

![1](docs/images/deskfolder-expanded.png)

![2](docs/images/deskfolder-cover.png)

![3](docs/images/deskfolder-compact.png)

## 主要功能

- 在桌面创建多个彼此独立的文件夹组件。
- 从资源管理器直接拖入程序、文件和快捷方式。
- 拖动图标调整顺序，支持保留空位或自动紧凑排列。
- 自定义网格行列、图标尺寸、间距、边距和圆角。
- 支持深浅外观、透明度、磨砂玻璃和多种边框样式。
- 支持溢出收纳，可选择展开方向以及缩略区封面。
- 支持锁定文件夹位置、开机启动和系统托盘管理。

## 安装与使用

1. 从项目的 **Releases** 页面下载最新的 Windows x64 安装程序。
2. 完成安装后启动 DeskFolder。
3. 从系统托盘打开总设置，点击“新建文件夹”。
4. 将需要整理的文件或快捷方式拖入桌面文件夹。
5. 右键文件夹或图标，可以进入设置、打开位置或删除项目。

DeskFolder 是托盘应用。关闭设置窗口不会退出程序；需要完全退出时，请使用系统托盘菜单中的“退出”。

## 配置与数据

用户数据保存在 Qt 的 `AppLocalDataLocation` 目录中，Windows 默认位于：

```text
%LOCALAPPDATA%\DesktopFolderLauncher
```

目录结构：

```text
DesktopFolderLauncher/
├─ config/
│  ├─ folders.json       # 文件夹列表与各文件夹设置
│  └─ defaults.json      # 新建文件夹默认参数
├─ folders/
│  └─ <uuid>.json        # 各文件夹中的图标与布局
└─ covers/
   └─ cover_*.png        # 用户上传后处理的封面
```

配置采用原子写入，旧版本数据会在启动时自动迁移。无法解析的配置不会直接覆盖，而会保留 `.corrupt` 副本以便恢复。删除图标、文件夹或替换封面时，软件也会清理不再被引用的托管资源。

卸载时可以选择保留或删除文件夹配置。计划重新安装或升级时，建议选择保留。

## 从源码构建

### 环境要求

- Windows 10/11 x64
- Qt 6.5 或更高版本
- CMake 3.21 或更高版本
- 支持 C++17 的 MinGW 或 MSVC 工具链

### 构建与测试

```powershell
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --config Release --parallel
ctest --test-dir build -C Release --output-on-failure
```

如果 CMake 无法定位 Qt，可以显式指定 Qt 安装目录：

```powershell
cmake -S . -B build `
  -DCMAKE_PREFIX_PATH="D:/Qt/6.x.x/mingw_64" `
  -DBUILD_TESTING=ON
```

### 部署运行库

```powershell
windeployqt --release --compiler-runtime --qmldir qml `
  --dir package/DeskFolder build/DesktopFolderLauncher.exe
```

安装程序使用 [Inno Setup](https://jrsoftware.org/isinfo.php) 构建，脚本位于 `packaging/DeskFolder.iss`。仓库中的 GitHub Actions 发布工作流会自动完成 Release 构建、测试、Qt 运行库部署和安装包生成。

## 技术栈

- C++17
- Qt 6 / Qt Quick / QML
- Windows OLE Drag and Drop
- Windows DWM 与窗口合成 API
- CMake
- Inno Setup

## 当前平台

DeskFolder 当前正式支持 Windows x64。原生拖放、桌面层级、磨砂效果和窗口行为依赖 Windows API，其他平台暂未纳入发布范围。
