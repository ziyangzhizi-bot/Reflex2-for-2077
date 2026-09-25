// routea_ui_panel.fx  (English edition) -- Reflex2 controls, inside ReShade's own panel.
//
// This pass is a PURE PASS-THROUGH (it samples ReShade's back buffer and returns it unchanged):
// it declares no ROUTEA semantic and never touches the add-on's textures, so enabling it cannot
// change the picture.  It exists only so ReShade lists the sliders below.
//
// The add-on reads these uniforms every frame; panel values win over the file knobs.

#include "ReShade.fxh"

uniform bool RouteAUiMaskLive <
    ui_type = "combo";
    ui_items = "off\0on\0";
    ui_label = "[1] UI mask (live per-pixel)";
    ui_tooltip = "Off = fall back to the older offline rectangular mask.";
> = true;

uniform float RouteAUiThreshold <
    ui_type = "slider";
    ui_min = 0.005; ui_max = 0.50;
    ui_label = "[2] threshold (lower protects more)";
    ui_tooltip = "High-pass residual gate. Raise it until the world stops smearing and the HUD is still clean.";
> = 0.05;

uniform float RouteAUiDepthCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "[3] depth cutoff (catch arms and weapon)";
    ui_tooltip = "Near pixels are forced to be treated as UI. 0 = off. Enable [6] to see the mask while tuning.";
> = 0.0;

uniform float RouteAUiCutoffExpand <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 8.0;
    ui_label = "[4] cutoff expand (pixels)";
    ui_tooltip = "Grows the cut-out band by a few pixels so no edge line leaks through.";
> = 2.0;

uniform bool RouteAUiDepthInvert <
    ui_label = "[5] depth inverted (this game uses reversed Z)";
    ui_tooltip = "Near = larger value = on. Cyberpunk uses reversed Z, keep this checked.";
> = true;

uniform bool RouteAUiShowMask <
    ui_label = "[6] show mask (magenta)";
    ui_tooltip = "Paints the protected pixels magenta so you can tune while looking at the picture.";
> = false;

// ---- status: written by the add-on every frame, read-only for you ----------------------------
uniform int RouteAStatus <
    ui_type = "combo";
    ui_items = "0 not ready (still starting)\0 1 WARP WORKING \0 2 degraded: not warping this session, restart the game\0 3 failed: see routea_warp.log\0";
    ui_label = "[status] read-only, written by the add-on";
    ui_tooltip = "1 = the kernel is warping; 2 = a resolution/fullscreen/HDR change stopped it for this session; 0 = not up yet; 3 = error.";
> = 0;

uniform int RouteABackBufferW <
    ui_type = "slider"; ui_min = 0; ui_max = 8192;
    ui_label = "[status] back buffer width (read-only)";
> = 0;

uniform int RouteABackBufferH <
    ui_type = "slider"; ui_min = 0; ui_max = 8192;
    ui_label = "[status] back buffer height (read-only)";
> = 0;

uniform int RouteAGen <
    ui_type = "slider"; ui_min = 0; ui_max = 999;
    ui_label = "[status] swap-chain generation (read-only, grows on a display change)";
> = 0;

uniform int RouteAKernelWarps <
    ui_type = "slider"; ui_min = 0; ui_max = 1000000;
    ui_label = "[status] frames warped by the kernel (read-only, rising = really warping)";
> = 0;

float4 RouteAUiPanelPS(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    return tex2D(ReShade::BackBuffer, uv);   // pass-through, changes nothing
}

technique RouteAUiMaskPanel <
    ui_label = "Reflex2: UI mask panel (do not untick)";
    ui_tooltip = "Only exists so ReShade lists the sliders above; this pass is a no-op.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = RouteAUiPanelPS;
    }
}
