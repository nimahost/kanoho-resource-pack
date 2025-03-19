#version 150

uniform float GameTime;

in vec3 coord;
in float sky;

out vec4 fragColor;

#define farNebulaColor        vec3(0.2714285714285714, 0.1, 0.1285714285714286)
#define farNebulaBias         0.05
#define farNebulaMultiplier   0.4
#define farNebulaDistance     1.5

#define midNebulaColor        vec3(0.1857142857142857, 0.1, 0.21428571428571425)
#define midNebulaBias         0.05
#define midNebulaMultiplier   0.6
#define midNebulaDistance     1.25

#define nearNebulaColor       vec3(0.1, 0.1, 0.3)
#define nearNebulaBias        0.05
#define nearNebulaMultiplier  1.2

float snoise(vec3 P) {
    //  https://github.com/BrianSharpe/Wombat/blob/master/SimplexPerlin3D.glsl

    //  simplex math constants
    const float SKEWFACTOR = 1.0/3.0;
    const float UNSKEWFACTOR = 1.0/6.0;
    const float SIMPLEX_CORNER_POS = 0.5;
    const float SIMPLEX_TETRAHADRON_HEIGHT = 0.70710678118654752440084436210485;    // sqrt( 0.5 )

    //  establish our grid cell.
    P *= SIMPLEX_TETRAHADRON_HEIGHT;    // scale space so we can have an approx feature size of 1.0
    vec3 Pi = floor( P + dot( P, vec3( SKEWFACTOR) ) );

    //  Find the vectors to the corners of our simplex tetrahedron
    vec3 x0 = P - Pi + dot(Pi, vec3( UNSKEWFACTOR ) );
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 Pi_1 = min( g.xyz, l.zxy );
    vec3 Pi_2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - Pi_1 + UNSKEWFACTOR;
    vec3 x2 = x0 - Pi_2 + SKEWFACTOR;
    vec3 x3 = x0 - SIMPLEX_CORNER_POS;

    //  pack them into a parallel-friendly arrangement
    vec4 v1234_x = vec4( x0.x, x1.x, x2.x, x3.x );
    vec4 v1234_y = vec4( x0.y, x1.y, x2.y, x3.y );
    vec4 v1234_z = vec4( x0.z, x1.z, x2.z, x3.z );

    // clamp the domain of our grid cell
    Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
    vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

    //    generate the random vectors
    vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
    Pt *= Pt;
    vec4 V1xy_V2xy = mix( Pt.xyxy, Pt.zwzw, vec4( Pi_1.xy, Pi_2.xy ) );
    Pt = vec4( Pt.x, V1xy_V2xy.xz, Pt.z ) * vec4( Pt.y, V1xy_V2xy.yw, Pt.w );
    const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
    const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );
    vec3 lowz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + Pi.zzz * ZINC.xyz ) );
    vec3 highz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + Pi_inc1.zzz * ZINC.xyz ) );
    Pi_1 = ( Pi_1.z < 0.5 ) ? lowz_mods : highz_mods;
    Pi_2 = ( Pi_2.z < 0.5 ) ? lowz_mods : highz_mods;
    vec4 hash_0 = fract( Pt * vec4( lowz_mods.x, Pi_1.x, Pi_2.x, highz_mods.x ) ) - 0.49999;
    vec4 hash_1 = fract( Pt * vec4( lowz_mods.y, Pi_1.y, Pi_2.y, highz_mods.y ) ) - 0.49999;
    vec4 hash_2 = fract( Pt * vec4( lowz_mods.z, Pi_1.z, Pi_2.z, highz_mods.z ) ) - 0.49999;

    //    evaluate gradients
    vec4 grad_results = inversesqrt( hash_0 * hash_0 + hash_1 * hash_1 + hash_2 * hash_2 ) * ( hash_0 * v1234_x + hash_1 * v1234_y + hash_2 * v1234_z );

    //    Normalization factor to scale the final result to a strict 1.0->-1.0 range
    //    http://briansharpe.wordpress.com/2012/01/13/simplex-noise/#comment-36
    const float FINAL_NORMALIZATION = 37.837227241611314102871574478976;

    //  evaulate the kernel weights ( use (0.5-x*x)^3 instead of (0.6-x*x)^4 to fix discontinuities )
    vec4 kernel_weights = v1234_x * v1234_x + v1234_y * v1234_y + v1234_z * v1234_z;
    kernel_weights = max(0.5 - kernel_weights, 0.0);
    kernel_weights = kernel_weights*kernel_weights*kernel_weights;

    //    sum with the kernel and return
    return dot( kernel_weights, grad_results ) * FINAL_NORMALIZATION;
}

