#define SHADER_NAME quad.frag

precision highp float;

varying vec3 vPosition;

uniform vec3 uSunPos;

#pragma glslify: atmosphere = require(../index)

void main() {
    vec3 color = atmosphere(
        normalize(vPosition),           // normalized ray direction
        vec3(0,6372e3,0),               // ray origin
        uSunPos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );

    // Apply exposure.
    color = 1.0 - exp(-1.0 * color);

    gl_FragColor = vec4(color, 1);
}
