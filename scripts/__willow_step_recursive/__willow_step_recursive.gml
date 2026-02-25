/// @ignore Recursively processes logic and component-specific steps for a box list.
/// @param {Array<Struct.WillowBox>} _boxList The list of boxes to process.
function __willow_step_recursive(_boxList) {
    var _len = array_length(_boxList);
    var _i = 0; repeat(_len) {
        var _box = _boxList[_i];
        if (is_struct(_box)) {
            // Standard box logic (transitions, resizing)
            if (variable_struct_exists(_box, "step")) _box.step();
            
            // Component-specific logic (cursor movement, scroll sync)
            if (variable_struct_exists(_box, "stepComponent")) _box.stepComponent();

            // Recurse into children if they aren't already handled by WillowBox.step
            if (variable_struct_exists(_box, "__children")) {
                __willow_step_recursive(_box.__children);
            }
        }
        _i++;
    }
}