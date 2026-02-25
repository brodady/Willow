/// @func    __willow_draw_focus_ring(_x, _y, _w, _h, _rounding, _thickness, _gap, _color, _alpha)
/// @desc    Draws a masked focus ring using the destination alpha channel stencil trick.
/// @param   {Real} _x
/// @param   {Real} _y
/// @param   {Real} _w
/// @param   {Real} _h
/// @param   {Real} _rounding
/// @param   {Real} _thickness
/// @param   {Real} _gap
/// @param   {Real} _color
/// @param   {Real} _alpha
/// @return  {Undefined}
/// @func    __willow_draw_focus_ring(_x, _y, _w, _h, _rounding, _thickness, _gap, _color, _alpha)
function __willow_draw_focus_ring(_x, _y, _w, _h, _rounding, _thickness, _gap, _color, _alpha) {
    var _sys = __WillowSystem();
    
    var _clampedRounding = min(_rounding, min(_w, _h) / 2);
    
    var _outX1 = _x - _gap - _thickness;
    var _outY1 = _y - _gap - _thickness;
    var _outX2 = _x + _w + _gap + _thickness;
    var _outY2 = _y + _h + _gap + _thickness;
    var _outR  = _clampedRounding + _gap + _thickness;

    var _inX1 = _x - _gap;
    var _inY1 = _y - _gap;
    var _inX2 = _x + _w + _gap;
    var _inY2 = _y + _h + _gap;
    var _inR  = _clampedRounding + _gap;

    if (_sys.use_clean_shapes) {
        // Counteract AA Erosion. The shader's Feather() eats ~1px total from the borders.
        var _aaPad = CleanAntialiasGet() ? 1.0 : 0;
        
        CleanRectangle(_outX1, _outY1, _outX2, _outY2)
            .Blend(_color, 0) 
            .Border(_thickness + _aaPad, _color, _alpha)
            .Rounding(_outR)
            .Draw();
    } else {
        // - HARDWARE STENCIL FOCUS RING (Native)
        var _prevAlpha = draw_get_alpha();
        var _prevColor = draw_get_color();
        var _nOff = 1; 
        
        var _ref = 0;
        if (gpu_get_stencil_enable()) _ref = gpu_get_stencil_ref();
        else {
            gpu_set_stencil_enable(true);
            gpu_set_stencil_ref(0);
        }

        gpu_set_colorwriteenable(false, false, false, false);
        gpu_set_stencil_func(cmpfunc_equal);
        gpu_set_stencil_ref(_ref);
        gpu_set_stencil_pass(stencilop_incr);
        
        draw_set_alpha(1);
        if (_inR > 0) draw_roundrect_ext(_inX1 + _nOff, _inY1 + _nOff, _inX2 - 1, _inY2 - 1, _inR, _inR, false);
        else draw_rectangle(_inX1 + _nOff, _inY1 + _nOff, _inX2 - 1, _inY2 - 1, false);

        gpu_set_colorwriteenable(true, true, true, true);
        gpu_set_stencil_func(cmpfunc_equal);
        gpu_set_stencil_ref(_ref);
        gpu_set_stencil_pass(stencilop_keep);
        
        draw_set_color(_color);
        draw_set_alpha(_alpha);
        if (_outR > 0) draw_roundrect_ext(_outX1 + _nOff, _outY1 + _nOff, _outX2 - 1, _outY2 - 1, _outR, _outR, false);
        else draw_rectangle(_outX1 + _nOff, _outY1 + _nOff, _outX2 - 1, _outY2 - 1, false);

        gpu_set_colorwriteenable(false, false, false, false);
        gpu_set_stencil_func(cmpfunc_equal);
        gpu_set_stencil_ref(_ref + 1);
        gpu_set_stencil_pass(stencilop_decr);
        
        draw_set_alpha(1);
        if (_inR > 0) draw_roundrect_ext(_inX1 + _nOff, _inY1 + _nOff, _inX2 - 1, _inY2 - 1, _inR, _inR, false);
        else draw_rectangle(_inX1 + _nOff, _inY1 + _nOff, _inX2 - 1, _inY2 - 1, false);

        gpu_set_colorwriteenable(true, true, true, true);
        gpu_set_stencil_func(cmpfunc_equal);
        gpu_set_stencil_ref(_ref);
        gpu_set_stencil_pass(stencilop_keep);
        
        draw_set_color(_prevColor);
        draw_set_alpha(_prevAlpha);
        if (_ref == 0) gpu_set_stencil_enable(false);
    }
}