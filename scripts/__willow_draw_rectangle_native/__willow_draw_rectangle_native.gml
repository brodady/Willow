/// @ignore Draws a rounded rectangle using native GM functions.
/// @param {Real} _x The draw X coordinate.
/// @param {Real} _y The draw Y coordinate.
/// @param {Real} _w The draw width.
/// @param {Real} _h The draw height.
/// @param {Struct} _r The render state struct from WillowStyle.
function __willow_draw_rectangle_native(_x, _y, _w, _h, _r) {
    var _borderAlpha = _r.borderAlpha[0];
    var _mainAlpha   = _r.alpha[0];
    
    // 1. Draw Border/Outline
    if (_r.borderWidth > 0 && _borderAlpha > 0) {
        draw_set_alpha(_borderAlpha);
        var _bc1 = _r.borderColours[0]; 
        var _bc2 = _r.borderColours[2];
        
        // Expand coordinates by borderWidth to draw the outline on the outside
        draw_roundrect_colour_ext(
            _x - _r.borderWidth, _y - _r.borderWidth,
            _x + _w + _r.borderWidth, _y + _h + _r.borderWidth,
            _r.rounding, _r.rounding, _bc1, _bc2, false
        );
    }
    
    // 2. Draw Main Fill
    if (_mainAlpha > 0) {
        draw_set_alpha(_mainAlpha);
        var _c1 = _r.colours[0]; 
        var _c2 = _r.colours[2];
        
        draw_roundrect_colour_ext(
            _x, _y, 
            _x + _w, _y + _h, 
            _r.rounding, _r.rounding, _c1, _c2, false
        );
    }
    
    draw_set_alpha(1);
}