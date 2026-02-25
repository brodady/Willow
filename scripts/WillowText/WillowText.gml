/// @func    WillowText(_name, _text, [_style])
/// @desc    A dedicated text component supporting labels, selectability, and Scribble effects.
/// @param   {String} _name
/// @param   {String} _text
/// @param   {Struct.WillowStyle} [_style]
/// @return  {Struct.WillowText} self
function WillowText(_name, _text, _style = new WillowStyle()) : WillowBox(_name, _style) constructor {
    
    #region INTERNAL VARIABLES
    
    __text = _text;
    __isSelectable = false;
    __autoWrap = false;
    __typist = undefined;

    __selectState = {
        __focus: false,
        __isDragging: false,
        __cursor: 0,
        __anchor: -1
    };
    
    #endregion
    
    #region PUBLIC API
    
    /// @func    setText(_text)
    /// @desc    Updates the text content and flags the layout for recalculation.
    /// @param   {String} _text
    /// @return  {Struct.WillowText} self
    static setText = function(_text) {
        var _newText = string(_text);
        if (__text == _newText) return self;
        
        __text = _newText;
        __updateNodeSize();            
        
        return self;
    };

    /// @func    setSelectable([_enable])
    /// @desc    Toggles whether the user can highlight and copy the text.
    /// @param   {Bool} [_enable]
    /// @return  {Struct.WillowText} self
    static setSelectable = function(_enable = true) {
        __isSelectable = _enable;
        if (!_enable) {
            __selectState.__focus = false;
            __selectState.__isDragging = false;
            __selectState.__anchor = -1;
        }
        return self;
    };
    
    /// @func    setAutoWrap([_enable])
    /// @desc    Toggles automatic line wrapping based on the component's flex bounds.
    /// @param   {Bool} [_enable]
    /// @return  {Struct.WillowText} self
    static setAutoWrap = function(_enable = true) {
        if (__autoWrap == _enable) return self;
        
        __autoWrap = _enable;
        __updateNodeSize();
        
        return self;
    };
    
    /// @func    setTypist(_typist)
    /// @desc    Assigns a Scribble Typist object for typewriter effects.
    /// @param   {Struct} _typist
    /// @return  {Struct.WillowText} self
    static setTypist = function(_typist) {
        __typist = _typist;
        return self;
    };

    /// @func    getContentWidth()
    /// @desc    Calculates the intrinsic width using native GML string functions for stability.
    /// @return  {Real}
    static getContentWidth = function() {
        var _sys = __WillowSystem();
        draw_set_font(__render[$ "text_font"] ?? _sys.default_font);
        var _clean = __getStrippedText(__text);
        
        if (__autoWrap && __layout != undefined && __layout.width > 0) return string_width_ext(_clean, -1, __layout.width);
        return string_width(_clean);
    };

    /// @func    getContentHeight()
    /// @desc    Calculates the intrinsic height using native GML string functions for stability.
    /// @return  {Real}
    static getContentHeight = function() {
        var _sys = __WillowSystem();
        draw_set_font(__render[$ "text_font"] ?? _sys.default_font);
        var _clean = __getStrippedText(__text);
        
        if (__autoWrap && __layout != undefined && __layout.width > 0) return string_height_ext(_clean, -1, __layout.width);
        return string_height(_clean);
    };
    
    #endregion

    #region PRIVATE SYSTEM HOOKS
    
    /// @ignore
    static __updateNodeSize = function() {
        var _flex = __styleDefinition.toFlexStruct();
        var _needsReflow = false;
        
        if (_flex.width == "auto") {
            flexpanel_node_style_set_width(__node, getContentWidth(), flexpanel_unit.point);
            _needsReflow = true;
        }
        if (_flex.height == "auto") {
            flexpanel_node_style_set_height(__node, getContentHeight(), flexpanel_unit.point);
            _needsReflow = true;
        }
        
        if (_needsReflow) {
            var _trunk = self; 
            while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
            
            if (_trunk != undefined && variable_struct_exists(_trunk, "getNode")) {
                flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), flexpanel_direction.LTR);
                _trunk.updatePosition(true);
            }
        }
    };

    /// @ignore 
    static __getStrippedText = function(_str) {
        if (!__WillowSystem().use_scribble) return _str;
        
        var _res = ""; 
        var _inTag = false; 
        var _len = string_length(_str);
        var _i = 1; 
        
        while (_i <= _len) {
            var _c = string_char_at(_str, _i);
            
            if (_c == "[") {
                if (_i < _len && string_char_at(_str, _i + 1) == "[") { 
                    _res += "["; 
                    _i += 2; 
                    continue; 
                }
                _inTag = true; 
                _i++;
                continue;
            }
            
            if (_c == "]" && _inTag) { 
                _inTag = false; 
                _i++;
                continue; 
            }
            
            if (!_inTag) _res += _c;
            _i++;
        }
        
        return _res;
    };

    /// @ignore 
    static __getCharIndexAtMouse = function() {
        var _drawX = getDrawX();
        var _clean = __getStrippedText(__text);
        var _sys = __WillowSystem();
        
        draw_set_font(__render[$ "text_font"] ?? _sys.default_font);
        
        var _totalW = getContentWidth() * __render.scaleX; 
        var _startX = _drawX;
        
        if (__render.textAlignH == fa_center) _startX += (__layout.width * 0.5) - (_totalW * 0.5);
        else if (__render.textAlignH == fa_right) _startX += __layout.width - _totalW;
        
        var _relX = window_mouse_get_x() - _startX;
        if (_relX <= 0) return 0;
        
        var _len = string_length(_clean);
        
        var _i = 1; repeat(_len) {
            var _sub = string_copy(_clean, 1, _i);
            var _w = string_width(_sub) * __render.scaleX;
            var _prevW = string_width(string_copy(_clean, 1, _i - 1)) * __render.scaleX;
            var _midpoint = _prevW + ((_w - _prevW) / 2);
            if (_relX < _midpoint) return _i - 1;
            _i++;
        }
        
        return _len;
    };
    
    #endregion

    #region CORE LOOP HOOKS
    
    /// @ignore
    static __applyTheme = function(_theme) {
        // Flimsy, but it works for now
        var _isManaged = (__parent != undefined && variable_struct_exists(__parent, "__textElement") && __parent.__textElement == self);
        
        // Only apply base formatting if a wrapper component (like a Button) isn't directly controlling style
        if (!_isManaged) {
            __render.text_colour = _theme.color.base_content;
        }
        
        __render.select_colour = _theme.color.primary;
        __render.select_alpha = 0.4;
    };

    /// @ignore
    static stepComponent = function() {
        if (!__isSelectable) return;

        if (device_mouse_check_button_pressed(0, mb_left) && !__eventState.hover) {
            __selectState.__focus = false;
            __selectState.__isDragging = false;
        }

        if (!device_mouse_check_button(0, mb_left)) __selectState.__isDragging = false;
        if (__selectState.__isDragging) __selectState.__cursor = __getCharIndexAtMouse();

        if (__selectState.__focus && keyboard_check(vk_control)) {
            var _clean = __getStrippedText(__text);
            
            if (keyboard_check_pressed(ord("A"))) {
                __selectState.__anchor = 0;
                __selectState.__cursor = string_length(_clean);
            }
            
            if (keyboard_check_pressed(ord("C")) && __selectState.__anchor != -1 && __selectState.__anchor != __selectState.__cursor) {
                var _m1 = min(__selectState.__cursor, __selectState.__anchor);
                var _m2 = max(__selectState.__cursor, __selectState.__anchor);
                clipboard_set_text(string_copy(_clean, _m1 + 1, _m2 - _m1));
            }
        }
    };
    
    /// @ignore OVERRIDE: Suppress background panel draw while maintaining structural depth
    static draw = function(_batched = false) {
        if (__render.scaleX == 0 || __render.scaleY == 0) return;

        var _depthPrev = gpu_get_depth();
        gpu_set_depth(__render.depth);
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);

        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child) && !_child.__isOverlay) {
                _child.draw(_batched);
            }
            _i++;
        }
        
        if (_matrixPushed) __willow_matrix_restore_transform();
        gpu_set_depth(_depthPrev);
    };

    /// @ignore
    static drawText = function() {
        if (__layout.width <= 0) return;

        var _sys = __WillowSystem();
        var _dx = getDrawX();
        var _dy = getDrawY();
        var _halign = __render.textAlignH;
        var _valign = __render.textAlignV;
        
        var _xx = _dx;
        var _yy = _dy;
        
        if (_halign == fa_center) _xx += __layout.width * 0.5;
        else if (_halign == fa_right) _xx += __layout.width;
        
        if (_valign == fa_middle) _yy += __layout.height * 0.5;
        else if (_valign == fa_bottom) _yy += __layout.height;

        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);

        var _font = __render[$ "text_font"] ?? _sys.default_font;
        var _colour = __render.text_colour;
        var _alpha = (__render[$ "text_alpha"] ?? 1) * __render.alpha[0];
        
        var _clean = __getStrippedText(__text);

        // - SELECTION
        var _hasSel = (__isSelectable && __selectState.__focus && __selectState.__anchor != -1 && __selectState.__anchor != __selectState.__cursor);
        
        if (_hasSel) {
            draw_set_font(_font);
            var _minS = min(__selectState.__cursor, __selectState.__anchor);
            var _maxS = max(__selectState.__cursor, __selectState.__anchor);
            
            var _totalW = string_width(_clean);
            var _startX = _dx;
            if (_halign == fa_center) _startX += (__layout.width * 0.5) - (_totalW * 0.5);
            else if (_halign == fa_right) _startX += __layout.width - _totalW;
            
            var _preW = string_width(string_copy(_clean, 1, _minS));
            var _selW = string_width(string_copy(_clean, _minS + 1, _maxS - _minS));
            
            var _selY = _yy;
            var _lineH = string_height("A");
            if (_valign == fa_middle) _selY -= _lineH * 0.5;
            else if (_valign == fa_bottom) _selY -= _lineH;

            var _selCol = __render[$ "select_colour"] ?? c_teal;
            var _selAlpha = (__render[$ "select_alpha"] ?? 0.4) * _alpha;
            
            var _highlightRender = { 
                colours: [_selCol, _selCol, _selCol, _selCol], 
                alpha: [_selAlpha, _selAlpha, _selAlpha, _selAlpha], 
                borderColours: [c_white, c_white, c_white, c_white], 
                borderAlpha: [0, 0, 0, 0], 
                borderWidth: 0, 
                rounding: 0 
            };
            
            if (_sys.use_clean_shapes) {
                __willow_draw_rectangle_cleanshapes(_startX + _preW, _selY, _selW, _lineH, _highlightRender);
            } else {
                __willow_draw_rectangle_native(_startX + _preW, _selY, _selW, _lineH, _highlightRender);
            }
        }

        // - TEXT RENDERING
        if (_sys.use_scribble) {
            var _fontName = is_string(_font) ? _font : font_get_name(_font);
            var _el = scribble(__text)
                .starting_format(_fontName, _colour)
                .align(_halign, _valign)
                .blend(_colour, _alpha);

            if (__autoWrap) _el.wrap(__layout.width);

            if (__typist != undefined) _el.draw(_xx, _yy, __typist);
            else _el.draw(_xx, _yy);

        } else {
            draw_set_font(_font);
            draw_set_halign(_halign);
            draw_set_valign(_valign);
            draw_set_alpha(_alpha);

            if (__autoWrap) draw_text_ext_color(_xx, _yy, _clean, -1, __layout.width, _colour, _colour, _colour, _colour, _alpha);
            else draw_text_color(_xx, _yy, _clean, _colour, _colour, _colour, _colour, _alpha);
        }
        
        if (_matrixPushed) __willow_matrix_restore_transform();
        draw_set_alpha(1);
    };
    
    #endregion
    
    #region EVENT BINDINGS
    
    onClick(function() {
        if (!__isSelectable) return;
        
        __selectState.__focus = true;
        __selectState.__isDragging = true;
        
        var _idx = __getCharIndexAtMouse();
        
        if (keyboard_check(vk_shift)) {
            if (__selectState.__anchor == -1) __selectState.__anchor = __selectState.__cursor;
            __selectState.__cursor = _idx;
        } else {
            __selectState.__cursor = _idx;
            __selectState.__anchor = _idx;
        }
    });

    onDoubleClick(function() {
        if (!__isSelectable || __text == "") return;
        
        var _clean = __getStrippedText(__text);
        var _idx = __getCharIndexAtMouse();
        
        var _start = _idx;
        while (_start > 0 && !__willow_is_boundary(string_char_at(_clean, _start))) _start--;
        
        var _end = _idx + 1;
        var _len = string_length(_clean);
        while (_end <= _len && !__willow_is_boundary(string_char_at(_clean, _end))) _end++;
        
        __selectState.__focus = true;
        __selectState.__anchor = _start;
        __selectState.__cursor = _end - 1;
    });
    
    #endregion

    // - INITIALIZATION
    __updateNodeSize();
}