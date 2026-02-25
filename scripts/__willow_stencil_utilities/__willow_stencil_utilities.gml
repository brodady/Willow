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

    // 1. Enable Stencil Testing
    if (!gpu_get_stencil_enable()) {
        gpu_set_stencil_enable(true);
        gpu_set_stencil_ref(0);
    }
    var _ref = gpu_get_stencil_ref();

    // 2. Disable color write so the mask shape is completely invisible (Prevents punched holes)
    gpu_set_colorwriteenable(false, false, false, false);

    // 3. Configure the stencil to increment (+1) where the shape is drawn
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_ref);
    gpu_set_stencil_pass(stencilop_incr);

    var _prevAlpha = draw_get_alpha();
    draw_set_alpha(1); 

    // 4. DRAW NATIVE MASK
    // We STRICTLY use native shapes here because shader-based SDFs (CleanShapes) use 
    // fragment shaders to cut corners, which the Early-Stencil test ignores.
    // We also subtract 1 from the width/height to fix GM's inclusive-pixel overrun.
    var _x2 = _x + _w - 1;
    var _y2 = _y + _h - 1;

    if (_rounding > 0) {
        draw_roundrect_ext(_x, _y, _x2, _y2, _rounding, _rounding, false);
    } else {
        draw_rectangle(_x, _y, _x2, _y2, false);
    }
    
    draw_set_alpha(_prevAlpha);

    // 5. Restore color write and set the test to ONLY allow drawing inside the new level
    gpu_set_colorwriteenable(true, true, true, true);
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_ref + 1);
    gpu_set_stencil_pass(stencilop_keep);

    return _ref; // Return the previous level to pass into pop()
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

    // 1. Disable color drawing
    gpu_set_colorwriteenable(false, false, false, false);

    // 2. Configure stencil to decrement (-1) the pixels back to their previous level
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_prevRef + 1);
    gpu_set_stencil_pass(stencilop_decr);

    var _prevAlpha = draw_get_alpha();
    draw_set_alpha(1);

    // 3. ERASER MASK
    var _x2 = _x + _w - 1;
    var _y2 = _y + _h - 1;

    if (_rounding > 0) {
        draw_roundrect_ext(_x, _y, _x2, _y2, _rounding, _rounding, false);
    } else {
        draw_rectangle(_x, _y, _x2, _y2, false);
    }
    
    draw_set_alpha(_prevAlpha);

    // 4. Restore state
    gpu_set_colorwriteenable(true, true, true, true);
    gpu_set_stencil_func(cmpfunc_equal);
    gpu_set_stencil_ref(_prevRef); // Restore the parent's reference constraint
    gpu_set_stencil_pass(stencilop_keep);

    // Turn off stencil completely if we have returned to the root level
    if (_prevRef == 0) {
        gpu_set_stencil_enable(false);
    }
}