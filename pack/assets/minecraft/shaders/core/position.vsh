#version 150

#moj_import <minecraft:fog.glsl>

in vec3 Position;

uniform mat4 ProjMat;
uniform mat4 ModelViewMat;

out vec3 coord;
out float sky;

void main() {
    // Output y for sky disc identification to discard things like stars
    sky = Position.y;

    // Rotate sky disk to be in front
    vec4 pos = vec4(
        Position.x,
        Position.z,
        - Position.y,
        1.0);
    
    // Calculate world space direction of vertex
    coord = (inverse(ModelViewMat) * pos).xyz;

    // Don't multiply by ModelViewMat to lock to screen
    gl_Position = ProjMat * pos;
}

// Alternative main function to show off the sky disks
// void main() {
//     sky = abs(Position.y);
//     vec3 pos = Position * vec3(0.03125, 1.0, 0.03125);
//     coord = pos;
//     gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
// }
