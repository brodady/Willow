/// @ignore Renders the tactile resize handle for a resizable box.
/// @param {Struct.WillowBox} _box The box instance.
function __willow_draw_resize_handle(_box) {
    if (!_box.__resizableH && !_box.__resizableV) return;

    // Constrain coordinates to whole integers to prevent anti-aliasing 
    // interpolation flickering during floating-point transform animations.
    var _dx = round(_box.getDrawX());
    var _dy = round(_box.getDrawY());
    var _w  = round(_box.__layout.width);
    var _h  = round(_box.__layout.height);

    var _inset = variable_struct_exists(_box.__render, "rounding") ? ceil(_box.__render.rounding * WILLOW_ROUNDING_INSET_FACTOR) : 0;
    var _hx = _dx + _w - (_box.__resizableH ? _inset + WILLOW_RESIZE_GUTTER : 0);
    var _hy = _dy + _h - (_box.__resizableV ? _inset + WILLOW_RESIZE_GUTTER : 0);

    var _sys = __WillowSystem();
    
    // Calculate theme-agnostic intensity based on parent alpha.
    // By scaling the grey value toward black (0), we simulate alpha fading natively within the difference blend mode.
    var _alpha = (variable_struct_exists(_box.__render, "handle_alpha") ? _box.__render.handle_alpha : 0.5) * _box.__render.alpha[0];
    var _intensity = 200 * _alpha; 
    var _col = make_color_rgb(_intensity, _intensity, _intensity);
    
    // Preserve destination alpha, but apply difference/exclusion blending to RGB
    gpu_set_blendmode_ext_sepalpha(bm_inv_dest_colour, bm_inv_src_colour, bm_zero, bm_one);
    
    // - RENDER GRIP PATTERN
    if (_sys.use_clean_shapes) {
        if (_box.__resizableH && _box.__resizableV) {
            CleanLine(_hx - 4, _hy - 1, _hx - 1, _hy - 4).Blend(_col, 1).Thickness(1).Draw();
            CleanLine(_hx - 8, _hy - 1, _hx - 1, _hy - 8).Blend(_col, 1).Thickness(1).Draw();
            CleanLine(_hx - 12, _hy - 1, _hx - 1, _hy - 12).Blend(_col, 1).Thickness(1).Draw();
        } else if (_box.__resizableV) {
            var _cx = round(_dx + (_w / 2));
            CleanLine(_cx - 6, _hy - 3, _cx + 6, _hy - 3).Blend(_col, 1).Thickness(1).Draw();
            CleanLine(_cx - 6, _hy - 6, _cx + 6, _hy - 6).Blend(_col, 1).Thickness(1).Draw();
        } else if (_box.__resizableH) {
            var _cy = round(_dy + (_h / 2));
            CleanLine(_hx - 3, _cy - 6, _hx - 3, _cy + 6).Blend(_col, 1).Thickness(1).Draw();
            CleanLine(_hx - 6, _cy - 6, _hx - 6, _cy + 6).Blend(_col, 1).Thickness(1).Draw();
        }
    } else {
        draw_set_color(_col);
        draw_set_alpha(1);
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
    }
    
    // Restore standard pipeline
    gpu_set_blendmode(bm_normal);
}