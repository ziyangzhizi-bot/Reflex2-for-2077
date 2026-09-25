# 开发用开关(不随用户版发布)

用户版(`release/payload/`)**不含任何配置文件**:插件在"没有配置文件"时按下面的默认值运行。
这些 `.txt` 只服务于开发/诊断,当年是一个个试出来的;对普通玩家没有任何益处,所以从发布包里
整体移除了(源文件留在这里备查)。

| 开关文件 | 默认(文件缺失时) | 作用 |
|---|---|---|
| `<module>_hooks.txt` | **开** | 引擎侧总闸(MinHook 挂 NGX/Streamline)。也支持 `plugins\routea_hook_own.txt` 反向关闭 |
| `<module>_live.txt` | **开** | 使用实时相机位姿(扭曲的意义所在) |
| `<module>_ldr2c.txt` | **开** | LDR 上屏链的内核求值(SdrCaseC) |
| `<module>_present_m5.txt` | **开** | LDR 呈现臂 |
| `<module>_present_m6.txt` / `_lastpath.txt` | **模式 6** | 呈现模式选择;无文件时按 6(同格式拷贝,实测配置) |
| `<module>_uilive.txt` | **开** | 逐像素 UI 遮罩(live) |
| `<module>_uimask.txt` | **开** | 离线/回退遮罩 |
| `<module>_uipin.txt` | (原样) | HUD pin 视图(未改为默认) |
| `<module>_framedepth.txt` | (原样) | 我们自己的同帧 Depth/MV 拷贝;缺失时用游戏 tag 的 Depth/MV |
| `<module>_uithr.txt` | 内建默认 | 高通阈值;面板滑块优先 |
| `<module>_uidepth.txt` | 关 | 深度截断的 `<cutoff> <radius> <inverted>` |
| `<module>_allowresize.txt` | — | **只用于测试**换分辨率后的重建路径(默认没有) |
| `plugins\routea_hook_live.txt` / `_gametex.txt` | 用户版仍随包 | 引擎侧 ASI 的实时位姿/游戏纹理绑定;内容含说明文字 |

## 开发注意

* 想看某个开关的“关”效果:删掉对应文件在**旧构建**里就是关;当前发布构建里删掉 = 开。
  要真正关闭请用面板总开关(取消勾选 = 纯转调)。
* 打包脚本 `release/make_release.ps1` 会**拒绝**打包 `dev/` 下的东西,并检查 `_re`、竞品名称、
  `.raw`/`.dmp`/`.cpp` 是否混入。
