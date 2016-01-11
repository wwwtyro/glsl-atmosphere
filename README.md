# glsl-atmosphere

Renders sky colors with Rayleigh and Mie scattering.

<p align='center'>
    <img src="https://raw.githubusercontent.com/wwwtyro/glsl-atmosphere/master/images/atmosphere.png" width="100%">
</p>

## Install

```sh
npm install glsl-atmosphere
```

## Example

### Javascript

```js
var quad = Geometry(gl)
    .attr('aPosition', [
        -1, -1, -1,
         1, -1, -1,
         1,  1, -1,
        -1, -1, -1,
         1,  1, -1,
        -1,  1, -1
    ]);

program.bind();
quad.bind(program);
program.uniforms.uSunPos = [0, 0.1, -1];
quad.draw();
```

### Vertex Shader
```glsl
attribute vec3 aPosition;

varying vec3 vPosition;

void main() {
    gl_Position = vec4(aPosition, 1.0);
    vPosition = aPosition;
}
```

### Fragment Shader
```glsl
varying vec3 vPosition;

uniform vec3 uSunPos;

#pragma glslify: atmosphere = require(glsl-atmosphere)

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
```

## API
```js
#pragma glslify: atmosphere = require(glsl-atmosphere)
```

#### `vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g)`

Returns a `vec3` representing the color of the sky along a view direction.

Takes:

* `vec3 r` normalized ray direction, typically a ray cast from the observers eye through a pixel
* `vec3 r0` ray origin in meters, typically the position of the viewer's eye
* `vec3 pSun` the position of the sun
* `float iSun` intensity of the sun
* `float rPlanet` radius of the planet in meters
* `float rAtoms` radius of the atmosphere in meters
* `vec3 kRlh` Rayleigh scattering coefficient
* `vec3 kMie` Mie scattering coefficient
* `float shRlh` Rayleigh scale height in meters
* `float shMie` Mie scale height in meters
* `float g` Mie preferred scattering direction

For an Earth-like atmosphere, see the settings in the example above.

## Credits

* [scratchapixel](http://www.scratchapixel.com/lessons/goodies/simulating-sky)
* [nvidia](http://http.developer.nvidia.com/GPUGems2/gpugems2_chapter16.html)
* [patapom](http://patapom.com/topics/Revision2013/Revision%202013%20-%20Real-time%20Volumetric%20Rendering%20Course%20Notes.pdf)
