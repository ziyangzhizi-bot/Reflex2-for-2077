// routea_switch.fx -- 用户版开关(Route A)
//
// 用户只需要动第一个复选框。第二个下拉框**保持默认的第二项**即可(它是呈现路径的选择,
// 插件在启动时锁定它;第一项那套写法当前不产生画面,所以默认已经指向第二项,不要改)。
// 开发/诊断用的 capture 控件只在开发版里,不进用户包。

#include "ReShade.fxh"

uniform bool RouteAWarpOn <
    ui_type = "checkbox";
    ui_label = "Route A: frame warp / 帧扭曲(总开关)";
    ui_tooltip = "取消勾选 = 插件变成纯转调:不求值、不拷贝、不抓帧,画面完全交给游戏自己。"
                 "勾选 = 由 NVIDIA 的 latewarp 内核完成扭曲。";
> = true;

uniform int RouteAPath <
    ui_type = "combo";
    ui_items = "（保留项,不要选这项）\0LDR warp - 保持这一项(默认)\0";
    ui_label = "Route A: 呈现路径(保持默认第二项,无需修改)";
    ui_tooltip = "插件启动时锁定这个选择;当前只有第二项能出画面。保持默认即可。";
> = 1;

float4 RouteASwitchPS(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    return tex2D(ReShade::BackBuffer, uv);   // 直通
}

technique RouteASwitch <
    ui_label = "Route A: 帧扭曲开关(只放控件,不改画面)";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = RouteASwitchPS;
    }
}
