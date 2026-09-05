#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float fog;
    float dropRate;
    float dropSize;
    float bend;
    float aspect;
    float rainAmount;
    float snowAmount;
    float cloudAmount;
    float stormAmount;
};

layout(binding = 1) uniform sampler2D sharp;
layout(binding = 2) uniform sampler2D blurred;
layout(binding = 3) uniform sampler2D wipe;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    float n = hash21(p);
    return vec2(n, hash21(p + n + 17.17));
}

float noise21(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 runner(vec2 uv, float columns, float phase, float speed, float radius) {
    float cellX = floor(uv.x * columns);
    float localX = fract(uv.x * columns) - 0.5;
    vec2 random = hash22(vec2(cellX, phase));
    if (random.x > dropRate) return vec3(0.0);

    float head = fract(time * speed * mix(0.72, 1.35, random.y) + random.x * 7.13 + phase);
    float dy = fract(uv.y - head + 0.5) - 0.5;
    float wobble = sin((uv.y + random.y) * 12.0 + time * 0.45) * 0.08;
    float dx = (localX - (random.y - 0.5) * 0.42 - wobble) * aspect / columns;
    float r = radius * dropSize * mix(0.72, 1.2, random.y);
    vec2 delta = vec2(dx, dy);
    float headMask = 1.0 - smoothstep(r * 0.22, r, length(delta));

    float behind = (1.0 - smoothstep(-0.025, 0.0, dy)) * smoothstep(-0.42, -0.04, dy);
    float trailWidth = r * mix(0.11, 0.24, random.x);
    float trail = (1.0 - smoothstep(0.0, trailWidth, abs(dx))) * behind;
    float beadWave = abs(fract((-dy + random.x) * 21.0) - 0.5);
    float beads = (1.0 - smoothstep(0.0, 0.16, beadWave))
                * (1.0 - smoothstep(0.0, r * 0.62, abs(dx))) * behind;
    float coverage = clamp(headMask + trail * 0.34 + beads * 0.72, 0.0, 1.0);
    vec2 offset = vec2(dx, dy) * headMask + vec2(dx * 0.3, -r * 0.35) * (trail + beads);
    return vec3(offset, coverage);
}

vec3 condensation(vec2 uv) {
    vec2 cells = vec2(25.0, 16.0);
    vec2 grid = uv * cells;
    vec2 id = floor(grid);
    vec2 random = hash22(id + 53.7);
    vec2 local = fract(grid) - 0.5 - (random - 0.5) * 0.58;
    local.x *= aspect * cells.y / cells.x;
    float radius = mix(0.055, 0.19, random.x) * dropSize;
    float mask = 1.0 - smoothstep(radius * 0.28, radius, length(local));
    float density = step(random.y, clamp(fog * 0.28 + rainAmount * 0.12, 0.0, 0.45));
    return vec3(local * mask * 0.045, mask * density);
}

float rainField(vec2 uv, float scale, float speed, float phase) {
    vec2 p = vec2(uv.x * aspect, uv.y);
    p.y -= time * speed;
    p.x += p.y * 0.12;
    vec2 grid = p * vec2(scale, scale * 0.42);
    vec2 id = floor(grid);
    vec2 local = fract(grid) - 0.5;
    vec2 random = hash22(id + phase);
    float x = abs(local.x - (random.x - 0.5) * 0.62);
    float streak = (1.0 - smoothstep(0.0, 0.034, x))
                 * (1.0 - smoothstep(0.08, 0.5, abs(local.y)));
    return streak * step(0.78, random.y);
}

float snowField(vec2 uv, float scale, float speed, float phase) {
    vec2 p = vec2(uv.x * aspect, uv.y - time * speed);
    vec2 grid = p * vec2(scale, scale * 0.72);
    vec2 id = floor(grid);
    vec2 random = hash22(id + phase);
    vec2 local = fract(grid) - 0.5;
    local.x += sin(time * 0.4 + random.x * 6.2831 + p.y * 4.0) * 0.22;
    float flake = 1.0 - smoothstep(0.015, mix(0.10, 0.19, random.y), length(local));
    return flake * mix(0.35, 1.0, random.x);
}

void main() {
    vec2 uv = qt_TexCoord0;

    vec3 first = runner(uv, 7.0, 0.17, 0.085, 0.030);
    vec3 second = runner(uv + vec2(0.031, 0.0), 12.0, 4.71, 0.125, 0.020);
    vec3 staticDrops = condensation(uv);
    float coverage = clamp(first.z + second.z + staticDrops.z * 0.78, 0.0, 1.0);
    vec2 offset = (first.xy + second.xy + staticDrops.xy) * bend;
    float wiped = texture(wipe, uv).a;
    float clearPane = max(coverage, wiped);

    vec2 sampleUv = clamp(uv + offset, vec2(0.002), vec2(0.998));
    vec4 crisp = texture(sharp, sampleUv);
    vec4 haze = texture(blurred, clamp(uv + offset * 0.24, vec2(0.002), vec2(0.998)));
    vec4 color = mix(crisp, haze, clamp(fog * (1.0 - clearPane), 0.0, 1.0));

    float mist = noise21(vec2(uv.x * 3.2 + time * 0.018, uv.y * 2.4 - time * 0.009));
    color.rgb += vec3(0.055, 0.065, 0.082) * fog * (1.0 - clearPane) * (0.45 + mist * 0.5);

    float rain = rainField(uv, 18.0, 0.62, 7.4) * 0.72
               + rainField(uv, 28.0, 0.92, 3.1)
               + rainField(uv, 43.0, 1.32, 19.7) * 0.56;
    color.rgb += vec3(0.62, 0.76, 0.94) * rain * rainAmount * mix(0.58, 0.27, fog);

    float snow = snowField(uv, 13.0, 0.075, 8.4) + snowField(uv, 19.0, 0.105, 31.2) * 0.6;
    color.rgb += vec3(0.78, 0.86, 0.96) * snow * snowAmount * 0.48;

    float cloudVeil = noise21(vec2(uv.x * 2.1 + time * 0.011, uv.y * 3.0));
    color.rgb += vec3(0.035, 0.042, 0.052) * cloudAmount * smoothstep(0.36, 0.8, cloudVeil) * (1.0 - smoothstep(0.25, 0.8, uv.y));

    color.rgb *= 1.0 - stormAmount * 0.08;

    float specular = pow(clamp(-offset.y * 7.0 / max(bend, 0.001), 0.0, 1.0), 4.0) * coverage;
    float rim = smoothstep(0.08, 0.42, coverage) * (1.0 - smoothstep(0.55, 0.94, coverage));
    color.rgb += specular * vec3(0.24, 0.28, 0.34);
    color.rgb += rim * vec3(0.12, 0.15, 0.19);
    color.rgb *= 1.0 - coverage * 0.045;

    float vignette = 1.0 - smoothstep(0.28, 0.85, distance(uv, vec2(0.5)));
    color.rgb *= mix(0.72, 1.0, vignette);
    fragColor = color * qt_Opacity;
}
