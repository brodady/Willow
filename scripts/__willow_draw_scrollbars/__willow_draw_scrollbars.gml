/// @ignore Renders scrollbars for a box if content is overflowing.
/// @param {Struct.WillowBox} _box The box instance.
function __willow_draw_scrollbars(_box) {
    if (_box.__maxScrollY <= 0 && _box.__maxScrollX <= 0) return;
    
    var _sys = __WillowSystem();
    var _dx = _box.getDrawX();
    var _dy = _box.getDrawY();
    var _w = _box.__layout.width;
    var _h = _box.__layout.height;
    
    // - METRIC RESOLUTION
    var _inset = variable_struct_exists(_box.__render, "rounding") ? ceil(_box.__render.rounding * 0.5) + 4 : 2;
    var _theme = _sys.theme;
    var _col = variable_struct_exists(_box.__render, "handle_colour") ? _box.__render.handle_colour : _theme.color.base_content;
    var _alpha = (variable_struct_exists(_box.__render, "handle_alpha") ? _box.__render.handle_alpha : 0.5) * _box.__render.alpha[0];

    if (!_box.__eventState.hover && !_box.__isResizing) _alpha *= 0.4;

    // - VERTICAL SCROLLBAR
    if (_box.__maxScrollY > 0) {
        var _trackH = _h - (_inset * 2) - (_box.__maxScrollX > 0 ? 8 : 0);
        var _thumbH = max(20, (_h / (_h + _box.__maxScrollY)) * _trackH);
        var _thumbY = _dy + _inset + (_box.__scrollY / _box.__maxScrollY) * (_trackH - _thumbH);
        
        var _sx1 = _dx + _w - 6 - _inset;
        var _sy1 = _dy + _inset;
        var _sx2 = _dx + _w - 2 - _inset;
        var _sy2 = _dy + _inset + _trackH;

        if (_sys.use_clean_shapes) {
            CleanRectangle(_sx1, _sy1, _sx2, _sy2).Rounding(2).Blend(_col, _alpha * 0.2).Draw();
            CleanRectangle(_sx1, _thumbY, _sx2, _thumbY + _thumbH).Rounding(2).Blend(_col, _alpha * 0.8).Draw();
        } else {
            draw_set_color(_col);
            draw_set_alpha(_alpha * 0.2);
            draw_roundrect(_sx1, _sy1, _sx2, _sy2, false);
            draw_set_alpha(_alpha * 0.8);
            draw_roundrect(_sx1, _thumbY, _sx2, _thumbY + _thumbH, false);
        }
    }
    
    // - HORIZONTAL SCROLLBAR
    if (_box.__maxScrollX > 0) {
        var _trackW = _w - (_inset * 2) - (_box.__maxScrollY > 0 ? 8 : 0);
        var _thumbW = max(20, (_w / (_w + _box.__maxScrollX)) * _trackW);
        var _thumbX = _dx + _inset + (_box.__scrollX / _box.__maxScrollX) * (_trackW - _thumbW);
        
        var _sx1 = _dx + _inset;
        var _sy1 = _dy + _h - 6 - _inset;
        var _sx2 = _dx + _inset + _trackW;
        var _sy2 = _dy + _h - 2 - _inset;

        if (_sys.use_clean_shapes) {
            CleanRectangle(_sx1, _sy1, _sx2, _sy2).Rounding(2).Blend(_col, _alpha * 0.2).Draw();
            CleanRectangle(_thumbX, _sy1, _thumbX + _thumbW, _sy2).Rounding(2).Blend(_col, _alpha * 0.8).Draw();
        } else {
            draw_set_color(_col);
            draw_set_alpha(_alpha * 0.2);
            draw_roundrect(_sx1, _sy1, _sx2, _sy2, false);
            draw_set_alpha(_alpha * 0.8);
            draw_roundrect(_thumbX, _sy1, _thumbX + _thumbW, _sy2, false);
        }
    }
    draw_set_alpha(1);
}