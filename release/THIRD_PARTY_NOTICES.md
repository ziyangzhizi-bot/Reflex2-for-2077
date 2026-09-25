# 第三方组件与许可(发布包必须附带本文件)

本 mod 自身由本项目作者编写,但它**链接/依赖**以下第三方组件。发布时请保持本文件与
`README_CN.md` 一起分发。

---

## 1. ReShade —— addon API(必需)

* 用途:本 mod 以 **ReShade 64 位 addon**(`*.addon64`)形式加载,使用其公开的 addon API
  (`reshade_api.hpp` / `reshade_events.hpp`)做交换链、资源与效果回调,并在 ReShade 面板里提供控件。
* 许可:ReShade 本体及其 SDK 头文件采用 **BSD 3-Clause**(见 ReShade 仓库 `LICENSE` 与
  `include/` 目录头部版权声明)。本项目**不包含** ReShade 本体,只针对其公开接口编译。
* 使用者在安装前必须自行安装 **带 addon 支持**的 ReShade。

## 2. MinHook(必需,已静态链接进 `routea_hook.asi`)

* 用途:在引擎侧挂钩 NGX / Streamline 的导出函数。
* 许可:**BSD 2-Clause** "Simplified" License,
  Copyright (c) 2009-2017 Tsuda Kageyu。本项目使用的是其 x64 源码的私有副本
  (`routea_addon\minhook\`),**编译时静态链接**。

## 3. NVIDIA NGX / DLSS / Streamline 运行时(必需,不随本包分发)

* 本 mod **不包含**任何 NVIDIA 二进制。它调用的是使用者系统上由 **NVIDIA 驱动**提供的
  `nvngx.dll` 与 **`nvngx_latewarp.dll`(NGX feature 15"latewarp")**,以及游戏自带的
  Streamline (`sl.*.dll`)。
* 这些组件的使用受 **NVIDIA 软件许可协议 / NVIDIA DLSS 许可**约束,由使用者的驱动安装提供;
  本项目只通过其公开调用约定使用,不改动、不重新分发。

## 4. Cyberpunk 2077(必需,不随本包分发)

* 本 mod 面向 **Cyberpunk 2077**(CD PROJEKT RED)。发布包不含任何游戏文件、美术、数据或反编译产物。

## 5. 开发期工具(不在发布包内)

以下工具只在开发/取证阶段使用,**不进入发布包**,其许可也不随本包分发:
`dumpbin`(Microsoft Visual C++ Build Tools)、`dbghelp`/DIA SDK(Windows SDK)、Python 3、
以及本项目内部的离线校验工具(`fxcheck`/`srvprobe`/`maskprobe`/`uidump_*`)。

---

## 6. 发布包内容声明

* 本包**只包含**:`routea_warp.addon64`、`routea_switch.fx`、`routea_ui_panel.fx`、
  `routea_hook.asi`、若干 `routea_warp_*.txt` 开关、安装/清理脚本与文档。
* 本包**不包含**:ReShade 本体、任何 NVIDIA 二进制、任何游戏文件、
  任何竞品 mod 的反编译/逆向资料(`_re/` 目录整体不参与打包)。

## 7. 风险声明

* 本 mod 通过**注入与挂钩**工作(ReShade addon + `.asi`)。请在**单机/离线**环境使用,
  并自行评估在线/反作弊环境下的风险。作者不对账号或存档后果负责。

---

## 8. 本版发行二进制的如实说明(B 方案豁免)

`routea_warp.addon64`(`33E7F620A2CB3D7F`)构建于**字符串清理之前**,发布门禁对它出具的是**豁免**(WAIVED),不是通过:

* 二进制内含**开发期路径字符串**:`_re\`、`make_uimask`、`019_CSMain`、`runtime.cpp L`;
* 内含**一处出处注释**:嵌在 HLSL 注释里提到 `OptiScaler`。

这些是**注释与路径文本**,不是任何第三方代码、也不是任何反编译产物;发布包里同样不含其它 mod 的
源码、shader 或数据。之所以仍然发行这一份:它是**唯一经过真机验证可稳定运行**的构建
(另一份清理干净、且含全部崩溃修复的构建 `3D79E95830EFDBAF` 在真机上仍会崩溃,已被否决并回退)。

**下一个已验证构建**将替换为本仓库 `SOURCE.md` 所述清理后的版本,届时本说明与门禁豁免一并撤销。
