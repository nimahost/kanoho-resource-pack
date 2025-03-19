#version 330

uniform float GameTime;

in vec3 coord;
in float sky;

out vec4 fragColor;


// Hash function to generate random numbers for nebula https://www.shadertoy.com/view/ttc3zr
vec3 hash(vec3 p3, const in float x_loop_dist) {
    p3.x = mod(p3.x, x_loop_dist);
	p3 = fract(p3 * vec3(10.31, 10.3, 9.73));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// Hash function to generate random numbers for stars
uvec3 murmurHash33(uvec3 src) {
    const uint M = 0x5bd1e995u;
    uvec3 h = uvec3(1190494759u, 2147483647u, 3559788179u);
    src *= M; src ^= src>>24u; src *= M;
    h *= M; h ^= src.x; h *= M; h ^= src.y; h *= M; h ^= src.z;
    h ^= h>>13u; h *= M; h ^= h>>15u;
    return h;
}

vec3 hash33(vec3 src) {
    uvec3 h = murmurHash33(floatBitsToUint(src));
    return uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0;
}

// Voronoi noise function for nebulas https://github.com/MaxBittker/glsl-voronoi-noise?tab=MIT-1-ov-file
vec3 voronoi3d(const in vec3 x, const in float x_loop_dist) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    float id = 0.0;
    vec2 res = vec2(100.0);
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 b = vec3(float(i), float(j), float(k));
                vec3 r = vec3(b) - f + hash(p + b, x_loop_dist);
                float d = dot(r, r);

                float cond = max(sign(res.x - d), 0.0);
                float nCond = 1.0 - cond;

                float cond2 = nCond * max(sign(res.y - d), 0.0);
                float nCond2 = 1.0 - cond2;

                id = (dot(p + b, vec3(1.0, 57.0, 113.0)) * cond) + (id * nCond);
                res = vec2(d, res.x) * cond + res * nCond;

                res.y = cond2 * d + nCond2 * res.y;
            }
        }
    }

    return vec3(sqrt(res), abs(id));
}


#define pi 3.141592653589792328462643383279502884197
#define tau 6.28318531
#define itau 0.159154943

//# section start quality high
// // High Quality Nebulas
// const float cfg_step_long = 0.2;
// const float cfg_step_short = 0.08;
// const float cfg_short_step_density_start = 0.3;
// const float cfg_short_step_density_end = 0.8;
// const int cfg_steps = 30;
// const float cfg_density = 6.0;
// const float cfg_max_density = 1.0;
// const bool cfg_double_density = true;

// const vec3 cfg_neb1 = vec3(0.3, 0.3, 0.6);
// const vec3 cfg_neb2 = vec3(0.4, 0.0, 0.0);

// // High Quality Stars
// const float cfg_star_scale = 300;
// const float cfg_star_prob_space = 0.0001;
// const float cfg_star_prob_nebula = 0.0025;
// const float cfg_star_prob_front = 0.01;
// const float cfg_far_star_density = 0.6;
// const float cfg_star_cylinder_size = 0.25;
// const int cfg_extra_star_layers = 40;
// const float cfg_min_star_radius = cfg_step_long;
// const float cfg_max_star_radius = 6;
//# section end

//# section start quality normal
// Normal Nebulas
const float cfg_step_long = 0.5;
const float cfg_step_short = 0.1;
const float cfg_short_step_density_start = 0.3;
const float cfg_short_step_density_end = 0.8;
const int cfg_steps = 10;
const float cfg_density = 3.0;
const float cfg_max_density = 1.0;
const bool cfg_double_density = false;

const vec3 cfg_neb1 = vec3(0.3, 0.3, 0.6);
const vec3 cfg_neb2 = vec3(0.5, 0.0, 0.0);

// Normal Stars
const float cfg_star_scale = 300;
const float cfg_star_prob_space = 0.0002;
const float cfg_star_prob_nebula = 0.01;
const float cfg_star_prob_front = 0.01;
const float cfg_far_star_density = 0.5;
const float cfg_star_cylinder_size = 0.5;
const int cfg_extra_star_layers = 10;
const float cfg_min_star_radius = cfg_step_long;
const float cfg_max_star_radius = 4;
//# section end

