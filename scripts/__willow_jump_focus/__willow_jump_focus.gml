/// @ignore Transfers focus between sibling elements in a container.
/// @param {Struct.WillowBox} _source The currently focused box.
/// @param {Real} _direction 1 for forward (Tab), -1 for backward (Shift+Tab).
function __willow_jump_focus(_source, _direction = 1) {
    var _parent = _source.__parent;
    if (_parent == undefined) return false;
    
    var _siblings = _parent.__children;
    var _count = array_length(_siblings);
    if (_count <= 1) return false;

    var _myIdx = -1;
    var _i = 0; repeat(_count) { 
        if (_siblings[_i] == _source) { _myIdx = _i; break; }
        _i++;
    }

    var _searchIdx = _myIdx;
    repeat(_count - 1) {
        _searchIdx = (_searchIdx + _direction + _count) % _count;
        var _target = _siblings[_searchIdx];

        // We only jump to components that explicitly support focus states.
        if (is_instanceof(_target, WillowTextBox) || is_instanceof(_target, WillowButton)) {

            if (variable_struct_exists(_source, "__inputState")) {
                _source.__inputState.__focus = false;
            }
            _target.__inputState.__focus = true;

            // Update cursor and keyboard string for textboxes
            if (is_instanceof(_target, WillowTextBox)) {
                _target.__inputState.__cursor = string_length(_target.__text);
                keyboard_string = _target.__text;
            }

            keyboard_clear(vk_tab);
            keyboard_clear(vk_up);
            keyboard_clear(vk_down);
            
            return true;
        }
    }
    return false;
}