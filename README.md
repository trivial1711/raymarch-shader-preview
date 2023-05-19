# Raymarching Shader Preview
Tool for previewing a 3d raymarching shader.

## Building
Install [SFML 2.5.1](https://www.sfml-dev.org/download/sfml/2.5.1/) to `C:\SFML-2.5.1\` (or install it somewhere else and then edit line 3 of the Makefile accordingly). Then run `make release`.

## Using
Example usage:
```
.\main-release.exe mucube.glsl
```
Here, `mucube.glsl` can be replaced by the filename of any shader written in [GLSL 1.30](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.1.30.pdf) that implements a function `vec3 rayColor(vec3 position, vec3 direction)`. The function should take as input the starting position and (normalized) direction of a ray in three-dimensional space, and return the color of a scene along that ray. You may use the uniform float `time` in the shader to get the time in seconds since the application was started. See `mucube.glsl` or `moving_cubes.glsl` for examples.

Use 
```
.\main-release.exe --help
```
to get a list of allowed command line arguments. You can use these to start the program with a different window size, frame rate, field of view, mouse sensitivity, or camera movement speed.

You can use the mouse and WASD keys to change your view of the scene. Use F12 to take a screenshot.
