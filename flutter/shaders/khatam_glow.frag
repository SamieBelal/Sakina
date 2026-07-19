// Ambient glow field behind the khatam companion — a soft gold aura that
// breathes and ripples, driven from Dart. Additive (drawn with BlendMode.plus)
// over the emerald sacred-canvas background. Uniform-driven (no texture sampler)
// so it renders every frame on Impeller with no offscreen pass.
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;       // canvas size in px
uniform float uPhase;     // looping phase 0..2π (breath + ripple animation)
uniform float uIntensity; // 0..1 overall glow strength (from streak glow)

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 p = uv - vec2(0.5);
    float d = length(p);

    // Gentle breathing core that fades toward the edges.
    float breath = 0.5 + 0.5 * sin(uPhase);
    float core = smoothstep(0.55, 0.0, d);
    float glow = core * (0.20 + 0.14 * breath) * uIntensity;

    // Faint concentric light ripple radiating outward.
    float ripple = 0.05 * sin(d * 34.0 - uPhase * 2.0) * smoothstep(0.55, 0.06, d);
    glow = max(glow + ripple * uIntensity, 0.0);

    vec3 gold = vec3(0.80, 0.62, 0.38);
    fragColor = vec4(gold * glow, glow);
}
