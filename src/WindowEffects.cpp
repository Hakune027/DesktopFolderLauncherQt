#include "WindowEffects.h"

#include <QtGlobal>

#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>

namespace {
enum AccentState {
    AccentDisabled = 0,
    AccentEnableTransparentGradient = 2,
    AccentEnableBlurBehind = 3,
    AccentEnableAcrylicBlurBehind = 4
};

struct AccentPolicy {
    int state;
    int flags;
    DWORD gradientColor;
    int animationId;
};

struct WindowCompositionAttributeData {
    int attribute;
    void *data;
    SIZE_T sizeOfData;
};

using SetWindowCompositionAttributeFunction = BOOL(WINAPI *)(HWND, WindowCompositionAttributeData *);
constexpr int WindowCompositionAttributeAccentPolicy = 19;
constexpr DWORD DwmWindowCornerPreference = 33;
constexpr DWORD DwmUseImmersiveDarkMode = 20;
constexpr DWORD DwmBorderColor = 34;
constexpr DWORD DwmCaptionColor = 35;
constexpr DWORD DwmTextColor = 36;
constexpr DWORD DwmSystemBackdropType = 38;
constexpr DWORD DwmWindowCornerDefault = 0;
constexpr DWORD DwmWindowCornerRound = 2;
constexpr DWORD DwmSystemBackdropNone = 1;
constexpr DWORD DwmSystemBackdropMainWindow = 2;
constexpr DWORD DwmSystemBackdropTransientWindow = 3;
constexpr DWORD DwmSystemBackdropTabbedWindow = 4;
}
#endif

bool WindowEffects::applyFrostedGlass(QWindow *window, bool enabled,
                                      bool lightTheme, bool windowShadow)
{
#ifdef Q_OS_WIN
    if (!window)
        return false;
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    auto setCompositionAttribute = reinterpret_cast<SetWindowCompositionAttributeFunction>(
        GetProcAddress(user32, "SetWindowCompositionAttribute"));
    if (!setCompositionAttribute)
        return false;

    AccentPolicy policy = {};
    DWORD backdropType = DwmSystemBackdropNone;
    policy.state = enabled ? AccentEnableBlurBehind : AccentDisabled;
    policy.flags = 0;
    // GradientColor is ABGR. Windows does not expose blur radius, so strength
    // controls how much of the acrylic blur is revealed through the tint.
    // Theme tint is rendered by QML and controlled by background opacity.
    // Keep the native layer almost colorless so blur strength stays separate.
    const int tintAlpha = enabled ? 1 : 0;
    const DWORD tintColor = lightTheme ? 0x00FFFFFF : 0x00000000;
    policy.gradientColor = (static_cast<DWORD>(tintAlpha) << 24) | tintColor;

    WindowCompositionAttributeData data = {};
    data.attribute = WindowCompositionAttributeAccentPolicy;
    data.data = &policy;
    data.sizeOfData = sizeof(policy);
    const bool applied = setCompositionAttribute(hwnd, &data);

    DwmSetWindowAttribute(hwnd, DwmSystemBackdropType,
                          &backdropType, sizeof(backdropType));

    MARGINS margins = enabled && windowShadow
            ? MARGINS{-1, -1, -1, -1} : MARGINS{0, 0, 0, 0};
    DwmExtendFrameIntoClientArea(hwnd, &margins);

    // Keep the native caption visually continuous with the QML surface while
    // retaining Windows 11 snap layouts, system buttons and rounded corners.
    const BOOL darkCaption = lightTheme ? FALSE : TRUE;
    DwmSetWindowAttribute(hwnd, DwmUseImmersiveDarkMode,
                          &darkCaption, sizeof(darkCaption));
    constexpr COLORREF defaultCaptionColor = 0xFFFFFFFF;
    // With the frame extended through the client area, asking DWM for its
    // default caption material avoids painting a separate solid title strip.
    // WS_CAPTION itself is retained, so native Windows transitions remain.
    const COLORREF captionColor = enabled
            ? defaultCaptionColor
            : (lightTheme ? RGB(245, 245, 245) : RGB(23, 24, 29));
    const COLORREF textColor = lightTheme ? RGB(24, 24, 24) : RGB(245, 245, 245);
    // DWMWA_COLOR_NONE removes the bright one-pixel DWM outline. The glass
    // surface still keeps its system shadow and rounded clipping.
    constexpr COLORREF noBorderColor = 0xFFFFFFFE;
    const COLORREF borderColor = enabled ? noBorderColor : captionColor;
    DwmSetWindowAttribute(hwnd, DwmCaptionColor,
                          &captionColor, sizeof(captionColor));
    DwmSetWindowAttribute(hwnd, DwmTextColor,
                          &textColor, sizeof(textColor));
    DwmSetWindowAttribute(hwnd, DwmBorderColor,
                          &borderColor, sizeof(borderColor));

    const DWORD cornerPreference = enabled ? DwmWindowCornerRound : DwmWindowCornerDefault;
    DwmSetWindowAttribute(hwnd, DwmWindowCornerPreference,
                          &cornerPreference, sizeof(cornerPreference));
    return applied;
#else
    Q_UNUSED(window);
    Q_UNUSED(enabled);
    Q_UNUSED(lightTheme);
    Q_UNUSED(windowShadow);
    return false;
#endif
}
