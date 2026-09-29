# HYSurveySDK Wrapper

将 [HYSurveySDK](https://gitee.com/hanyidata/survey-sdk-ios)（体验家 / xmplus 问卷 SDK）封装为 Swift Package。

- **Current HYSurveySDK version:** 0.4.37
- **上游:** https://github.com/hanyidata/survey-sdk-ios
- **最低 iOS:** 17.0（与 STTiOS 一致）
- **License:** MIT（上游原协议）

这是源码库，不是二进制 xcframework。官方只发 CocoaPods / Gitee 源码，没有 SPM。

## 接入

Xcode → Project → Package Dependencies → 添加本仓库，选中 library `HYSurveySDK`。

```swift
import HYSurveySDK

HYGlobalConfig.setup(server: "production")
```

## 和 CocoaPods 的差别

官方 podspec 用 `s.resources` 把 `Assets` 打进 framework，源码里用 `Bundle(for: Self.self)` 读 `index.html` / `version.json`。

SPM 静态库的 `Bundle(for:)` 会落到宿主 App，资源实际在 `Bundle.module`。包装时只改了这一处：

```swift
#if SWIFT_PACKAGE
let myBundle = Bundle.module
#else
let myBundle = Bundle(for: Self.self)
#endif
```

其余 Swift 源码和 Assets 保持上游原样。不需要 `patch.sh` 改 Mach-O。

## 升级

```bash
git clone --branch <官方tag> --depth 1 https://github.com/hanyidata/survey-sdk-ios /tmp/survey-sdk-ios
./sync.sh /tmp/survey-sdk-ios
```

然后 commit，tag 打成和官方一致的版本号（例如 `0.4.37`）。
