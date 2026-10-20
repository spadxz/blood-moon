#version 440
// A clean, code-drawn scarlett for the Scarlett theme. The surface is
// procedural, so it has no embedded stock artwork or background image.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
};

float moonHash(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float moonNoise(vec2 p)
{
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = moonHash(cell);
    float b = moonHash(cell + vec2(1.0, 0.0));
    float c = moonHash(cell + vec2(0.0, 1.0));
    float d = moonHash(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float moonFbm(vec2 p)
{
    float value = 0.0;
    float amplitude = 0.5;
    for (int octave = 0; octave < 4; ++octave) {
        value += amplitude * moonNoise(p);
        p = p * 2.03 + vec2(17.1, 9.2);
        amplitude *= 0.5;
    }
    return value;
}

void main()
{
    vec2 uv = qt_TexCoord0;
    float aspect = itemSize.x / max(itemSize.y, 1.0);

    // Keep the moon in the upper-right of the player so the cover and controls
    // remain readable in front of it.
    vec2 delta = vec2((uv.x - 0.73) * aspect, uv.y - 0.29);
    float distanceFromMoon = length(delta);
    const float moonRadius = 0.205;

    vec3 background = vec3(0.004, 0.003, 0.006);
    float outside = smoothstep(moonRadius - 0.003, moonRadius + 0.006, distanceFromMoon);
    float haloFalloff = exp(-max(distanceFromMoon - moonRadius, 0.0) * 17.0);
    float haloLimit = 1.0 - smoothstep(moonRadius + 0.12, moonRadius + 0.46, distanceFromMoon);
    float halo = haloFalloff * haloLimit * outside;
    background += vec3(0.34, 0.012, 0.025) * halo;
    background += vec3(0.11, 0.004, 0.014)
                  * exp(-distanceFromMoon * 5.2)
                  * (1.0 - smoothstep(moonRadius + 0.06, moonRadius + 0.72, distanceFromMoon));

    float disc = 1.0 - smoothstep(moonRadius - 0.002, moonRadius + 0.002, distanceFromMoon);
    vec3 colour = background;

    if (disc > 0.0) {
        vec2 sphere = delta / moonRadius;
        float depth = sqrt(max(0.0, 1.0 - dot(sphere, sphere)));
        vec3 normal = normalize(vec3(sphere.x, -sphere.y, depth));
        vec3 lightDirection = normalize(vec3(-0.42, -0.46, 0.82));
        float light = max(dot(normal, lightDirection), 0.12);

        // Broad maria and smaller craters give the surface lunar detail while
        // keeping the illustration crisp at typical desktop sizes.
        vec2 surface = vec2(atan(normal.x, normal.z) * 0.7, normal.y * 1.8);
        float maria = moonFbm(surface * 4.8 + vec2(1.7, 3.4));
        float texture = moonFbm(surface * 17.0 + vec2(8.1, 2.6));
        float fineTexture = moonNoise(surface * 76.0 + vec2(4.2, 11.8));
        float darkSea = smoothstep(0.42, 0.69, maria);
        float craterBands = smoothstep(0.44, 0.66, texture);

        vec3 ember = vec3(0.93, 0.12, 0.035);
        vec3 hotEdge = vec3(1.0, 0.37, 0.105);
        vec3 deepSea = vec3(0.28, 0.012, 0.025);
        vec3 surfaceColour = mix(ember, hotEdge, smoothstep(0.36, 0.93, texture));
        surfaceColour = mix(surfaceColour, deepSea, darkSea * 0.62);
        surfaceColour *= 0.40 + 0.74 * light;
        surfaceColour *= 0.94 + fineTexture * 0.14;
        surfaceColour *= 0.88 + craterBands * 0.2;

        float rim = pow(max(dot(normal, lightDirection), 0.0), 3.4);
        surfaceColour += vec3(0.22, 0.035, 0.025) * rim;
        colour = mix(background, surfaceColour, disc);
    }

    fragColor = vec4(colour, 1.0) * qt_Opacity;
}
