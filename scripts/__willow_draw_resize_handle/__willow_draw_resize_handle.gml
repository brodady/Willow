/// @ignore Renders the tactile resize handle for a resizable box.
/// @param {Struct.WillowBox} _box The box instance.
function __willow_draw_resize_handle(_box) {
    if (!_box.__resizableH && !_box.__resizableV) return;

    var _dx = round(_box.getDrawX());
    var _dy = round(_box.getDrawY());
    var _w  = round(_box.__layout.width);
    var _h  = round(_box.__layout.height);

    var _inset = variable_struct_exists(_box.__render, "rounding") ? ceil(_box.__render.rounding * WILLOW_ROUNDING_INSET_FACTOR) : 0;
    var _hx = _dx + _w - (_box.__resizableH ? _inset + WILLOW_RESIZE_GUTTER : 0);
    var _hy = _dy + _h - (_box.__resizableV ? _inset + WILLOW_RESIZE_GUTTER : 0);

    var _sys = __WillowSystem();
    
    var _theme = _sys.theme;
    var _col = _theme.color.base_content;
    
    var _baseAlpha = variable_struct_exists(_box.__render, "handle_alpha") ? _box.__render.handle_alpha : 0.4;
    var _alpha = _baseAlpha * _box.__render.alpha[0];
    
    gpu_set_blendmode(bm_normal);
    
    // - RENDER GRIP PATTERN
    if (_sys.use_clean_shapes) {
        
        var _ox = 0.5;
        var _oy = 0.5;
        
        if (_box.__resizableH && _box.__resizableV) {
            CleanLine(_hx - 4 + _ox, _hy - 1 + _oy, _hx - 1 + _ox, _hy - 4 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
            CleanLine(_hx - 8 + _ox, _hy - 1 + _oy, _hx - 1 + _ox, _hy - 8 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
            CleanLine(_hx - 12 + _ox, _hy - 1 + _oy, _hx - 1 + _ox, _hy - 12 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
        } else if (_box.__resizableV) {
            var _cx = round(_dx + (_w / 2));
            CleanLine(_cx - 6 + _ox, _hy - 3 + _oy, _cx + 6 + _ox, _hy - 3 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
            CleanLine(_cx - 6 + _ox, _hy - 6 + _oy, _cx + 6 + _ox, _hy - 6 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
        } else if (_box.__resizableH) {
            var _cy = round(_dy + (_h / 2));
            CleanLine(_hx - 3 + _ox, _cy - 6 + _oy, _hx - 3 + _ox, _cy + 6 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
            CleanLine(_hx - 6 + _ox, _cy - 6 + _oy, _hx - 6 + _ox, _cy + 6 + _oy).Blend(_col, _alpha).Thickness(1).Draw();
        }
    } else {
        draw_set_color(_col);
        draw_set_alpha(_alpha);
        if (_box.__resizableH && _box.__resizableV) {
            draw_line_width(_hx - 4, _hy - 1, _hx - 1, _hy - 4, 1);
            draw_line_width(_hx - 8, _hy - 1, _hx - 1, _hy - 8, 1);
            draw_line_width(_hx - 12, _hy - 1, _hx - 1, _hy - 12, 1);
        } else if (_box.__resizableV) {
            var _cx = round(_dx + (_w / 2));
            draw_line_width(_cx - 6, _hy - 3, _cx + 6, _hy - 3, 1);
            draw_line_width(_cx - 6, _hy - 6, _cx + 6, _hy - 6, 1);
        } else if (_box.__resizableH) {
            var _cy = round(_dy + (_h / 2));
            draw_line_width(_hx - 3, _cy - 6, _hx - 3, _cy + 6, 1);
            draw_line_width(_hx - 6, _cy - 6, _hx - 6, _cy + 6, 1);
        }
        draw_set_alpha(1);
    }
}