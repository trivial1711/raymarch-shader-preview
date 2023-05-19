#define NUM_ITERATIONS 300
#define EPSILON 0.001
#define NUM_LIGHTS 3

uniform vec3 lightVectors[NUM_LIGHTS] = vec3[NUM_LIGHTS](
    normalize(vec3(2., -2., -1.)),
    normalize(vec3(-4., -3., -1.)),
    normalize(vec3(-1., 4., 2.))
);
uniform vec3 lightColors[NUM_LIGHTS] = vec3[NUM_LIGHTS](
    vec3(0.9, 0.08, 0),
    vec3(0.06, 0.8, 0.2),
    vec3(0.02, 0.03, 0.7)
);

const vec3 diffuse = vec3(1., 1., 1.);
const float alpha = 10.;

vec3 rayColor(vec3 position, vec3 direction)
{
    vec3 normal = vec3(0., 0., 0.);

    for(int i = 0; i < NUM_ITERATIONS; i++) {
        ivec3 j = ivec3(floor(position));
        vec3 t = ((1. + sign(direction)) / 2. - sign(direction) * fract(position)) / abs(direction);

        position += (min(t.x, min(t.y, t.z)) + EPSILON) * direction;

        if(t.x <= t.y && t.x <= t.z && (j.y + j.z) % 2 != 0) {
            normal = vec3(-sign(direction.x), 0., 0.);
            break;
        }
        if(t.y <= t.x && t.y <= t.z && (j.x + j.z) % 2 != 0) {
            normal = vec3(0., -sign(direction.y), 0.);
            break;
        }
        if(t.z <= t.x && t.z <= t.y && (j.x + j.y) % 2 != 0) {
            normal = vec3(0., 0., -sign(direction.z));
            break;
        }
    }

    vec3 color = vec3(0., 0., 0.);
    for(int i = 0; i < NUM_LIGHTS; i++) {
        vec3 R = reflect(lightVectors[i], normal);
        float diffuseCoeff = max(-dot(lightVectors[i], normal), 0.0);
        float specularCoeff = max(-dot(R, direction), 0.0);
        color += diffuseCoeff * diffuse * lightColors[i] + pow(specularCoeff, alpha) * lightColors[i];
    }

    return color;
}