//# section start quality low
// // Low Quality Nebulas
// const float cfg_step_long = 0.6;
// const float cfg_step_short = 0.2;
// const float cfg_short_step_density_start = 0.4;
// const float cfg_short_step_density_end = 0.8;
// const int cfg_steps = 5;
// const float cfg_density = 3.0;
// const float cfg_max_density = 1.0;
// const bool cfg_double_density = false;

// const vec3 cfg_neb1 = vec3(0.3, 0.3, 0.6);
// const vec3 cfg_neb2 = vec3(0.4, 0.05, 0.1);

// // Low Quality Stars
// const float cfg_star_scale = 300;
// const float cfg_star_prob_space = 0.0004;
// const float cfg_star_prob_nebula = 0.02;
// const float cfg_star_prob_front = 0.01;
// const float cfg_far_star_density = 0.5;
// const float cfg_star_cylinder_size = 1.0;
// const int cfg_extra_star_layers = 5;
// const float cfg_min_star_radius = cfg_step_long;
// const float cfg_max_star_radius = 4;
//# section end

// Other
vec3 cfg_background = vec3(0.01, 0.01, 0.02);
float cfg_min_fac = 0.05;
float cfg_speed = 10.0;
float cfg_star_change_speed = 7.0;
float cfg_rotations = 1.0;
// float cfg_speed = 0;
// float cfg_rotations = 0;

float cfg_short_step_density_sf = 1 / (cfg_short_step_density_end - cfg_short_step_density_start);
float cfg_max_dist = cfg_step_long * cfg_steps;
int cfg_max_star_layers_per_step = int(ceil(cfg_step_long / cfg_star_cylinder_size)) + 1;

vec4 star_texture_cylinder(float a, float x, float r, float forward_factor, float density, float x_loop_dist) {
    vec2 scale = vec2(cfg_star_scale / r, floor(cfg_star_scale * tau)); // the sqrt here causes some stares to not be square but I think its worth it
    vec2 tex_coord = floor(vec2(mod(x, x_loop_dist), (a + pi) * itau) * scale);

    vec3 v3 = hash33(vec3(tex_coord, r));
    float v = fract(v3.x + v3.y + v3.z);
    if (v <= mix(cfg_star_prob_space, cfg_star_prob_nebula, density) * (0.9 - (forward_factor * forward_factor) * 1.1))
        return vec4(1.0, 1.0, 1.0, 1.0 - r / cfg_max_star_radius);
    else
        return vec4(0.0);
}

vec4 star_texture_plane(vec2 tex_coord, float forward_factor) {
    tex_coord = floor(tex_coord * cfg_star_scale);

    vec3 v3 = hash33(vec3(tex_coord, 0.0));
    float v = fract(v3.x + v3.y + v3.z);

    v -= GameTime * cfg_star_change_speed;
    v = fract(v);

    if (v <= cfg_star_prob_front) {
        v /= cfg_star_prob_front;
        v = 1.0 - abs(2.0 * v - 1.0);
        v *= max(abs(forward_factor) * 2.0 - 1.0, 0.0);
        return vec4(v, v, v, 1.0);
    }
    else
        return vec4(0.0);
}

