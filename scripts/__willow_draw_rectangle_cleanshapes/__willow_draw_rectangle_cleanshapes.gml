/// @ignore Draws a rectangle using the CleanShapes batching engine.
/// @param {Real} _bx The base X coordinate (pre-transform).
/// @param {Real} _by The base Y coordinate (pre-transform).
/// @param {Real} _bw The base width.
/// @param {Real} _bh The base height.
/// @param {Struct} _r The render state struct from WillowStyle.
/// @func    __willow_draw_rectangle_cleanshapes(_x, _y, _w, _h, _render)
function __willow_draw_rectangle_cleanshapes(_x, _y, _w, _h, _render) {
    var _rounding = variable_struct_exists(_render, "rounding") ? _render.rounding : 0;
    
    var _clampedR = min(_rounding, min(_w, _h) / 2);
    
    var _c1 = variable_struct_exists(_render, "colours") ? _render.colours[0] : c_white;
    var _a1 = _render.alpha[0];
    
    var _rect = CleanRectangle(_x, _y, _x + _w, _y + _h)
        .Rounding(_clampedR)
        .Blend(_c1, _a1);
        
    if (variable_struct_exists(_render, "borderWidth") && _render.borderWidth > 0) {
        var _bc = variable_struct_exists(_render, "borderColours") ? _render.borderColours[0] : c_white;
        var _ba = (variable_struct_exists(_render, "borderAlpha") ? _render.borderAlpha[0] : 1) * _a1;
        
        // Pad the component's inner borders to counter the shader's AA erosion
        var _aaPad = CleanAntialiasGet() ? 1.0 : 0;
        _rect.Border(_render.borderWidth + _aaPad, _bc, _ba);
    }
    
    _rect.Draw();
}