// Random Number Generator
float rand( vec3 co )
{
    float b = fract( sin( co.x + co.y*524.6786780 + co.z*937.67568756870 ) * 752.65434545);
    float a = fract( cos( co.x + co.y*2395.42342340 + co.z*97.0988900 ) * 153.5724257524);
    float c = mix(a, b, 0.5);
    return c;
}

float nebula( vec3 position, mat4 offset, float bias, float multiplier)
{
    position = (offset * vec4(position, 1.0)).xyz;
    float v = snoise(position);
    v += snoise(position * 5) / 4;
    v += snoise(position * 20) / 10;
    //v += snoise(position * 40) / 15;
    v *= multiplier;
    v += bias;
    return max(0.0, v);
}

float stars( vec3 position, mat4 offset, float starSize, float starThreshold )
{
    //commented code is for rounded stars
    position = (offset * vec4(position, 1.0)).xyz / starSize;
    vec3 roundedPosition = floor(position);
    //vec3 pixelOffset = (position - roundedPosition - vec3(0.5)) * 2;
    //float dist = dot(pixelOffset, pixelOffset);
    float value = pow(rand(roundedPosition), starThreshold);
    //value *= 1.0 - dist * dist;
    //value = max(value, 0.0);
	return value * 2;
}

void main() {
    if (abs(sky - 16) > 0.01) discard;

    // Normalize to make accurate direction
    vec3 position = normalize(coord);

    float angle = GameTime * 5.0;
    float c = cos(angle);
    float s = sin(angle);
	mat4 offset = mat4(
        1, 0, 0, 0,
        0, c, -s, 0,
        0, s, c, 0,
        GameTime * 10.0, 0, 0, 1);

	vec3 color = vec3(0.0);
    // position is the position of the pixel in worldspace
    // offset is the virtual offset of the universe for the animated sky movement
    // color is the color of the sky for that pixel

    vec3 cylinderPosition = position / length(position.yz);
    vec3 spherePosition = normalize(position);

    vec3 edgeStars = vec3(stars(cylinderPosition, offset, 0.005, 80.0));
    edgeStars += vec3(stars(cylinderPosition * 2.27341867, offset, 0.007, 60.0));
    edgeStars += vec3(stars(cylinderPosition * 3.16573287, offset, 0.009, 40.0));

    mat4 nebulaOffset = offset;
    vec3 nebulas = farNebulaColor * nebula(spherePosition * farNebulaDistance, nebulaOffset, farNebulaBias, farNebulaMultiplier);
    nebulaOffset[3][1] += 0.02;
    nebulas += mix(vec3(0.0), midNebulaColor, nebula(spherePosition * midNebulaDistance, nebulaOffset, midNebulaBias, midNebulaMultiplier));
    nebulaOffset[3][1] += 0.02;
    nebulas += mix(vec3(0.0), nearNebulaColor, nebula(spherePosition, nebulaOffset, nearNebulaBias, nearNebulaMultiplier));

    mat4 rotationalOffset = offset;
    rotationalOffset[3][0] = 0;
    vec3 endStars = vec3(stars(spherePosition, rotationalOffset, 0.0025, 40.0));

    color += max(mix(edgeStars, endStars, mix(-0.5, 1.0, abs(dot(spherePosition, vec3(1.0, 0.0, 0.0))))), vec3(0.0));
    color += nebulas;

	// drawing the skybox
	fragColor = vec4(color, 1.0);
}
