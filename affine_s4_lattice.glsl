#define NUM_ITERATIONS 500
#define MAX_DIST 20.
#define FOG_START_DIST 10.
#define MIN_DIST 0.0001
#define EPSILON 0.00005
#define NUM_LIGHTS 4
#define SQRT3 1.73205080757

uniform vec3 lightVectors[NUM_LIGHTS] = vec3[NUM_LIGHTS](
    normalize(vec3(1., 1., 1.)),
    normalize(vec3(-1., -2., 1.)),
    normalize(vec3(-1., 1., -2.)),
    normalize(vec3(1., -2., -1.))
);
uniform vec3 lightColors[NUM_LIGHTS] = vec3[NUM_LIGHTS](
    vec3(0., 1., 0.),
    vec3(0., 0.5, 1.),
    vec3(1., 0., 1.),
    vec3(1., 0.5, 0.)
);

uniform vec3 xs[4] = vec3[4](
    vec3(1/SQRT3, 1/SQRT3, 1/SQRT3),
    vec3(1/SQRT3, -1/SQRT3, -1/SQRT3),
    vec3(-1/SQRT3, -1/SQRT3, 1/SQRT3),
    vec3(-1/SQRT3, 1/SQRT3, -1/SQRT3)
);

const vec3 diffuse = vec3(1., 1., 1.);
const vec3 fog = vec3(1., 1., 1.);
const float alpha = 10.;

float dist(vec3 p) {
    float a = dot(xs[0] - xs[1], p);
    float b = dot(xs[1] - xs[2], p);
    float c = dot(xs[2] - xs[3], p);
    float d = dot(xs[3] - xs[0], p);
    return 3.0 / 8.0 * min(min(a, b), min(c, 1+d));
}

vec3 gradient(vec3 x) {
    vec3 u = vec3(dist(x + vec3(EPSILON, 0, 0)), dist(x + vec3(0, EPSILON, 0)), dist(x + vec3(0, 0, EPSILON)));
    vec3 v = vec3(dist(x - vec3(EPSILON, 0, 0)), dist(x - vec3(0, EPSILON, 0)), dist(x - vec3(0, 0, EPSILON)));
    return (u - v)/ (2. * EPSILON);
}

float march(vec3 origin, vec3 direction, float s) {
    float v = 0.;
    for(int i = 0; i < NUM_ITERATIONS; i++) {
        float d = s * dist(origin + direction * v);
        v += d;
        if(v > MAX_DIST || d < MIN_DIST) {
            break;
        }
    }
    return v;
}

vec3 rayColor(vec3 position, vec3 direction)
{
    float s = sign(dist(position));
    float distance = march(position, direction, s);
    vec3 rayDestination = position + distance * direction;
    vec3 normal = s * gradient(rayDestination);

    vec3 color = vec3(0., 0., 0.);
    for(int i = 0; i < NUM_LIGHTS; i++) {
        vec3 R = reflect(lightVectors[i], normal);
        float diffuseCoeff = max(-dot(lightVectors[i], normal), 0.0);
        float specularCoeff = max(-dot(R, direction), 0.0);
        color += diffuseCoeff * diffuse * lightColors[i] + pow(specularCoeff, alpha) * lightColors[i];
    }
 
    float farness = clamp((distance - FOG_START_DIST) / (MAX_DIST - FOG_START_DIST), 0., 1.);

    return mix(color, fog, farness);
}