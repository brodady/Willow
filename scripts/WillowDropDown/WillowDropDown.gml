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
    flexpanel_node_style_set_align_self(_node, flexpanel_align.flex_start);
    
    // 2. Set as Overlay
    alwaysOnTop();
    #endregion

    #region PUBLIC METHODS
    /// @func    buildItems()
    /// @desc    Constructs the internal button hierarchy based on the provided item list.
    /// @return  {Struct.WillowDropDown} Self
    static buildItems = function() {
        __children = [];
        flexpanel_node_remove_all_children(__node);
        
        var _buttons = [];
        var _len = array_length(__items);
        
        // Accumulator to lock the height of the dropdown
        var _targetHeight = 0;
        
        for (var i = 0; i < _len; i++) {
            var _item = __items[i];
            var _btn = new WillowButton(_item.label, __itemStyle.clone());
            
            if (variable_struct_exists(_item, "icon") && _item.icon != undefined) {
                _btn.setIcon(_item.icon, 0.5, 0, 0.5, "right");
            }
            
            if (__itemHoverStyle != undefined && variable_struct_exists(_btn, "onEnter")) {
                _btn.onEnter(__itemHoverStyle);
                _btn.onLeave(__itemStyle);
            }
            
            _btn.__dropdownAction = variable_struct_exists(_item, "callback") ? _item.callback : undefined;
            _btn.__dropdownParent = self;
            
            _btn.onClick(function(_callerBtn) {
                if (is_callable(_callerBtn.__dropdownAction)) _callerBtn.__dropdownAction();
                _callerBtn.__dropdownParent.close();
            });
            
            array_push(_buttons, _btn);
            
            if (variable_struct_exists(__itemStyle.struct, "height") && is_numeric(__itemStyle.struct.height)) {
                _targetHeight += __itemStyle.struct.height;
            } else {
                _targetHeight += 40; 
            }
        }
        
        contains(_buttons);
        
        var _padTop = variable_struct_exists(__styleDefinition.struct, "paddingTop") ? __styleDefinition.struct.paddingTop : 0;
        var _padBot = variable_struct_exists(__styleDefinition.struct, "paddingBottom") ? __styleDefinition.struct.paddingBottom : 0;
        
        flexpanel_node_style_set_height(__node, _targetHeight + _padTop + _padBot, flexpanel_unit.point);
        
        if (__parent != undefined) {
            var _trunk = self;
            while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
            flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
            _trunk.updatePosition(true);
        }
        
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
            
            var _trunk = self;
            while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
            
            // FIX: Must call updatePosition on the trunk so the global screen_wrapper bounds sync
            flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
            _trunk.updatePosition(true);
            
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
        
        __render.depth = WILLOW_OVERLAY_DEPTH;
        
        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child)) {
                if (variable_struct_exists(_child, "step")) _child.step();
                
                // FIX: Ensure children actually process interaction logic!
                if (variable_struct_exists(_child, "stepComponent")) _child.stepComponent();
            }
            _i++;
        }
        
        __framesAlive++;
        
        if (__framesAlive > 2 && (device_mouse_check_button_pressed(0, mb_left) || device_mouse_check_button_pressed(0, mb_right))) {
            var _mx = window_mouse_get_x();
            var _my = window_mouse_get_y();
            var _inBounds = point_in_rectangle(_mx, _my, __layout.left, __layout.top, __layout.left + __layout.width, __layout.top + __layout.height);
            
            if (!_inBounds) close();
        }
    };

    static draw = function(_batched = false) {
        if (!__isOpen) return;

        var _depthPrev = gpu_get_depth();
        gpu_set_depth(__render.depth);
        
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);
        
        var _dx = getDrawX();
        var _dy = getDrawY();
        var _sz = __getRenderSize(); // Safer than raw __render.width fetches
        
        // FIX: native is strictly lowercase in GameMaker!
        if (__WillowSystem().use_clean_shapes) __willow_draw_rectangle_cleanshapes(_dx, _dy, _sz.w, _sz.h, __render);
        else __willow_draw_rectangle_native(_dx, _dy, _sz.w, _sz.h, __render);

        if (_matrixPushed) __willow_matrix_restore_transform();
        gpu_set_depth(_depthPrev);

        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child)) _child.draw(_batched);
            _i++;
        }
    };
    
    // FIX: You MUST override drawText so closed dropdowns don't push invisible 0x0 stencil masks!
    static drawText = function() {
        if (!__isOpen) return;
        
        __layout = flexpanel_node_layout_get_position(__node, false); 
        var _numChildren = array_length(__children);
        var _depthPrev = gpu_get_depth();
        
        gpu_set_depth(__render.depth); 

        var _drawX = getDrawX();
        var _drawY = getDrawY();

        __willow_draw_scrollbars(self);
        __willow_draw_resize_handle(self);

        gpu_set_depth(_depthPrev);

        var _needsClip = (__maxScrollX > 0 || __maxScrollY > 0 || (variable_struct_exists(__styleDefinition.struct, "clipContent") && __styleDefinition.struct.clipContent));
        var _prevMask = 0;
        var _clipInset = 2; 
        
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);
        
        if (_needsClip && _numChildren > 0) {
            var _sz = __getRenderSize();
            _prevMask = __willow_mask_push(
                _drawX + _clipInset, 
                _drawY + _clipInset, 
                max(0, _sz.w - (_clipInset * 2)), 
                max(0, _sz.h - (_clipInset * 2)), 
                max(0, __render.rounding - _clipInset)
            );
        }
        
        if (_matrixPushed) __willow_matrix_restore_transform();

        if (_numChildren > 0) {
            var _i = 0; repeat(_numChildren) {
                 var _childBox = __children[_i];
                if (is_struct(_childBox)) {
                    if (!(variable_struct_exists(_childBox, "__isOverlay") && _childBox.__isOverlay)) {
                        if (variable_struct_exists(_childBox, "drawText")) _childBox.drawText();
                    }
                }
                _i++;
            }
        }
        
        if (_needsClip && _numChildren > 0) {
            if (_matrixPushed) __willow_matrix_apply_transform(__render, __layout);
            __willow_mask_pop(
                _drawX + _clipInset, 
                _drawY + _clipInset, 
                max(0, _sz.w - (_clipInset * 2)), 
                max(0, _sz.h - (_clipInset * 2)), 
                max(0, __render.rounding - _clipInset), 
                _prevMask
            );
            if (_matrixPushed) __willow_matrix_restore_transform();
        }
    };
    #endregion
    
    buildItems();
    close();
}