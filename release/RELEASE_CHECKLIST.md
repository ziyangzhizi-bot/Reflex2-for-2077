# 发布清单(Reflex2)—— 逐项状态与证据

> 目标原文:在"只有 NVIDIA latewarp 内核可以扭曲"的前提下,修好交换链重建崩溃,使任意分辨率、
> 局内/局外任意顺序切换都不崩溃,并推进到可交付发布状态(安装方式、开箱默认值、换机自检与自动降级、说明文档)。
> 本文件逐项回答:**做到哪了、证据是什么、还差什么。**

## A. 硬阻塞项

| # | 项目 | 状态 | 证据 / 还差什么 |
|---|---|---|---|
| A9 | 发布包(可分发 zip) | 🟢 完成 | `make_release.ps1` → `_dist\FrameWarp-RouteA-0.9.0-rc1.zip`(**24 个文件,342 KB**);内含插件/两个 .fx/引擎钩子/10 个默认开关 + 安装/清理脚本 + README/发布说明/许可/变更记录/VERSION/BUILD_INFO;脚本自带**禁品自检**(不得出现 `_re`、竞品逆向、`.raw`/`.dmp`、`.cpp`) |
| A10 | 许可与致谢 | 🟢 完成 | `THIRD_PARTY_NOTICES.md`:ReShade(addon API,BSD 3-Clause)、MinHook(BSD 2-Clause,静态链接)、NVIDIA NGX/DLSS/Streamline(**不随包分发**)、不含游戏文件与竞品资料 |
| A11 | 版本与构建信息 | 🟢 完成 | `VERSION` = `0.9.0-rc1`;包内 `BUILD_INFO.txt` 记录插件/钩子 SHA256 + 打包时间;`CHANGELOG.md` 记录本版修复清单 |
| A12 | Mod 页面文案 | 🟢 完成 | `RELEASE_NOTES_0.9.0-rc1.md`(可直接作为发布页正文:是什么/要求/安装/使用/最重要的一条/已知限制/风险/致谢) |
| A13 | 发布包端到端验证 | 🟢 完成 | 在**解压后的包目录**里跑 `install.ps1 -DryRun`(自检全绿、复制与开关逻辑正确、游戏目录零改动)与 `cleanup.ps1 -DryRun` |
| A14 | 出包产物 = 实测过的构建 | 🟢 完成 | 包内 `routea_warp.addon64` = **`33E7F620A2CB3D7F`**,即 19:02 那一局实测(60 秒、`evals` 涨到 1147、正常退出、扭曲工作)的同一份 |
| A15 | 换机安装测试 | 🔴 未做 | 需要在**另一台机器**上跑 `install.ps1 -SelfCheck` 并按 README 验证(本机无法替代) |
| A16 | 发布页/上传 | 🔴 未做 | 需要作者把 zip 上传到发布平台并配截图/视频(我无法代做) |

