#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 glassTint;
    vec2 surfaceSize;
    float cornerRadius;
};

void main() {
    vec2 point = (qt_TexCoord0 - 0.5) * surfaceSize;
    vec2 edge = abs(point) - (surfaceSize * 0.5 - cornerRadius);
    vec2 corner = max(edge, 0.0);
    float distance = length(corner) + min(max(edge.x, edge.y), 0.0) - cornerRadius;
    float antialias = max(fwidth(distance) * 0.5, 0.35);
    float coverage = 1.0 - smoothstep(-antialias, antialias, distance);

    vec2 normal = sign(point) * (any(greaterThan(edge, vec2(0.0)))
        ? normalize(corner)
        : (edge.x > edge.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0)));
    float depth = max(-distance, 0.0);
    float bevel = max(cornerRadius * 0.38, 2.0);
    // A circular bevel concentrates the reflection near the outer edge.
    float bevelPosition = clamp(depth / bevel, 0.0, 1.0);
    float rim = 1.0 - sqrt(bevelPosition * (2.0 - bevelPosition));
    float highlight = max(dot(normal, normalize(vec2(-0.45, -1.0))), 0.0);
    float bounce = max(dot(normal, normalize(vec2(0.35, 1.0))), 0.0);
    float glint = 0.68 + 0.32 * (1.0 - qt_TexCoord0.x);

    float tintAlpha = glassTint.a * mix(0.65, 0.9, smoothstep(0.0, 1.0, qt_TexCoord0.y));
    vec3 tint = glassTint.rgb * (tintAlpha / max(glassTint.a, 0.001));
    vec4 base = vec4(tint, tintAlpha);
    float reflected = rim * (0.12 + 0.46 * highlight * glint + 0.13 * bounce)
        * smoothstep(0.0, 0.15, glassTint.a);
    vec3 reflection = mix(vec3(0.72, 0.83, 0.95), vec3(1.0, 0.98, 0.94), highlight);
    // Tint opposite sides of the bevel without sampling the scene.
    reflection.r += 0.06 * max(-normal.x, 0.0) * (1.0 - highlight);
    reflection.b -= 0.07 * max(-normal.x, 0.0);
    fragColor = (vec4(reflection * reflected, reflected) + base * (1.0 - reflected))
        * coverage * qt_Opacity;
}
