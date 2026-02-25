/// @func    __willow_draw_rectangle_native(_x, _y, _w, _h, _render)
/// @desc    Draws the base component background using strictly aligned GM primitives.
function __willow_draw_rectangle_native(_x, _y, _w, _h, _render) {
    var _rounding = variable_struct_exists(_render, "rounding") ? _render.rounding : 0;
    var _clampedR = min(_rounding, _w / 2, _h / 2);
    
    var _nOff = 1;
    var _x1 = _x + _nOff;
    var _y1 = _y + _nOff;
    var _x2 = _x + _w - 1;
    var _y2 = _y + _h - 1;

    var _prevAlpha = draw_get_alpha();
    var _prevColor = draw_get_color();

    // Draw Solid Background
    if (variable_struct_exists(_render, "colours")) {
        draw_set_alpha(_render.alpha[0]);
        draw_set_color(_render.colours[0]);
        if (_clampedR > 0) draw_roundrect_ext(_x1, _y1, _x2, _y2, _clampedR, _clampedR, false);
        else draw_rectangle(_x1, _y1, _x2, _y2, false);
    }

    // Draw Concentric Border Thickness
    if (variable_struct_exists(_render, "borderWidth") && _render.borderWidth > 0) {
        var _bw = _render.borderWidth;
        draw_set_alpha((variable_struct_exists(_render, "borderAlpha") ? _render.borderAlpha[0] : 1) * _render.alpha[0]);
        draw_set_color(variable_struct_exists(_render, "borderColours") ? _render.borderColours[0] : c_white);
        
        // Loop the thickness inward to simulate a true stroke outline
        var _i = 0; repeat(_bw) {
            var _br = max(0, _clampedR - _i);
            if (_br > 0) draw_roundrect_ext(_x1 + _i, _y1 + _i, _x2 - _i, _y2 - _i, _br, _br, true);
            else draw_rectangle(_x1 + _i, _y1 + _i, _x2 - _i, _y2 - _i, true);
            _i++;
        }
    }

    draw_set_alpha(_prevAlpha);
    draw_set_color(_prevColor);
}