| # | 项目 | 状态 | 证据 / 还差什么 |
|---|---|---|---|
| A1 | 交换链重建不再崩溃 | 🟡 **已缓解 + 已文档化** | 已修 5 类:`destroy_swapchain` 丢身份+代号、`init_swapchain` 先重读新尺寸、代号参与"是否本链"判断、内核/拷贝前硬门、**兜底后连建造者一起停**(`SdrEnsure` 拒绝重建)、不再对"游戏自己的帧"发 barrier、`GravePush` 不再释放还在飞的资源、中间纹理不再每帧重分配。**已验证**:启动时 3 次换链不再误触发(19:02 局正常退出)、"改分辨率→回主菜单→再读档"不崩(18:43 局 112 秒正常退出)。**仍会闪退**:游戏内改完分辨率**直接回存档**(18:58 在"全静默"版上仍复现,无 fwcrash → 很可能是 DXGI/驱动/游戏侧)。正确操作与状态指示见 `README_CN.md` §3.1 |
| A7 | 在游戏内确认"扭曲真的在工作" | 🟢 完成 | 面板 5 个只读项:状态 / 后缓冲宽高 / 交换链代号 / 内核已扭曲帧数(`33E7F620A2CB3D7F` + `routea_ui_panel.fx` 11 个 uniform) |
| A8 | 驱动兼容性 | 🟢 有实测证据 | RTX 4060 Laptop / 驱动 617.14;开发期间用户更新过一次驱动,mod 仍正常 → 当前驱动支持 `nvngx_latewarp.dll`(NGX feature 15)路径 |
| A2 | 安装方式 | 🟢 完成 | `RELEASE\install.ps1`(`-SelfCheck` / `-DryRun` / `-Uninstall` / `-ForceDefaults`),`payload\` 内含 addon + 2 个 .fx + .asi + 默认开关 |
| A3 | 开箱默认值 | 🟢 完成 | 安装脚本写入 `routea_warp_lastpath.txt=6` 等 10 个开关;面板默认:阈值 0.05、深度截断关、总开关开 |
| A4 | 换机自检与降级 | 🟢 完成 | `install.ps1 -SelfCheck` 实测输出:游戏 exe / `nvngx_latewarp.dll`(版本 310,2,0,0)/ ReShade(`dxgi.dll`)/ 着色器目录 / plugins / GPU(`RTX 4060 Laptop, 617.14`)/ 游戏未运行 → 结论"环境满足"。缺项时**不装**并列出缺什么,且插件本身在缺内核时退化为"加载但不动画面"(不崩)。 |
| A5 | 说明文档 | 🟢 完成 | `RELEASE\README_CN.md`:需求、安装、面板中文滑块表、日志与崩溃取证、已知问题、风险声明、卸载 |
| A6 | 可复现构建 | 🟢 完成 | `build_release.cmd` 加 `/Brepro` + `/MAP` + `/INCREMENTAL:NO`:同一源码连续两次构建 **SHA256 完全相同**(`D5FA325C31C712EE`)。**实测:不加 `/Brepro` 的两个构建哈希不同;加 `/Zi`/`/DEBUG` 会让 `.text` 从 286 KB 涨到 646 KB(symbol 全错)。** |

## B. 发布前应做(不阻塞首发,但影响体验/支持成本)

| # | 项目 | 状态 | 说明 |
|---|---|---|---|
| B1 | HUD 平坦区域(血条填充/面板底色)仍会被扭 | 🔴 未做 | 设计已定:1/16 分辨率 UI 出现图 + 16×16 块状涂抹 + "最近 N 帧见过"防冻结。见 `HANDOVER.md` §6 |
| B2 | 崩溃符号可离线解码 | 🟢 完成 | 构建产物附带 `.map`;`fg\lookup_rva.py --crash fwcrash_1.txt` 一条命令解出函数名(已实测) |
| B3 | 日志可关 / 轮转 | 🟢 已有 | `routea_warp.log` → 自动轮转 `routea_warp.old.log`(实测存在 8.8 MB 的旧日志) |
| B4 | 发布版不得含竞品反编译资料 | 🟡 规则已定 | `_re\optiscaler_re\`、`_re\routeA\*.md`(内部复盘)与 `.txt` 取证**不入发布包**;`RELEASE\payload\` 已按此组织 |
| B5 | 干净的安装来源 | 🟢 完成 | `payload\`(addon 448000 B `8F2D2F11CC6D9CAE`;`routea_hook.asi` `18222858577D546C`;两个 .fx;开关) |
| B6 | 磁盘卫生 | 🟢 完成 | `cleanup.ps1 -DryRun` 可清掉帧转储(每个 14–30 MB)、`_uimask.raw`、`fwcrash_*.dmp`(每个 200 MB),保留最近回退点 |

## C. 已知依赖风险(写进 README,发布时声明)

1. `Latewarp.*` 参数名/语义由**驱动**提供 —— 换驱动版本可能失效(表现为"不动画面",不是崩溃)。
2. Streamline tag 布局与 `sl::Constants` 偏移由**游戏/Streamline 版本**决定(当前只 tag 0/1/3/4/29)。
3. 交换链格式(显卡/HDR)决定后续转换面;格式铁律见 `HANDOVER.md` §5。
4. 本 mod 为注入式,反作弊/联网风险由用户评估。

## D. 工程纪律(这次反复踩过的,已固化)

1. 任何 detour 先核对 SDK 头文件参数个数/类型;vtable 槽位先数,别猜。
2. 缓存里不存裸资源指针;换链必须靠 `destroy_swapchain`/`init_swapchain` 成对处理。
3. **不复用** `GetDeviceRemovedReason()` 的 `FAILED()` 判断:`0x887A0001` 不是设备移除。
4. `Close()` 失败 → 列表永不可 `Reset`(D3D12 文档);`Allocator::Reset()` 只能在 GPU 用完后调用。
5. 符号分析**不要**用带 `/Zi`+`/DEBUG` 的构建(增量链接把 `.text` 撑大 2.26 倍、符号全错);用 `/MAP` + `/INCREMENTAL:NO /OPT:REF /OPT:ICF`,并用 `rvamap.py --pe A --pe2 B` + `textdiff.py` 证明代码布局一致。
6. 一次只改一个变量;**游戏内验证永远由用户执行**,AI 只读日志与崩溃文件。
