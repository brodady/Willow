/// @ignore Intersects a requested area with the hardware scissor, accounting for GUI scale.
/// @param {Any} _x X coordinate or a struct/array containing bounds.
/// @param {Real} [_y] Y coordinate.
/// @param {Real} [_w] Width.
/// @param {Real} [_h] Height.
function __willow_gpu_set_scissor_intersect(_x, _y = undefined, _w = undefined, _h = undefined) {
    var _p = gpu_get_scissor();
    var _px, _py, _pw, _ph;
    
    // - EXTRACT CURRENT BOUNDS
    if (is_struct(_p)) {
        _px = _p.x; _py = _p.y; _pw = _p.w; _ph = _p.h;
    } else if (is_array(_p)) {
        _px = _p[0]; _py = _p[1]; _pw = _p[2]; _ph = _p[3];
    } else return;

    // - RESOLVE INPUT ARGUMENTS
    if (is_array(_x)) {
        _y = _x[1]; _w = _x[2]; _h = _x[3]; _x = _x[0];
    } else if (is_struct(_x)) {
        _y = _x.y; _w = _x.w; _h = _x.h; _x = _x.x;
    }

    // - COORDINATE TRANSFORMATION
    // Important: The GPU scissor operates in window space on the back buffer, but Willow operates in GUI space.
    var _scaleX = window_get_width() / max(1, display_get_gui_width());
    var _scaleY = window_get_height() / max(1, display_get_gui_height());

    var _tx = _x * _scaleX;
    var _ty = _y * _scaleY;
    var _tw = _w * _scaleX;
    var _th = _h * _scaleY;

    // - CALCULATE INTERSECTION
    var _x1 = max(_tx, _px);
    var _y1 = max(_ty, _py);
    var _x2 = min(_tx + _tw, _px + _pw);
    var _y2 = min(_ty + _th, _py + _ph);
    
    gpu_set_scissor(_x1, _y1, max(0, _x2 - _x1), max(0, _y2 - _y1));
}