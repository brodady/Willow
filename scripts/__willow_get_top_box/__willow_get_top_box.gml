/// @ignore Internal: Recursively find the topmost box under the mouse coordinates.
/// @return {Struct|Noone}
function __willow_get_top_box(box_list, mouse_x, mouse_y) {
    var _best_box = noone;
    var _best_depth = infinity;
    var _len = array_length(box_list);
    
    for (var i = 0; i < _len; i++) {
        var _current_box = box_list[i];
        if (!is_struct(_current_box) || !variable_struct_exists(_current_box, "__render") ||
            !variable_struct_exists(_current_box.__render, "depth") || !variable_struct_exists(_current_box, "__layout")) {
            continue;
        }

        // If a container is explicitly unhittable, skip it AND its children
        if (variable_struct_exists(_current_box, "__isHittable") && !_current_box.__isHittable) continue;

        var _layout = _current_box.__layout;
        var _w = _layout.width * _current_box.__render.scaleX;
        var _h = _layout.height * _current_box.__render.scaleY;
        var _x = _layout.left + (_layout.width - _w) / 2;
        var _y = _layout.top + (_layout.height - _h) / 2;

        var _is_hovered = point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h);
        
        if (_is_hovered) {
            var _top_child = noone;
            if (variable_struct_exists(_current_box, "__children") && array_length(_current_box.__children) > 0) {
                _top_child = __willow_get_top_box(_current_box.__children, mouse_x, mouse_y);
            }

            var _candidate_box = noone;
            if (_top_child != noone) {
                _candidate_box = _top_child;
            } else {
                var _hasSprite = (variable_struct_exists(_current_box.__render, "sprite_index") && _current_box.__render.sprite_index != -1);
                if ((_current_box.__render.alpha[0] > 0 || _hasSprite) && (_current_box.__render.scaleX != 0 || _current_box.__render.scaleY != 0)) {
                    _candidate_box = _current_box;
                }
            }

            // Calculate depth for the winning candidate
            if (_candidate_box != noone) {
                var _candidate_depth = infinity;
                if (variable_struct_exists(_candidate_box, "__render")) {
                    _candidate_depth = _candidate_box.__render.depth;
                }

                var _check_overlay = _candidate_box;
                while (_check_overlay != undefined && _check_overlay != noone) {
                    if (variable_struct_exists(_check_overlay, "__isOverlay") && _check_overlay.__isOverlay) {
                        _candidate_depth -= 1000000;
                        break;
                    }
                    _check_overlay = variable_struct_exists(_check_overlay, "__parent") ? _check_overlay.__parent : undefined;
                }

                if (_candidate_depth < _best_depth) {
                    _best_depth = _candidate_depth;
                    _best_box = _candidate_box;
                }
            }
        }
    }
    return _best_box;
}