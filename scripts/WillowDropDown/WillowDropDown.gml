/// @func    WillowDropDown(_name, _items, _boxStyle, _itemStyle, [_itemHoverStyle])
/// @desc    A standalone Dropdown Menu component used for context menus or file menus.
/// @param   {String} _name Unique identifier.
/// @param   {Array<Struct>} _items Array of {label, callback} structs.
/// @param   {Struct.WillowStyle} _boxStyle Style for the dropdown container.
/// @param   {Struct.WillowStyle} _itemStyle Base style for individual menu items.
/// @param   {Struct.WillowStyle} [_itemHoverStyle] Style applied when an item is hovered.
/// @return  {Struct.WillowDropDown}
function WillowDropDown(_name, _items, _boxStyle, _itemStyle, _itemHoverStyle = new WillowStyle()) : WillowBox(_name, _boxStyle) constructor {
    
    #region INTERNAL VARIABLES
    __items = _items;
    __itemStyle = _itemStyle;
    __itemHoverStyle = _itemHoverStyle;
    
    __isOpen = false;
    __framesAlive = 0;
    #endregion

    #region INITIALIZATION
    // 1. Configure Layout Behavior
    var _node = getNode();
    flexpanel_node_style_set_flex_direction(_node, flexpanel_flex_direction.column);
    flexpanel_node_style_set_flex_wrap(_node, flexpanel_wrap.no_wrap);
    flexpanel_node_style_set_position_type(_node, flexpanel_position_type.absolute);
    
    // 2. Set as Overlay
    alwaysOnTop();
    #endregion

    #region PUBLIC METHODS
    /// @func    buildItems()
    /// @desc    Constructs the internal button hierarchy based on the provided item list.
    /// @return  {Struct.WillowDropDown} Self
    static buildItems = function() {
        var _buttons = [];
        var _len = array_length(__items);
        
        for (var i = 0; i < _len; i++) {
            var _item = __items[i];
            
            // Create item as a Button component
            var _btn = new WillowButton(_item.label, __itemStyle.clone());
            
            // Apply Hover States if provided
            if (__itemHoverStyle != undefined) {
                // Note: Assumes WillowButton/Box supports onEnter/onLeave transition blocks
                if (variable_struct_exists(_btn, "onEnter")) {
                    _btn.onEnter(__itemHoverStyle);
                    _btn.onLeave(__itemStyle);
                }
            }
            
            // Inject dropdown-specific logic into button
            _btn.__dropdownAction = variable_struct_exists(_item, "callback") ? _item.callback : undefined;
            _btn.__dropdownParent = self;
            
            _btn.onClick(function(_callerBtn) {
                if (is_callable(_callerBtn.__dropdownAction)) _callerBtn.__dropdownAction();
                _callerBtn.__dropdownParent.close();
            });
            
            array_push(_buttons, _btn);
        }
        
        contains(_buttons);
        
        // Force immediate layout reflow
        var _trunk = self;
        while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
        flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
        _trunk.updatePosition(true);
        
        return self;
    };

    /// @func    open([_x], [_y])
    /// @desc    Displays the dropdown at the specified coordinates and enables interaction.
    /// @param   {Real} [_x] Optional X coordinate.
    /// @param   {Real} [_y] Optional Y coordinate.
    /// @return  {Struct.WillowDropDown} Self
    static open = function(_x = undefined, _y = undefined) {
        __isOpen = true;
        __isHittable = true;
        __framesAlive = 0;
        
        flexpanel_node_style_set_display(__node, flexpanel_display.flex);
        
        if (_x != undefined && _y != undefined) {
            flexpanel_node_style_set_position(__node, flexpanel_edge.left, _x, flexpanel_unit.point);
            flexpanel_node_style_set_position(__node, flexpanel_edge.top, _y, flexpanel_unit.point);
            
            // Refresh layout to resolve initial width/height for clamping
            var _trunk = self;
            while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
            flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
            updatePosition(true);
            
            // Screen Clamping
            var _safeX = clamp(_x, 0, max(0, window_get_width() - __layout.width));
            var _safeY = clamp(_y, 0, max(0, window_get_height() - __layout.height));
            
            flexpanel_node_style_set_position(__node, flexpanel_edge.left, _safeX, flexpanel_unit.point);
            flexpanel_node_style_set_position(__node, flexpanel_edge.top, _safeY, flexpanel_unit.point);
            
            flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
            _trunk.updatePosition(true);
        }
        
        return self;
    };

    /// @func    close()
    /// @desc    Hides the dropdown and disables interaction.
    /// @return  {Struct.WillowDropDown} Self
    static close = function() {
        __isOpen = false;
        __isHittable = false;
        
        flexpanel_node_style_set_display(__node, flexpanel_display.none);
        
        if (__parent != undefined) {
            var _trunk = self;
            while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
            flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
            _trunk.updatePosition(true);
        }
        
        return self;
    };
    #endregion

    #region CORE LOOP OVERRIDES
    /// @ignore Handle "click outside" logic to close menu.
    static step = function() {
        if (!__isOpen) return;
        
        // Ensure dropdown stays at overlay depth
        __render.depth = WILLOW_OVERLAY_DEPTH;
        
        // Execute standard Box step logic (animations, events)
        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child)) {
                if (variable_struct_exists(_child, "step")) _child.step();
            }
            _i++;
        }
        
        __framesAlive++;
        
        // Close if clicking outside bounds
        if (__framesAlive > 2 && (device_mouse_check_button_pressed(0, mb_left) || device_mouse_check_button_pressed(0, mb_right))) {
            var _mx = window_mouse_get_x();
            var _my = window_mouse_get_y();
            var _inBounds = point_in_rectangle(_mx, _my, __layout.left, __layout.top, __layout.left + __layout.width, __layout.top + __layout.height);
            
            if (!_inBounds) close();
        }
    };

    /// @ignore Gate rendering based on open state.
    static draw = function(_batched = false) {
        if (!__isOpen) return;

        // Standard WillowBox Draw logic
        var _depthPrev = gpu_get_depth();
        gpu_set_depth(__render.depth);
        
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);
        
        var _dx = getDrawX();
        var _dy = getDrawY();
        
        if (__WillowSystem().use_clean_shapes) __willow_draw_rectangle_cleanshapes(_dx, _dy, __render.width, __render.height, __render);
        else __willow_draw_rectangle_Native(_dx, _dy, __render.width, __render.height, __render);

        if (_matrixPushed) __willow_matrix_restore_transform();
        gpu_set_depth(_depthPrev);

        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child)) _child.draw(_batched);
            _i++;
        }
    };
    #endregion
    
    // Auto-build and initialize in a closed state
    buildItems();
    close();
}