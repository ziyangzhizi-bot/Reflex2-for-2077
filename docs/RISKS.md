# 全部风险清单(RISKS) / Complete risk list

> 版本 `0.9.0-rc1`。**强烈建议在装之前读完这一页。**
> English summary follows each table.

## A. 安全 / 账号类

| # | 风险 | 严重度 | 可能性 | 现在的缓解 | 你应该做什么 |
|---|---|---|---|---|---|
| A1 | **反作弊 / 在线环境** :本 mod 是注入式(ReShade addon + `.asi`),挂钩 NGX/Streamline/D3D12 | **高** | 中 | 无技术缓解(这是所有注入式 mod 的共同风险) | **只在单机 / 离线游玩时使用**;联机、竞速、带反作弊的模式请先卸载。后果自负 |
| A2 | 存档损坏(崩溃发生在写入途中) | 中 | 低 | 崩溃点都在渲染路径,不触碰存档系统;但我们无法保证 | 重要存档手动备份(`%LOCALAPPDATA%\CD Projekt Red\Cyberpunk 2077\Saves\`) |
| A3 | 游戏文件被其它工具误删 | 中 | **中(已发生一次)** | 本仓库不含任何"清理游戏目录"的脚本;`install.ps1` 只备份不改别人的文件 | 不要用 mod 管理器/清理工具批量处理 `bin\x64`;`install.ps1` 的备份目录 `_fwbackup_*` 请留着做回退 |

**EN:** A1 injecting mod (anti-cheat risk — offline only), A2 save corruption is unlikely but back
your saves up, A3 third-party cleanup tools once wiped every related file — keep the backups.

## B. 运行期崩溃 / 卡住

| # | 风险 | 严重度 | 可能性 | 现在的缓解 | 你应该做什么 |
|---|---|---|---|---|---|
| B1 | **游戏内改分辨率 → 直接回存档** → 数秒内闪退 | **高** | **高(必现)** | 无(证据显示换链后插件已完全静默仍复现,疑似游戏/DXGI 侧) | **不要这么做**:进游戏前设好分辨率,或改完先回主菜单再读档(详见 README) |
| B2 | 游戏内改分辨率后本局扭曲**自动停用** | 中 | 高 | 这是**故意的保护**(换链后不再分配/绑定任何交换链资源) | 重启游戏恢复;面板"状态"会显示 `2 已降级` |
| B3 | GPU 挂起(驱动复位,LiveKernelEvent 141) | **高** | 低(已修) | 已修两个真因:延迟销毁曾释放"仍在飞"的资源;每帧新分配 33 MB 中间纹理 | 若再遇到,把 `bin\x64\fwcrash_*.txt` 与 `routea_warp.log` 反馈 |
| B4 | 设备被移除 / 画面冻结 | 中 | 低(已修) | 旧版把 `GetDeviceRemovedReason()` 的 `0x887A0001` 误判成"设备移除"并永久停止呈现 → 已修 | 若画面停住但游戏在跑:看日志有没有 `device really IS removed` |
| B5 | 崩溃取证文件写在游戏目录里 | 低 | 高(崩溃时) | `fwcrash_*.txt/.dmp` 写在 `bin\x64\`;**每个 dmp 约 200 MB** | 用 `cleanup.ps1` 清理(保留 `.txt`) |

**EN:** B1 the one forbidden sequence (in-game resolution change then straight back to the save),
B2 warp auto-disables after an in-game resolution change (by design), B3 two GPU-hang root causes
fixed, B4 the false "device removed" latch fixed, B5 crash dumps land in the game folder (~200 MB each).

## C. 画面 / 效果类

| # | 风险 | 严重度 | 可能性 | 现在的缓解 | 你应该做什么 |
|---|---|---|---|---|---|
| C1 | **HUD 平坦区域**仍会被扭(血条填充、面板底色) | 中 | 中 | 逐像素遮罩保护了轮廓/文字;平坦内部仍漏 | 把面板"UI 保护阈值"往小调(保护更多),或用 `[6] 显示遮罩` 看着调 |
| C2 | 位移只有**一帧**,观感上有一帧延迟 | 低 | 高 | 使用引擎自己发布的一帧 delta(这是设计,不是 bug) | 无 |
| C3 | 高光被钳制 / 亮度观感变化 | 低 | 中 | 内核的 [0,1] 输出契约决定 | 用面板滑块微调;必要时关闭本 mod |
| C4 | 与其它画面 mod 叠加后效果不可预期(RenoDX、DLSS 替换、帧生成解锁等) | 中 | 中 | 无 | 出问题时先只留本 mod + ReShade,再逐个加回 |

**EN:** C1 flat HUD interiors can still warp, C2 one-frame latency by design, C3 kernel clamps to
[0,1], C4 other graphics mods can interact unpredictably.

## D. 依赖 / 兼容性

| # | 风险 | 严重度 | 可能性 | 现在的缓解 | 你应该做什么 |
|---|---|---|---|---|---|
| D1 | **驱动更新**后 latewarp 参数/语义变化 → 失效 | **高** | 中 | 失效时**退化为不动画面**(不崩);面板状态会显示非 `1` | 换驱动后先看面板"状态";必要时回退驱动 |
| D2 | 游戏大版本更新改变 Streamline tag 布局 | 高 | 低 | 同上(退化为不动画面) | 关注仓库的兼容性说明 |
| D3 | ReShade 升级导致 addon 接口变化 | 中 | 低 | 我们只用公开 addon API,且实测 6.8.0 | 升级 ReShade 后重建/重装 |
| D4 | 非 NVIDIA 卡 / 无 `nvngx_latewarp.dll` | 高 | 低 | `install.ps1 -SelfCheck` 会直接报缺项;插件会加载但不动画面(不崩) | 先跑 `-SelfCheck` |
| D5 | 非 D3D12 路径(如 Vulkan 后端) | 中 | 低 | 代码只处理 D3D12 交换链 | 用 D3D12 启动游戏 |
| D6 | HDR / 10bit 交换链格式与本机不同 | 中 | 低 | 尺寸/格式按**当前后缓冲**实时读取并校验 | 若 HDR 下异常,先在 SDR 下验证 |

**EN:** D1 driver updates can invalidate the latewarp parameter set (degrades to inert),
D2 game updates can change the Streamline tag layout, D3 ReShade API drift, D4 needs an
NVIDIA GPU and the driver's `nvngx_latewarp.dll`, D5 D3D12 only, D6 HDR format differences.

## E. 资源 / 性能 / 卫生

| # | 风险 | 严重度 | 可能性 | 现在的缓解 | 你应该做什么 |
|---|---|---|---|---|---|
| E1 | 显存**缓慢增长**(故意不释放仍在飞的资源) | 中 | 中 | 延迟销毁栅栏会释放**确认**用过的资源;宁可短暂多留也不 GPU 侧 use-after-free | 长时间游玩后重启游戏;不要在 8 GB 卡上开 4K + 高清材质 |
| E2 | 每帧额外计算(内核求值 + 遮罩 4 次 dispatch + 拷贝) | 低 | 高 | 全部在 GPU 上,实测 2560x1600 可跑 | 帧数不够时提高"UI 保护阈值"或关掉本 mod |
| E3 | 日志无限增长 | 低 | 低 | 自动轮转(`routea_warp.log` → `.old.log`) | 用 `cleanup.ps1` |
| E4 | 游戏目录被调试产物撑大 | 中 | 中 | `cleanup.ps1 -DryRun` 先看;可释放约 1 GB | 定期跑 `cleanup.ps1` |

**EN:** E1 VRAM grows slowly by design (deferred destruction), E2 extra per-frame GPU work,
E3 log rotation, E4 debug leftovers can be cleaned with `cleanup.ps1`.

## F. 许可 / 法律

| # | 风险 | 严重度 | 可能性 | 缓解 |
|---|---|---|---|---|
| F1 | 使用了 ReShade / MinHook 的代码 | 低 | — | 均按其 BSD 许可使用,静态链接的 MinHook 在 `THIRD_PARTY_NOTICES.md` 声明 |
| F2 | NVIDIA 运行时**不再分发** | 低 | — | 发布包不含任何 NVIDIA 二进制,由使用者驱动提供 |
| F3 | 不含游戏文件与竞品逆向资料 | 低 | — | 打包脚本内置"禁品自检",`_re/` 整体不进包 |

**EN:** F1 ReShade/MinHook used under BSD terms and credited, F2 no NVIDIA binaries redistributed,
F3 no game files and no third-party reverse-engineering material shipped.

---

## G. 一句话结论

**它现在能稳定跑(实测 60 秒连续、扭曲工作、正常退出),但有一条必须避开的操作
(游戏内改完分辨率别直接回存档),以及两条依赖(D3D12 + NVIDIA 驱动提供的 latewarp 内核)。
在这两条之外,它不会让游戏变得更不稳定 —— 出错时它选择"松开"而不是"硬撑"。**
