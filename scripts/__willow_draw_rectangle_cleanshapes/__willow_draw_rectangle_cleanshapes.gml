/// @ignore Draws a rectangle using the CleanShapes batching engine.
/// @param {Real} _bx The base X coordinate (pre-transform).
/// @param {Real} _by The base Y coordinate (pre-transform).
/// @param {Real} _bw The base width.
/// @param {Real} _bh The base height.
/// @param {Struct} _r The render state struct from WillowStyle.
function __willow_draw_rectangle_cleanshapes(_bx, _by, _bw, _bh, _r) {
    CleanBatchBegin();

    var _shape = CleanRectangle(_bx, _by, _bx + _bw, _by + _bh)
        .Blend4(
            _r.colours[0], _r.alpha[0], 
            _r.colours[1], _r.alpha[1], 
            _r.colours[2], _r.alpha[2], 
            _r.colours[3], _r.alpha[3]
        )
        .Border4(
            _r.borderWidth,
            _r.borderColours[0], _r.borderAlpha[0], 
            _r.borderColours[1], _r.borderAlpha[1], 
            _r.borderColours[2], _r.borderAlpha[2], 
            _r.borderColours[3], _r.borderAlpha[3]
        )
        .Rounding(_r.rounding);
    
    _shape.Draw(); 
    CleanBatchEndDraw();
}