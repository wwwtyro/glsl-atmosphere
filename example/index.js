var Geometry = require('gl-geometry');
var glShader = require('gl-shader');
var glslify = require('glslify');

var canvas = document.createElement('canvas');
canvas.width = canvas.height = 128;
document.body.appendChild(canvas);

var gl = canvas.getContext('webgl');
gl.clearColor(1,0,1,1);

var quad = Geometry(gl)
    .attr('aPosition', [
        -1, -1, -1,
         1, -1, -1,
         1,  1, -1,
        -1, -1, -1,
         1,  1, -1,
        -1,  1, -1
    ]);

var program = glShader(gl, glslify('./example.vert'), glslify('./example.frag'));

function reflow() {
    document.body.style.background = '#333';
    document.body.style.margin = '0px';
    canvas.style.position = 'fixed';
    var s = Math.min(window.innerHeight, window.innerWidth) * 0.95;
    canvas.style.height = canvas.style.width = s + 'px';
    canvas.style.left = (window.innerWidth/2 - s/2) + 'px';
    canvas.style.top = (window.innerHeight/2 - s/2) + 'px';
}

var theta = 0;

function render() {
    reflow();
    theta += 0.0125;
    gl.clear(gl.COLOR_BUFFER_BIT);
    program.bind();
    quad.bind(program);
    program.uniforms.uSunPos = [0, Math.cos(theta) * 0.3 + 0.2, -1];
    quad.draw();
    requestAnimationFrame(render);
}

render();
