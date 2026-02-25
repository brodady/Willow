/// @ignore Recursively renders text and accessories for all components in the list.
/// @param {Array<Struct.WillowBox>} _boxList The list of boxes to process.
function __willow_draw_text_recursive(_boxList) {
    var _len = array_length(_boxList);
    var _i = 0; repeat(_len) {
        var _box = _boxList[_i];
        if (is_struct(_box)) {
            // Standard pass skips overlays
            var _isOverlay = (variable_struct_exists(_box, "__isOverlay") && _box.__isOverlay);
            if (_isOverlay) { _i++; continue; }

            // Text rendering (will natively recurse through internal children)
            if (variable_struct_exists(_box, "drawText")) {
                _box.drawText();
            }
        }
        _i++;
    }
}