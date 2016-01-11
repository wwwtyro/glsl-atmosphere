#define SHADER_NAME quad.vert

attribute vec3 aPosition;

varying vec3 vPosition;

void main() {
    gl_Position = vec4(aPosition, 1.0);
    vPosition = aPosition;
}
