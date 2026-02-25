/// @ignore Ensures color values are 4-element arrays [TL, TR, BR, BL].
function __willow_ensure_colour_array(_c) {
    if (is_array(_c)) {
        if (array_length(_c) == 4) return _c;
        if (array_length(_c) >= 1) return [_c[0], _c[0], _c[0], _c[0]];
    }
    return is_real(_c) ? [_c, _c, _c, _c] : [c_white, c_white, c_white, c_white];
}