// Main rendering
void main() {
    if (abs(sky - 16) > 0.01) discard;

    float s = sin(GameTime * tau * cfg_rotations);
    float c = cos(GameTime * tau * cfg_rotations);

    // Normalize to make accurate direction
    vec3 direction = normalize(coord);
    direction = vec3(
        direction.x,
        direction.y * c + direction.z * s,
        direction.z * c - direction.y * s
    );

    // Raycast setup
    vec3 pos = vec3(GameTime * cfg_speed, 0.0, 0.0);
    float dist = cfg_step_long;
    vec3 col = vec3(0.0, 0.0, 0.0);
    float fac = 1.0;
    float t_dist = 0.0;

    // Star collider shape setup
    float cylinder_size = cfg_star_cylinder_size / length(direction.yz);
    float inv_cylinder_size = 1.0 / cylinder_size;
    // Calculate the angle of the point on the star cylinder
    float a = atan(direction.y, direction.z);
    float forward_factor = dot(direction, vec3(1.0, 0.0, 0.0));
    
    // Raycast
    for (int i = 0; i < cfg_steps; i++)
    {
        // Move
        pos += direction * dist;
        t_dist += dist;

        // Sample nebula
        float raw_density = voronoi3d(pos, cfg_speed).x;
        if (cfg_double_density) {
            raw_density = mix(raw_density, voronoi3d(pos * 2, cfg_speed * 2).x, 0.25);
        }

        // Calculate rendered density
        float density = 2.0 * max(raw_density, 0.5) - 1.0;
        density *= density * density;
        density *= cfg_density;
        density = min(density, cfg_max_density);

        // Calculate nebula colour
        vec3 neb_col = mix(cfg_neb1, cfg_neb2, t_dist / cfg_max_dist);

        // Calculate next nebula step
        float t = clamp((raw_density - cfg_short_step_density_start) * cfg_short_step_density_sf, 0.0, 1.0);
        dist = mix(cfg_step_long, cfg_step_short, t);

        // Loop for all possible star layers
        float star_prop = 0.0;
        for (int j = 0; j <= cfg_max_star_layers_per_step; j++) {
            
            // Find the distance to the next star layer
            float delta_pos = cylinder_size - mod(t_dist + star_prop, cylinder_size);
            if (delta_pos < 1e-6 && j > 0) delta_pos += cylinder_size;
            
            // Apply nebula colour
            if (star_prop + delta_pos > dist) {
                // If no star layer remaining add final nebula contribution
                float dist_cont = 1.0 - pow(0.5, dist - star_prop);
                float visual_density = density * dist_cont;
                col += neb_col * visual_density * fac;
                fac *= 1.0 - visual_density;
                break;
            } else {
                // Add nebula contribution up to next star layer
                float dist_cont = 1.0 - pow(0.5, delta_pos);
                float visual_density = density * dist_cont;
                col += neb_col * visual_density * fac;
                fac *= 1.0 - visual_density;

                ////////////////////////////////////////////////////////////////////////
                // OPTAMISATION: Combine nebula colour calculations if no star impact //
                ////////////////////////////////////////////////////////////////////////
            }

            // Move to the next star layer
            star_prop += delta_pos;

            // Calculate total distance to star layer
            float star_dist = t_dist + star_prop;

            // Calculate x coordinate of the colision
            float x = pos.x + direction.x * star_prop;

            // Calculate radius of the star cylinder
            float r = round(star_dist * inv_cylinder_size) * cfg_star_cylinder_size;

            // Calculate the angle of the point on the star cylinder
            float a = atan(direction.y, direction.z);

            // Set the colour of the star cylinder at that point
            if (r <= cfg_max_star_radius) {
                if (r >= cfg_min_star_radius) {
                    vec4 colour = star_texture_cylinder(a, x, r, forward_factor, density, cfg_speed);
                    col += colour.rgb * colour.a * fac;
                    fac *= 1.0 - colour.a;
                    if (colour.a >= 1.0) break;
                }
            } else {
                break;
            }
        }

        if (fac < cfg_min_fac)
            break;
    }

    // Loop for extra star layers past the nebula
    // Move
    pos += direction * dist;
    t_dist += dist;

    float star_prop = 0.0;
    for (int j = 0; j < cfg_extra_star_layers; j++) {
        
        // Find the distance to the next star layer
        float delta_pos = cylinder_size - mod(t_dist + star_prop, cylinder_size);
        if (delta_pos < 1e-5) delta_pos += cylinder_size;

        // Move to the next star layer
        star_prop += delta_pos;

        // Calculate total distance to star layer
        float star_dist = t_dist + star_prop;

        // Calculate x coordinate of the colision
        float x = pos.x + direction.x * star_prop;

        // Calculate radius of the star cylinder
        float r = round(star_dist * inv_cylinder_size) * cfg_star_cylinder_size;

        // Set the colour of the star cylinder at that point
        if (r <= cfg_max_star_radius) {
            if (r >= cfg_min_star_radius) {
                vec4 colour = star_texture_cylinder(a, x, r, forward_factor, cfg_far_star_density, cfg_speed);
                col += colour.rgb * colour.a * fac;
                fac *= 1.0 - colour.a;
                if (colour.a >= 1.0) break;
            }
        } else {
            break;
        }
    }

    // Add static stars
    vec2 tex_coord = direction.yz / direction.x;
    vec4 colour = star_texture_plane(tex_coord, forward_factor);
    col += colour.rgb * colour.a * fac;
    fac *= 1.0 - colour.a;

    // Apply remaining colour
    col += cfg_background * fac;

    // Set colour to output
    fragColor = vec4(vec3(col), 1.0);
}
