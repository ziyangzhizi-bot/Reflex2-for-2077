# Reflex2 — Reflex2 for Cyberpunk 2077 via NVIDIA latewarp

[中文说明](README_CN.md)

Make **NVIDIA's own latewarp kernel** (NGX feature 15, `nvngx_latewarp.dll`) produce a **visible
one-frame displacement / warp** in **Cyberpunk 2077**. The warp is computed **entirely by NVIDIA's
kernel** — this mod contains **no self-written reprojection, motion-vector or depth math**.

Controls live in the **ReShade overlay panel** (no hotkeys, no config editing).

| | |
|---|---|
| Status | `0.9.0-rc1` (release candidate) |
| Tested on | RTX 4060 Laptop, driver **617.14**, ReShade **6.8.0**, Cyberpunk 2077 2.31 |
| Requires | ReShade 64-bit **with add-on support**, NVIDIA RTX 40-series or newer |
| Known limitation | **After changing the resolution in-game, do NOT jump straight back into the save** — see below |

## ⚠️ The one rule to remember

**Change the resolution *before* launching the game** (desktop / launcher / NVIDIA panel). If you
change it in-game, go to the **main menu first and load the save from there**.
Loading the save *directly* from the graphics-settings screen can make the game quit within a few
seconds. After an in-game resolution change the warp switches **itself off for that session** (a
deliberate protection) — restart the game to get it back. The in-game panel tells you which state
you are in.

## Install

```powershell
# in the folder you extracted the release into
.\install.ps1 -SelfCheck   # environment check, changes nothing
.\install.ps1              # install (quit the game first)
.\install.ps1 -Lang en     # optional: force the English panel
```

The script backs up every file it overwrites (to `bin\x64\_fwbackup_<timestamp>\`) and verifies
hashes afterwards. Uninstall with `.\install.ps1 -Uninstall`.

## Use

1. Launch the game, open ReShade's overlay (default `Home`).
2. Enable **`routea_ui_panel.fx`** — six sliders plus five read-only status rows live there:

| Panel row | Meaning |
|---|---|
| Status (read-only) | `0` not ready / **`1` warp working** / `2` degraded: restart the game / `3` failed: see the log |
| Back-buffer W / H | the resolution actually being served right now |
| Swap-chain generation | grows by one on every resolution / fullscreen / HDR change |
| Kernel warps | **rising = NVIDIA's kernel is really warping this session** |

3. To disable the warp temporarily, untick **"Reflex2: frame warp"** in `routea_switch.fx`.
   Unticking it now makes the add-on a pure pass-through (no evaluation, no copies, no captures).

## Requirements

| | |
|---|---|
| Cyberpunk 2077 | Steam / GOG / Epic |
| ReShade | 6.8.0 tested, 64-bit, **add-on support** |
| GPU | NVIDIA RTX 40-series or newer — the mod needs the driver's `nvngx_latewarp.dll` |
| Driver | 617.14 tested; a driver update during development kept the mod working |
| In-game | DLSS upscaling recommended; this mod is unrelated to frame generation |

## Repository layout

```
release/                 the shipped artifacts and the packaging scripts
  payload/               addon, engine hook, shaders, default gate files
  install.ps1            install / self-check / uninstall  (-Lang cn|en|bilingual)
  cleanup.ps1            removes debug leftovers (frame dumps, old crash dumps, old backups)
  make_release.ps1       builds the distributable zip (refuses to ship forbidden content)
docs/
  RISKS.md               every user-visible risk, in one table
  ARCHITECTURE.md        how the mod hooks the frame and what each file does
  TROUBLESHOOTING.md     symptom -> check -> fix
SOURCE.md                why the add-on source is not in this repository yet
```

## Risks and limitations (read before installing)

* **Injection**: this is an injected mod (ReShade add-on + `.asi`). Use it **offline / single-player**
  and judge the anti-cheat risk yourself.
* Driver-dependent: a future driver may change the latewarp parameter set. The mod then runs
  **inert** (no warp, no crash) rather than failing hard — check the status panel.
* The in-game resolution-change rule above; the HUD's **flat areas** (health-bar fill, panel
  backgrounds) can still be warped; the displacement is **one frame** (using the engine's own
  one-frame delta).
* Deliberate memory holds (deferred destruction) can grow VRAM slowly; the mod never frees a
  resource the GPU may still be using.

The full list is in [docs/RISKS.md](docs/RISKS.md).

## Credits and licence

* ReShade add-on API (BSD 3-Clause), MinHook (BSD 2-Clause, statically linked).
  NVIDIA NGX / DLSS / Streamline runtimes are **not** redistributed — they come from your driver.
* See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Project licence: see [LICENSE](LICENSE).

Not affiliated with CD PROJEKT RED, NVIDIA or the ReShade project.

---

## 变更:路径选项已移除(2026-09-25)

`Reflex2: which path`(UI first / Light first)这个组合框已从项目里删除:

* 插件现在只有一条路径 —— LDR 扭曲(改扭显示就绪的帧,再拷进后缓冲),也就是实测通过的那条;
* `routea_switch.fx` 里只剩**一个**控件:总开关;
* 原因:UI first 依赖"游戏把自有帧交给内核"(原地改写)这条通道,而当前游戏/驱动不再提供它
  (`Latewarp.Output ret=0xFFFFFFFF`、`GAMETEX bound=0`),留下这个选项只会让人选了之后什么都看不到;
* 代码里那条分支现在永远不会被置位(`g_uiFirstPath` 恒为 0),不存在两条路同时生效的可能。

延迟说明(如实):这条路径的源帧是上一帧的显示就绪拷贝,所以画面比输入晚一帧;
亮部保留(HDR 不被钳制),HUD 会跟着一起被扭(面板块 [1] 阈值可调保护程度)。
