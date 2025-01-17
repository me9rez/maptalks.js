const float COMMON_FLOAT_MAX =  1.70141184e38;
const float COMMON_FLOAT_MIN = 1.17549435e-38;
//https://github.com/tensorfire/tensorfire/tree/12e07bf2786cd5a1464e634cc0c429479723cbdb/src/format/1-4/codec/softfloat
float common_packFloat(vec4 val){
    vec4 scl = floor(255.0 * val + 0.5);
    float sgn = (scl.a < 128.0) ? 1.0 : -1.0;
    float exn = mod(scl.a * 2.0, 256.0) + floor(scl.b / 128.0) - 127.0;
    float man = 1.0 +
        (scl.r / 8388608.0) +
        (scl.g / 32768.0) +
        mod(scl.b, 128.0) / 128.0;
    return sgn * man * pow(2.0, exn);
}

vec4 common_unpackFloat(highp float v) {
    highp float av = abs(v);

    //Handle special cases
    if(av < COMMON_FLOAT_MIN) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    } else if(v > COMMON_FLOAT_MAX) {
        return vec4(127.0, 128.0, 0.0, 0.0) / 255.0;
    } else if(v < -COMMON_FLOAT_MAX) {
        return vec4(255.0, 128.0, 0.0, 0.0) / 255.0;
    }

    highp vec4 c = vec4(0,0,0,0);

    //Compute exponent and mantissa
    highp float e = floor(log2(av));
    highp float m = av * pow(2.0, -e) - 1.0;

    //Unpack mantissa
    c[1] = floor(128.0 * m);
    m -= c[1] / 128.0;
    c[2] = floor(32768.0 * m);
    m -= c[2] / 32768.0;
    c[3] = floor(8388608.0 * m);

    //Unpack exponent
    highp float ebias = e + 127.0;
    c[0] = floor(ebias / 2.0);
    ebias -= c[0] * 2.0;
    c[1] += floor(ebias) * 128.0;

    //Unpack sign bit
    c[0] += 128.0 * step(0.0, -v);

    //Scale back to range
    return c / 255.0;
}

vec4 common_encodeDepth(const in float depth) {
    float alpha = 1.0;
    vec4 pack = vec4(0.0);
    pack.a = alpha;
    const vec3 code = vec3(1.0, 255.0, 65025.0);
    pack.rgb = vec3(code * depth);
    pack.gb = fract(pack.gb);
    pack.rg -= pack.gb * (1.0 / 256.0);
    pack.b -= mod(pack.b, 4.0 / 255.0);
    return pack;
}

float common_decodeDepth(const in vec4 pack) {
    return pack.r + pack.g / 255.0;
}
