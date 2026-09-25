// routea_ui_panel.fx -- Reflex2 的遮罩控件,放在 ReShade 自己的面板里。
//
// 说明:这个 pass 是**纯直通**(采样 ReShade 自己的 back buffer 原样返回),不声明任何 ROUTEA
// 语义、不碰插件的纹理;勾上它也不会改变画面。若 ReShade 显示中文是方块,请在
// ReShade 设置页把 Font 选成"Microsoft YaHei / 微软雅黑"(或 SimHei),再重开面板即可。
//
// 插件每帧读这几个 uniform,面板的值**优先于**文件旋钮:
//   routea_warp_uithr.txt / routea_warp_uidepth.txt 只在没有面板时兜底。

#include "ReShade.fxh"

uniform bool RouteAUiMaskLive <
    ui_type = "combo";
    ui_items = "关\0开\0";
    ui_label = "[1] 遮罩开关(live 逐像素)";
    ui_tooltip = "关掉 = 回到旧的离线矩形遮罩。";
> = true;

uniform float RouteAUiThreshold <
    ui_type = "slider";
    ui_min = 0.005; ui_max = 0.50;
    ui_label = "[2] 阈值 threshold(越小保护越多)";
    ui_tooltip = "高通残差门槛。调大到世界不再发糊、HUD 还干净为止。";
> = 0.05;

uniform float RouteAUiDepthCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "[3] 深度截断 depth cutoff(抓手臂和枪)";
    ui_tooltip = "近处强制算 UI。0 = 关。勾上 [6] 显示遮罩,再慢慢往上推。";
> = 0.0;

uniform float RouteAUiCutoffExpand <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 8.0;
    ui_label = "[4] 扩展像素 cutoff expand";
    ui_tooltip = "把深度挖空带往外扩几像素,防止边缘漏一条线。";
> = 2.0;

uniform bool RouteAUiDepthInvert <
    ui_label = "[5] 深度反相(本游戏用反相 Z)";
    ui_tooltip = "近处数值大 = 开。赛博朋克是反相 Z,保持开启。";
> = true;

uniform bool RouteAUiShowMask <
    ui_label = "[6] 显示遮罩 show(品红)";
    ui_tooltip = "把被保护的像素涂成品红,用来一边拖一边看。";
> = false;

// ---- 状态显示(插件每帧写入,你只读,不要手动改) --------------------------------------------
// 这几个是"我到底在不在扭、在什么分辨率上扭"的答案 —— 不用去翻日志。
uniform int RouteAStatus <
    ui_type = "combo";
    ui_items = "0 未就绪(还在启动)\0 1 扭曲工作中 ✔\0 2 已降级:本局不再扭曲,重启游戏恢复\0 3 失败:看 routea_warp.log\0";
    ui_label = "[状态] 只读:插件每帧写";
    ui_tooltip = "1 = 内核正在扭;2 = 换过分辨率(HDR/全屏)后本局已停用,重启即恢复;0 = 还没起来;3 = 出错。";
> = 0;

uniform int RouteABackBufferW <
    ui_type = "slider"; ui_min = 0; ui_max = 8192;
    ui_label = "[状态] 当前后缓冲宽(只读)";
> = 0;

uniform int RouteABackBufferH <
    ui_type = "slider"; ui_min = 0; ui_max = 8192;
    ui_label = "[状态] 当前后缓冲高(只读)";
> = 0;

uniform int RouteAGen <
    ui_type = "slider"; ui_min = 0; ui_max = 999;
    ui_label = "[状态] 交换链代号(只读,变大=换过分辨率)";
> = 0;

uniform int RouteAKernelWarps <
    ui_type = "slider"; ui_min = 0; ui_max = 1000000;
    ui_label = "[状态] 内核已扭曲帧数(只读,持续变大=真的在扭)";
> = 0;

float4 RouteAUiPanelPS(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    return tex2D(ReShade::BackBuffer, uv);   // 直通,什么都不改
}

technique RouteAUiMaskPanel <
    ui_label = "Reflex2:UI 遮罩面板(不要勾选)";
    ui_tooltip = "只是为了 ReShade 列出上面的滑块;这个 pass 是空操作。";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = RouteAUiPanelPS;
    }
}
