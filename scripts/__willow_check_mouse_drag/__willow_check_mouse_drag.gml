/// @ignore Checks for a left-click drag based on system sensitivity.
function __willow_check_mouse_drag() {
    var _dx = abs(window_mouse_get_delta_x());
    var _dy = abs(window_mouse_get_delta_y());
    return (mouse_check_button(mb_left) && (_dx >= WILLOW_DRAG_THRESHOLD || _dy >= WILLOW_DRAG_THRESHOLD));
}