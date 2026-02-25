/// @func    WillowButton(_label, [_style], [_onClick])
/// @desc    Creates a standard interactive button with text and optional icon support.
/// @param   {String} _label
/// @param   {Struct.WillowStyle} [_style]
/// @param   {Function} [_onClick]
/// @return  {Struct.WillowButton} self
function WillowButton(_label, _style = new WillowStyle(), _onClick = undefined) : WillowBox("Button: " + _label, _style) constructor {
    
    #region INTERNAL VARIABLES
    
    // - STATE & DATA
    __label = _label;
    __isPressed = false;
    __hoverAlpha = 0;
    
    __inputState = {
        __focus: false
    };
    
    // - CHILDREN
    __textElement = undefined;
    __iconElement = undefined;
    
    #endregion
    
    #region INITIALIZATION
    
    // - LAYOUT CONFIGURATION
    var _node = getNode();
    flexpanel_node_style_set_flex_direction(_node, flexpanel_flex_direction.row);
    flexpanel_node_style_set_justify_content(_node, flexpanel_justify.center);
    flexpanel_node_style_set_align_items(_node, flexpanel_align.center);
    flexpanel_node_style_set_gap(_node, flexpanel_gutter.all_gutters, 8);

    // - LABEL SETUP
    __textElement = new WillowText(_label + "_label", _label);
    __textElement.__isHittable = false;

    // Disable flex growth/shrink to ensure text scaling doesn't distort within the container
    var _tnode = __textElement.getNode();
    flexpanel_node_style_set_flex_shrink(_tnode, 0);
    flexpanel_node_style_set_flex_grow(_tnode, 0);
    
    contains([__textElement]);
    
    // - EVENT BINDING
    if (_onClick != undefined && is_method(_onClick)) {
        onClick(_onClick);
    }
    
    #endregion

    #region PUBLIC API
    
    /// @func    setText(_text)
    /// @desc    Safely updates the button's label and forces the child component to update.
    /// @param   {String} _text
    /// @return  {Struct.WillowButton} self
    static setText = function(_text) {
        __label = _text;
        if (__textElement != undefined) {
            if (variable_struct_exists(__textElement, "setText")) {
                __textElement.setText(_text);
            } else {
                __textElement.__text = _text; 
            }
        }
        return self;
    };

    /// @func    setIcon(_sprite, [_scale], [_rot], [_alpha], [_align])
    /// @desc    Injects a WillowSprite icon into the button's layout.
    /// @param   {Asset.GMSprite} _sprite
    /// @param   {Real} [_scale]
    /// @param   {Real} [_rot]
    /// @param   {Real} [_alpha]
    /// @param   {String} [_align]
    /// @return  {Struct.WillowButton} self
    static setIcon = function(_sprite, _scale = 1, _rot = 0, _alpha = 1, _align = "left") {
        var _iconStyle = new WillowStyle()
            .scale(_scale)
            .rotate(_rot)
            .alpha(_alpha);

        __iconElement = new WillowSprite("Icon", _sprite, _iconStyle);
        __iconElement.__isHittable = false;
        
        if (_align == "left") contains([__iconElement, __textElement]);
        else contains([__textElement, __iconElement]);
        
        return self;
    };
    
    #endregion
    
    #region SYSTEM HOOKS
    
    /// @ignore
    static __applyTheme = function(_theme) {
        __render.colours = __willow_ensure_colour_array(_theme.color.primary);
        __render.rounding = _theme.radius.btn;
        __render.outline_colour = _theme.color.primary;
        __render.outline_alpha = 0.6;

        if (__textElement != undefined) {
            __textElement.__render.text_colour = _theme.color.primary_content;
        }
    };
    
    /// @ignore
    static stepComponent = function() {
        __maxScrollX = 0; __maxScrollY = 0; __scrollX = 0; __scrollY = 0;

        if (__isResizing) return;
        
        var _isHovered = __eventState.hover;
        
        // - FOCUS MANAGEMENT
        if (device_mouse_check_button_pressed(0, mb_left)) {
            __inputState.__focus = false;
        }

        if (__inputState.__focus) {
            if (keyboard_check_pressed(vk_tab)) {
                __willow_jump_focus(self, keyboard_check(vk_shift) ? -1 : 1);
                return;
            }
            if (keyboard_check_pressed(vk_up)) {
                __willow_jump_focus(self, -1);
                return;
            }
            if (keyboard_check_pressed(vk_down)) {
                __willow_jump_focus(self, 1);
                return;
            }
            
            if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
                __handleEvent(WILLOW_EVENT.click);
            }
        }

        // - TACTILE FEEDBACK
        var _kbPressed = __inputState.__focus && (keyboard_check(vk_enter) || keyboard_check(vk_space));
        __isPressed = (_isHovered && mouse_check_button(mb_left)) || _kbPressed;
        var _pressVal = __isPressed ? 1 : 0;

        if (__textElement != undefined) {
            __textElement.__render.offsetY = _pressVal;
            __textElement.__render.offsetX = _pressVal;
            __textElement.__render.alpha[0] = __render.alpha[0];
        }
        
        if (__iconElement != undefined) {
            __iconElement.__render.offsetY = _pressVal;
            __iconElement.__render.offsetX = _pressVal;
            __iconElement.__render.alpha[0] = __render.alpha[0];
        }
        
        var _theme = __WillowSystem().theme;
        var _targetScale = __isPressed ? (variable_struct_exists(_theme.anim, "focus_scale") ? _theme.anim.focus_scale : 0.95) : 1.0;
        
        __render.scaleX = lerp(__render.scaleX, _targetScale, 0.3);
        __render.scaleY = lerp(__render.scaleY, _targetScale, 0.3);
        
        var _targetAlpha = _isHovered ? (variable_struct_exists(_theme.anim, "hover_alpha") ? _theme.anim.hover_alpha : 0.1) : 0;
        __hoverAlpha = lerp(__hoverAlpha, _targetAlpha, 0.2);
    };
    
    /// @ignore OVERRIDE: Handle visual overlays before masking children.
    static drawText = function() {
        var _dx = round(getDrawX());
        var _dy = round(getDrawY());
        var _sz = __getRenderSize();
        var _szW = round(_sz.w);
        var _szH = round(_sz.h);
        
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);
        
        // - RENDER FOCUS RING
        if (__inputState.__focus) {
            var _focusGap = 1;
            var _focusThick = 2;
            var _oc = variable_struct_exists(__render, "outline_colour") ? __render.outline_colour : __WillowSystem().theme.color.primary;
            var _oa = __render.alpha[0] * (variable_struct_exists(__render, "outline_alpha") ? __render.outline_alpha : 0.6);
            
            __willow_draw_focus_ring(_dx, _dy, _szW, _szH, __render.rounding, _focusThick, _focusGap, _oc, _oa);
        }

        // - RENDER HOVER HIGHLIGHT
        if (__hoverAlpha > 0) {
            var _c = c_black; 
            draw_set_alpha(__hoverAlpha * __render.alpha[0]);
            
            if (__WillowSystem().use_clean_shapes) {
                CleanRectangle(_dx, _dy, _dx + _szW, _dy + _szH)
                    .Rounding(__render.rounding)
                    .Blend(_c, draw_get_alpha())
                    .Draw();
            } else {
                draw_set_colour(_c);
                if (__render.rounding > 0) draw_roundrect_ext(_dx, _dy, _dx + _szW - 1, _dy + _szH - 1, __render.rounding, __render.rounding, false);
                else draw_rectangle(_dx, _dy, _dx + _szW - 1, _dy + _szH - 1, false);
            }
            
            draw_set_alpha(1);
        }
        
        // - CASCADE CHILDREN (Apply Mask natively for internal labels/icons)
        var _numChildren = array_length(__children);
        var _needsClip = (__maxScrollX > 0 || __maxScrollY > 0 || (variable_struct_exists(__styleDefinition.struct, "clipContent") && __styleDefinition.struct.clipContent));
        var _prevMask = 0;
        var _clipInset = 2; 
        
        if (_needsClip && _numChildren > 0) {
            _prevMask = __willow_mask_push(
                _dx + _clipInset, 
                _dy + _clipInset, 
                max(0, _szW - (_clipInset * 2)), 
                max(0, _szH - (_clipInset * 2)), 
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
                _dx + _clipInset, 
                _dy + _clipInset, 
                max(0, _szW - (_clipInset * 2)), 
                max(0, _szH - (_clipInset * 2)), 
                max(0, __render.rounding - _clipInset), 
                _prevMask
            );
            if (_matrixPushed) __willow_matrix_restore_transform();
        }
    };
    
    #endregion
}