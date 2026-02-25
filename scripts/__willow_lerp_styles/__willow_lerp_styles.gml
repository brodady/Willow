/// @ignore Interpolates between two render properties for style transitions.
function __willow_lerp_styles(_from, _to, _amount, _key) {
    switch (_key) {
        case "colours":
        case "borderColours":
            if (!is_array(_from) || !is_array(_to)) return _to;
            var _res = array_create(4);
            var _i = 0; repeat(4) {
                _res[_i] = merge_colour(_from[_i], _to[_i], _amount);
                _i++;
            }
            return _res;

        case "alpha":
        case "borderAlpha":
            if (!is_array(_from) || !is_array(_to)) return _to;
            var _res = array_create(4);
            var _i = 0; repeat(4) {
                _res[_i] = lerp(_from[_i], _to[_i], _amount);
                _i++;
            }
            return _res;

        case "rounding":
        case "borderWidth":
        case "offsetX":
        case "offsetY":
        case "scaleX": 
        case "scaleY":   
        case "rotation": 
            return (is_real(_from) && is_real(_to)) ? lerp(_from, _to, _amount) : _to;

        default:
            return _to;
    }
}