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
function __willow_draw_focus_ring(_x, _y, _w, _h, _rounding, _thickness, _gap, _color, _alpha) {
    var _sys = __WillowSystem();

    // This prevents massive "pill-shape" radii (like 999) from mathematically inverting the corner arcs.
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
        // CleanShapes handles hollow SDF borders natively
        CleanRectangle(_outX1, _outY1, _outX2, _outY2)
            .Blend(c_white, 0)
            .Border(_thickness, _color, _alpha)
            .Rounding(_outR)
            .Draw();
    } else {
        // Make a border by masking rectangles
        gpu_set_colorwriteenable(false, false, false, true);

        gpu_set_blendmode(bm_subtract);
        draw_set_alpha(1);
        draw_rectangle(_outX1, _outY1, _outX2, _outY2, false);

        gpu_set_blendmode(bm_add);
        draw_set_alpha(_alpha);
        draw_roundrect_ext(_outX1, _outY1, _outX2, _outY2, _outR, _outR, false);

        gpu_set_blendmode(bm_subtract);
        draw_set_alpha(1);
        draw_roundrect_ext(_inX1, _inY1, _inX2, _inY2, _inR, _inR, false);

        gpu_set_colorwriteenable(true, true, true, true);
        gpu_set_blendmode_ext(bm_dest_alpha, bm_inv_dest_alpha);

        draw_set_color(_color);
        draw_set_alpha(1); 
        draw_rectangle(_outX1, _outY1, _outX2, _outY2, false); 

        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white);
        draw_set_alpha(1);
    }
}