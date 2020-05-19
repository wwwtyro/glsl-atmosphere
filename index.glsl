#define PI 3.141592
#define iSteps 16
#define jSteps 8

vec2 rsi(vec3 r0, vec3 rd, float sr) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    vec2 p = rsi(r0, r, rAtmos);

    // There are a few cases to distinguish:
    // 0a: The ray starts outside the atmosphere and does not intersect it.
    //     Return 0.
    // 0b: The ray starts inside the planet. Return 0.
    // 0c: The ray intersects the atmosphere at t < 0. Return 0.
    //
    // If isect_planet.y < 0, set isect_planet.y = 1e16 and
    // isect_planet.x = -1e16 to treat it as non-intersection.
    //
    // 1: The ray starts outside the atmosphere and intersects it at t > 0,
    //    but does not intersect the planet.
    //    Ray from p.x to p.y.
    // 2: The ray starts outside the atmosphere and intersects it at t > 0 and
    //    intersects the planet.
    //    Ray from p.x to isect_planet.x.
    // 3: The ray starts inside the atmosphere and does not intersect the
    //    planet.
    //    Ray from 0 to p.y.
    // 4: The ray starts inside the atmosphere and intersects the planet at
    //    t > 0.
    //    Ray from 0 to isect_planet.x.

    // Ray does not intersect the atmosphere (on the way forward) at all;
    // exit early.
    if (p.x > p.y || p.y < 0) return vec3(0,0,0);

    vec2 isect_planet = rsi(r0, r, rPlanet);

    // Ray starts inside the planet -> return 0
    if (isect_planet.x < 0 && isect_planet.y >= 0) {
        return vec3(0);
    }

    // Treat intersection of the planet in negative t as if the planet had not
    // been intersected at all.
    bool planet_intersected = (isect_planet.x < isect_planet.y && isect_planet.x > 0);

    // always start atmosphere ray at viewpoint if we start inside atmosphere
    p.x = max(p.x, 0);

    // if the planet is intersected, set the end of the ray to the planet
    // surface.
    p.y = planet_intersected ? isect_planet.y : p.y;

    float iStepSize = (p.y - p.x) / float(iSteps);

    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - rPlanet;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, rAtmos).y / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Calculate and return the final color.
    return iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie);
}

#pragma glslify: export(atmosphere)
