#define NUM_ITERATIONS 500
#define MAX_DIST 100.
#define MIN_DIST 0.001
#define EPSILON 0.001
#define SQRT2 1.41421356237309504880
#define SQRT3 1.73205080757

const float cubeSpeed = 0.2;
const float cameraSpeed = 0.1;
const mat3 camera = mat3(0., SQRT2 * SQRT3 / 3., SQRT3/3.,
                        -SQRT2/2., -SQRT2 * SQRT3 / 6., SQRT3/3.,
                        SQRT2/2., -SQRT2 * SQRT3 / 6., SQRT3/3.);
const vec3 light = normalize(vec3(5., -2., -1.));
const vec3 diffuse = vec3(0.4, 0.2, 0.8);
const vec3 specular = vec3(0.9, 0.08, 0);
const vec3 background = vec3(0.03, 0.2, 0.35);
const float alpha = 10.;

float maxComponent(vec3 p) {
    return max(p.x, max(p.y, p.z));
}

float maxAbsComponent(vec3 p) {
    return maxComponent(abs(p));
}

float dist(vec3 p) {
    ivec3 i = ivec3(floor(p));
    
    if(i.x % 2 != 0 && i.y % 2 == 0)  {
        return maxAbsComponent(fract(p - vec3(0., 0., time * cubeSpeed)) - 0.5) - 0.2;
    }
    if(i.y % 2 != 0 && i.z % 2 == 0)  {
        return maxAbsComponent(fract(p - vec3(time * cubeSpeed, 0., 0.)) - 0.5) - 0.2;
    }
    if(i.z % 2 != 0 && i.x % 2 == 0)  {
        return maxAbsComponent(fract(p - vec3(0., time * cubeSpeed, 0.)) - 0.5) - 0.2;
    }
    
    return 0.3;
}

vec3 gradient(vec3 x) {
    vec3 u = vec3(dist(x + vec3(EPSILON, 0, 0)), dist(x + vec3(0, EPSILON, 0)), dist(x + vec3(0, 0, EPSILON)));
    vec3 v = vec3(dist(x - vec3(EPSILON, 0, 0)), dist(x - vec3(0, EPSILON, 0)), dist(x - vec3(0, 0, EPSILON)));
    return (u - v)/ (2. * EPSILON);
}

float march(vec3 origin, vec3 direction) {
    float v = 0.;
    for(int i = 0; i < NUM_ITERATIONS; i++) {
        float d = dist(origin + direction * v);
        v += d;
        if(v > MAX_DIST || d < MIN_DIST) {
            break;
        }
    }
    return v;
}

vec3 rayColor(vec3 position, vec3 direction)
{
    float v = march(position, direction);
    vec3 p = position + direction * v;
    vec3 n = normalize(gradient(p));
    vec3 R = reflect(light, n);

    float diffuseCoeff = max(-dot(light, n), 0.0);
    float specularCoeff = max(-dot(R, direction), 0.0);

    vec3 surfaceColor = diffuseCoeff * diffuse + pow(specularCoeff, alpha) * specular;
    float farness = mix(0.4, 1., clamp(v / MAX_DIST, 0., 1.));

    return mix(surfaceColor, background, farness);
}