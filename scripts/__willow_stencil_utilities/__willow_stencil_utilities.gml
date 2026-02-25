/// @func    __willow_mask_push(_x, _y, _w, _h, _rounding)
/// @desc    Pushes a hierarchical stencil mask to perfectly clip children to scaled/rounded bounds.
/// @param   {Real} _x
/// @param   {Real} _y
/// @param   {Real} _w
/// @param   {Real} _h
/// @param   {Real} _rounding
/// @return  {Real} The previous stencil reference level.
function __willow_mask_push(_x, _y, _w, _h, _rounding) {
    var _sys = __WillowSystem();

    if (!gpu_get_stencil_enable()) {
        gpu_set_stencil_enable(true);
        gpu_set_stencil_ref(0);
    }
    var _ref = gpu_get_stencil_ref();

    gpu_set_colorwriteenable(false, false, false, false);
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_ref);
    gpu_set_stencil_pass(stencilop_incr);

    var _prevAlpha = draw_get_alpha();
    draw_set_alpha(1); 

    var _clampedR = min(_rounding, _w / 2, _h / 2);
    
    var _nOff = 1;
    var _x1 = _x + _nOff;
    var _y1 = _y + _nOff;
    var _x2 = _x + _w - 1;
    var _y2 = _y + _h - 1;

    if (_clampedR > 0) draw_roundrect_ext(_x1, _y1, _x2, _y2, _clampedR, _clampedR, false);
    else draw_rectangle(_x1, _y1, _x2, _y2, false);
    
    draw_set_alpha(_prevAlpha);

    gpu_set_colorwriteenable(true, true, true, true);
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_ref + 1);
    gpu_set_stencil_pass(stencilop_keep);

    return _ref;
}

/// @func    __willow_mask_pop(_x, _y, _w, _h, _rounding, _prevRef)
/// @desc    Pops a hierarchical stencil mask, restoring the parent's clipping area.
/// @param   {Real} _x
/// @param   {Real} _y
/// @param   {Real} _w
/// @param   {Real} _h
/// @param   {Real} _rounding
/// @param   {Real} _prevRef
/// @return  {Undefined}
function __willow_mask_pop(_x, _y, _w, _h, _rounding, _prevRef) {
    var _sys = __WillowSystem();

    gpu_set_colorwriteenable(false, false, false, false);
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_prevRef + 1);
    gpu_set_stencil_pass(stencilop_decr);

    var _prevAlpha = draw_get_alpha();
    draw_set_alpha(1);

    var _clampedR = min(_rounding, _w / 2, _h / 2);
    var _nOff = 1;
    var _x1 = _x + _nOff;
    var _y1 = _y + _nOff;
    var _x2 = _x + _w - 1;
    var _y2 = _y + _h - 1;

    if (_clampedR > 0) draw_roundrect_ext(_x1, _y1, _x2, _y2, _clampedR, _clampedR, false);
    else draw_rectangle(_x1, _y1, _x2, _y2, false);
    
    draw_set_alpha(_prevAlpha);

    gpu_set_colorwriteenable(true, true, true, true);
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_prevRef); 
    gpu_set_stencil_pass(stencilop_keep);

    if (_prevRef == 0) gpu_set_stencil_enable(false);
}