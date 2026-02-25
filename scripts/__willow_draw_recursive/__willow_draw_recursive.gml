/// @ignore Recursively renders box backgrounds and shapes, skipping overlays.
/// @param {Array<Struct.WillowBox>} _boxList The list of boxes to render.
/// @param {Bool} _useCleanShapes Whether to use the CleanShapes batching engine.
function __willow_draw_recursive(_boxList, _useCleanShapes) {
    var _len = array_length(_boxList);
    var _i = 0; repeat(_len) {
        var _box = _boxList[_i];
        if (is_struct(_box)) {
            // Standard pass skips overlays (handled by Willow.draw overlay pass)
            var _isOverlay = (variable_struct_exists(_box, "__isOverlay") && _box.__isOverlay);
            if (_isOverlay) { _i++; continue; }

            // Standard Draw logic (Backgrounds + drawComponent hook)
            if (variable_struct_exists(_box, "draw")) {
                _box.draw(_useCleanShapes);
            }
        }
        _i++;
    }
}