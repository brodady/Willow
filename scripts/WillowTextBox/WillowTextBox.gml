/// @func    WillowTextBox(_name, [_placeholder], [_style])
/// @desc    Creates a new text input box with unified cursor and selection logic.
/// @param   {String} _name
/// @param   {String} [_placeholder]
/// @param   {Struct.WillowStyle} [_style]
/// @return  {Struct.WillowTextBox} self
function WillowTextBox(_name, _placeholder = "Enter text...", _style = new WillowStyle()) : WillowBox(_name, _style) constructor {

    #region INTERNAL VARIABLES
    
    // - STATE & DATA
    __text = "";
    __placeholder = _placeholder;
    __replacementChar = "";
    __prefixText = "";
    __suffixText = "";
    __isMultiline = false;
    __submitOnEnter = true;
    __wordWrap = true;

    // - RENDERING CACHE
    __lastText = "";
    __lastWidth = 0;
    __cachedLines = [];
    __lineHeight = 20;
    __cursorStyle = cr_beam; 

    // - INTERACTION STATE
    __inputState = {
        __focus: false,
        __isDragging: false,
        __cursor: 0,
        __selectStart: -1,
        __selectMode: WILLOW_SELECT_MODE.REGULAR,
        __maxLength: infinity,
        __blinkTimer: 0,
        __blinkRate: 45,
        __navTimer: 0 
    };
    
    #endregion

    #region PUBLIC API
    
    /// @func    setReplacementChar(_char)
    /// @desc    Sets a masking character (e.g., "*") for password fields.
    /// @param   {String} _char
    /// @return  {Struct.WillowTextBox} self
    static setReplacementChar = function(_char) { 
        __replacementChar = string_char_at(_char, 1); 
        return self; 
    };
    
    /// @func    setMultiline(_enable, [_submitOnEnter])
    /// @desc    Configures multi-line support and enter-key behavior.
    /// @param   {Bool} _enable
    /// @param   {Bool} [_submitOnEnter]
    /// @return  {Struct.WillowTextBox} self
    static setMultiline = function(_enable, _submitOnEnter = false) { 
        __isMultiline = _enable; 
        __submitOnEnter = _submitOnEnter; 
        return self; 
    };
    
    /// @func    setPrefix(_text)
    /// @desc    Sets uneditable text rendered before the input (e.g., "https://").
    /// @param   {String} _text
    /// @return  {Struct.WillowTextBox} self
    static setPrefix = function(_text) { 
        __prefixText = string(_text); 
        return self; 
    };
    
    /// @func    setSuffix(_text)
    /// @desc    Sets uneditable text rendered after the input.
    /// @param   {String} _text
    /// @return  {Struct.WillowTextBox} self
    static setSuffix = function(_text) { 
        __suffixText = string(_text); 
        return self; 
    };
    
    #endregion

    #region PRIVATE SYSTEM HOOKS
    
    /// @ignore
    static __applyTheme = function(_theme) {
        __render.colours = __willow_ensure_colour_array(_theme.color.base_200);
        __render.rounding = _theme.radius.field;
        __render.outline_colour = _theme.color.primary;
        __render.outline_alpha  = 0.6;
        __render.select_colour  = _theme.color.primary;
        __render.select_alpha   = 0.4;
        
        if (!variable_struct_exists(__render, "text_colour")) __render.text_colour = _theme.color.base_content;
    };

    /// @ignore
    static __getTextWidth = function(_str) {
        _str = string_replace_all(_str, "\r", ""); 
        if (!__isMultiline) _str = string_replace_all(_str, "\n", "");
        
        var _sys = __WillowSystem();
        var _font = __render[$ "text_font"] ?? _sys.default_font;
        
        if (_sys.use_scribble) {
            var _safe = string_replace_all(_str, "[", "[[");
            var _fontName = is_string(_font) ? _font : font_get_name(_font);
            return scribble(_safe).starting_format(_fontName, c_white).get_width();
        } else {
            var _fidx = is_string(_font) ? asset_get_index(_font) : _font;
            if (font_exists(_fidx)) draw_set_font(_fidx);
            return string_width(_str);
        }
    };

    /// @ignore
    static __getPrefixOffset = function() {
        if (__prefixText == "") return 0;
        return __getTextWidth(__prefixText) * 0.8 + 4;
    };

    /// @ignore Evaluates coordinates against viewport bounds to scroll appropriately
    static __scrollToCursor = function() {
        var _coords = __willow_textbox_get_cursor_coords(self, __inputState.__cursor);
        var _maxW = max(10, __layout.width - 16);
        var _maxH = max(10, __layout.height - 16);

        if (_coords.x - __scrollX > _maxW) __scrollX = _coords.x - _maxW;
        else if (_coords.x - __scrollX < 0) __scrollX = max(0, _coords.x);
        
        if (__isMultiline) {
            if (_coords.y - __scrollY > _maxH - __lineHeight) __scrollY = _coords.y - (_maxH - __lineHeight);
            else if (_coords.y - __scrollY < 0) __scrollY = max(0, _coords.y);
        }

        __scrollX = clamp(__scrollX, 0, max(0, __maxScrollX));
        __scrollY = clamp(__scrollY, 0, max(0, __maxScrollY));
    };

    /// @ignore
    static __getCursorIndexFromMouse = function() {
        var _roundingOffset = variable_struct_exists(__render, "rounding") ? max(10, __render.rounding * 0.5) : 10;
        var _drawX = getDrawX() + _roundingOffset;
        var _drawY = getDrawY() + (__isMultiline ? _roundingOffset : (__layout.height / 2) - (__lineHeight / 2));
        var _mx = window_mouse_get_x(); 
        var _my = window_mouse_get_y();
        
        __willow_update_textbox_cache(self);
        
        var _relY = _my - (_drawY - __scrollY);
        var _lineIdx = __isMultiline ? clamp(floor(_relY / __lineHeight), 0, array_length(__cachedLines) - 1) : 0;
        
        if (array_length(__cachedLines) == 0) return 0;
        var _l = __cachedLines[_lineIdx];
        
        _mx = clamp(_mx, getDrawX(), getDrawX() + __layout.width);
        var _relX = _mx - (_drawX - __scrollX + __getPrefixOffset());
        
        if (_relX <= 0) return _l.start_idx - 1;
        
        var _len = string_length(_l.text);
        var _maskedText = __willow_textbox_get_masked_str(self, _l.text);
        
        var _i = 1; repeat(_len) {
            var _charW = __getTextWidth(string_copy(_maskedText, 1, _i));
            var _prevW = __getTextWidth(string_copy(_maskedText, 1, _i - 1));
            var _midpoint = _prevW + ((_charW - _prevW) / 2);
            if (_relX < _midpoint) return _l.start_idx - 1 + (_i - 1);
            _i++;
        }
        return _l.has_newline ? (_l.end_idx - 1) : _l.end_idx;
    };

    /// @ignore
    static __getIndexFromXCoord = function(_targetX, _lineData) {
        var _masked = __willow_textbox_get_masked_str(self, _lineData.text);
        var _len = string_length(_masked);
        
        if (_targetX <= 0) return _lineData.start_idx - 1;
        
        var _i = 1; repeat(_len) {
            var _charW = __getTextWidth(string_copy(_masked, 1, _i));
            var _prevW = __getTextWidth(string_copy(_masked, 1, _i - 1));
            var _midpoint = _prevW + ((_charW - _prevW) / 2);
            if (_targetX < _midpoint) return _lineData.start_idx - 1 + (_i - 1);
            _i++;
        }
        return _lineData.has_newline ? (_lineData.end_idx - 1) : _lineData.end_idx;
    };
    
    #endregion

    #region CORE LOOP HOOKS
    
    static stepComponent = function() {
        __willow_update_textbox_cache(self);

        // - SCROLL BOUNDARIES
        __maxScrollY = max(0, (array_length(__cachedLines) * __lineHeight) - (__layout.height - 16));
        if (__isMultiline && __wordWrap) {
            __maxScrollX = 0;
        } else {
            var _fullWidth = __getTextWidth(__willow_textbox_get_masked_str(self, __text));
            __maxScrollX = max(0, _fullWidth + __getPrefixOffset() - (__layout.width - 16));
        }
        __allowScroll = __inputState.__focus;
        
        if (__isResizing) return;
        
        // - FOCUS & MOUSE DRAG
        if (device_mouse_check_button_pressed(0, mb_left) && !__eventState.hover) {
            __inputState.__focus = false;
            __inputState.__isDragging = false;
        }

        if (!device_mouse_check_button(0, mb_left)) {
            if (__inputState.__isDragging && !__eventState.hover && window_get_cursor() != cr_default) window_set_cursor(cr_default);
            __inputState.__isDragging = false;
            __inputState.__selectMode = WILLOW_SELECT_MODE.REGULAR;
        }

        if (!__inputState.__focus) return;
        
        if (__inputState.__isDragging) {
            var _mouseIdx = __getCursorIndexFromMouse();
            
            if (__inputState.__selectMode == WILLOW_SELECT_MODE.WORD) {
                var _wordStart = _mouseIdx;
                while (_wordStart > 0 && !__willow_is_boundary(string_char_at(__text, _wordStart))) _wordStart--;
                
                var _wordEnd = _mouseIdx + 1;
                var _len = string_length(__text);
                while (_wordEnd <= _len && !__willow_is_boundary(string_char_at(__text, _wordEnd))) _wordEnd++;
                _wordEnd -= 1;
        
                if (_mouseIdx < __inputState.__pivotStart) {
                    __inputState.__cursor = _wordStart;
                    __inputState.__selectStart = __inputState.__pivotEnd;
                } else {
                    __inputState.__cursor = _wordEnd;
                    __inputState.__selectStart = __inputState.__pivotStart;
                }
            } else {
                __inputState.__cursor = _mouseIdx;
            }
            
            __scrollToCursor();
            __inputState.__blinkTimer = 0;
        }
        
        __inputState.__blinkTimer = (__inputState.__blinkTimer + 1) % (__inputState.__blinkRate * 2);

        // - KEYBOARD NAVIGATION
        var _shift = keyboard_check(vk_shift);
        var _ctrl  = keyboard_check(vk_control);
        var _moved = false;

        if (keyboard_check_pressed(vk_tab)) {
            __willow_jump_focus(self, _shift ? -1 : 1);
            return;
        }

        var _pressNav = keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_up) || keyboard_check_pressed(vk_down);
        var _holdNav = keyboard_check(vk_left) || keyboard_check(vk_right) || keyboard_check(vk_up) || keyboard_check(vk_down);
        
        if (_pressNav) {
            __inputState.__navTimer = 0;
        } else if (_holdNav) {
            __inputState.__navTimer++;
        } else {
            __inputState.__navTimer = 0;
        }

        var _navDelay = 25; 
        var _navSpeed = 2;  
        var _canRepeat = (__inputState.__navTimer > _navDelay) && ((__inputState.__navTimer % _navSpeed) == 0);

        var _up    = keyboard_check_pressed(vk_up)    || (keyboard_check(vk_up)    && _canRepeat);
        var _down  = keyboard_check_pressed(vk_down)  || (keyboard_check(vk_down)  && _canRepeat);
        var _left  = keyboard_check_pressed(vk_left)  || (keyboard_check(vk_left)  && _canRepeat);
        var _right = keyboard_check_pressed(vk_right) || (keyboard_check(vk_right) && _canRepeat);

        if (_up || _down || _left || _right) __inputState.__blinkTimer = 0;
        
        if (_up || _down) {
            if (__isMultiline) {
                if (_shift) {
                    if (__inputState.__selectStart == -1) __inputState.__selectStart = __inputState.__cursor;
                } else __inputState.__selectStart = -1;
                
                var _coords = __willow_textbox_get_cursor_coords(self, __inputState.__cursor);
                var _targetLineIdx = _coords.line_idx + (_up ? -1 : 1);
                
                if (_targetLineIdx < 0) {
                    if (__willow_jump_focus(self, -1)) return;
                } else if (_targetLineIdx >= array_length(__cachedLines)) {
                    if (__willow_jump_focus(self, 1)) return;
                } else __inputState.__cursor = __getIndexFromXCoord(_coords.x, __cachedLines[_targetLineIdx]);
                
                _moved = true;
            } else {
                if (keyboard_check_pressed(vk_up)) __willow_jump_focus(self, -1);
                if (keyboard_check_pressed(vk_down)) __willow_jump_focus(self, 1);
                return;
            }
        }

        if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_return)) {
            if (__isMultiline && !__submitOnEnter) {
                if (__inputState.__selectStart != -1 && __inputState.__selectStart != __inputState.__cursor) {
                    var _minS = min(__inputState.__cursor, __inputState.__selectStart);
                    var _maxS = max(__inputState.__cursor, __inputState.__selectStart);
                    __text = string_copy(__text, 1, _minS) + string_copy(__text, _maxS + 1, string_length(__text) - _maxS);
                    __inputState.__cursor = _minS;
                    __inputState.__selectStart = -1;
                }
                __text = string_insert("\n", __text, __inputState.__cursor + 1);
                __inputState.__cursor += 1;
                keyboard_string = __text;
                __inputState.__blinkTimer = 0;
                _moved = true;
            } else { 
                __inputState.__focus = false; 
                return; 
            }
        }

        // - TEXT MANIPULATION & CLIPBOARD
        var _del = keyboard_check_pressed(vk_delete);
        var _bs  = keyboard_check_pressed(vk_backspace);

        if (_ctrl) {
            var _hasSel = (__inputState.__selectStart != -1 && __inputState.__selectStart != __inputState.__cursor);
            var _minS = _hasSel ? min(__inputState.__cursor, __inputState.__selectStart) : __inputState.__cursor;
            var _maxS = _hasSel ? max(__inputState.__cursor, __inputState.__selectStart) : __inputState.__cursor;
            
            if (keyboard_check_pressed(ord("A"))) { 
                __inputState.__selectStart = 0; 
                __inputState.__cursor = string_length(__text); 
                __inputState.__blinkTimer = 0; 
            }
            if (keyboard_check_pressed(ord("C")) && _hasSel) clipboard_set_text(string_copy(__text, _minS + 1, _maxS - _minS));
            if (keyboard_check_pressed(ord("X")) && _hasSel) {
                clipboard_set_text(string_copy(__text, _minS + 1, _maxS - _minS));
                __text = string_copy(__text, 1, _minS) + string_copy(__text, _maxS + 1, string_length(__text) - _maxS);
                __inputState.__cursor = _minS; 
                __inputState.__selectStart = -1; 
                keyboard_string = __text; 
                __inputState.__blinkTimer = 0; 
                _moved = true;
            }
            if (keyboard_check_pressed(ord("V"))) {
                if (clipboard_has_text()) {
                    var _insertText = string_replace_all(clipboard_get_text(), "\r", ""); 
                    if (_hasSel) {
                        __text = string_copy(__text, 1, _minS) + string_copy(__text, _maxS + 1, string_length(__text) - _maxS);
                        __inputState.__cursor = _minS; 
                        __inputState.__selectStart = -1;
                    }
                    __text = string_insert(_insertText, __text, __inputState.__cursor + 1);
                    __inputState.__cursor += string_length(_insertText); 
                    keyboard_string = __text; 
                    __inputState.__blinkTimer = 0; 
                    _moved = true;
                }
            }
            if (_bs) {
                if (_hasSel) {
                    __text = string_copy(__text, 1, _minS) + string_copy(__text, _maxS + 1, string_length(__text) - _maxS);
                    __inputState.__cursor = _minS; 
                    __inputState.__selectStart = -1;
                } else if (__inputState.__cursor > 0) {
                    var _delStart = __inputState.__cursor;
                    while (_delStart > 0 && __willow_is_boundary(string_char_at(__text, _delStart))) _delStart--;
                    while (_delStart > 0 && !__willow_is_boundary(string_char_at(__text, _delStart))) _delStart--;
                    __text = string_copy(__text, 1, _delStart) + string_copy(__text, __inputState.__cursor + 1, string_length(__text) - __inputState.__cursor);
                    __inputState.__cursor = _delStart;
                }
                keyboard_string = __text; 
                __inputState.__blinkTimer = 0; 
                _moved = true;
            }
        }

        // - HORIZONTAL SKIPPING
        if (_left || _right) {
            if (_shift) {
                if (__inputState.__selectStart == -1) __inputState.__selectStart = __inputState.__cursor;
            } else __inputState.__selectStart = -1;

            if (_ctrl) {
                var _len = string_length(__text);
                if (_left) {
                    while (__inputState.__cursor > 0 && __willow_is_boundary(string_char_at(__text, __inputState.__cursor))) __inputState.__cursor--;
                    while (__inputState.__cursor > 0 && !__willow_is_boundary(string_char_at(__text, __inputState.__cursor))) __inputState.__cursor--;
                } else if (_right) {
                    while (__inputState.__cursor < _len && __willow_is_boundary(string_char_at(__text, __inputState.__cursor + 1))) __inputState.__cursor++;
                    while (__inputState.__cursor < _len && !__willow_is_boundary(string_char_at(__text, __inputState.__cursor + 1))) __inputState.__cursor++;
                }
            } else {
                if (_left) {
                    __inputState.__cursor = max(0, __inputState.__cursor - 1);
                    if (!__isMultiline) {
                        while (__inputState.__cursor > 0 && (string_char_at(__text, __inputState.__cursor) == "\n" || string_char_at(__text, __inputState.__cursor) == "\r")) __inputState.__cursor--;
                    } else if (_shift) {
                        if (__inputState.__cursor > 0 && string_char_at(__text, __inputState.__cursor) == "\n") {
                            __inputState.__cursor = max(0, __inputState.__cursor - 1);
                        }
                    }
                }
                if (_right) {
                    __inputState.__cursor = min(string_length(__text), __inputState.__cursor + 1);
                    if (!__isMultiline) {
                        while (__inputState.__cursor <= string_length(__text) && __inputState.__cursor > 0 && (string_char_at(__text, __inputState.__cursor) == "\n" || string_char_at(__text, __inputState.__cursor) == "\r")) __inputState.__cursor++;
                    } else if (_shift) {
                        if (__inputState.__cursor <= string_length(__text) && __inputState.__cursor > 0 && string_char_at(__text, __inputState.__cursor) == "\n") {
                            __inputState.__cursor = min(string_length(__text), __inputState.__cursor + 1);
                        }
                    }
                }
            }
            _moved = true;
        }

        if (keyboard_check_pressed(vk_home)) {
            if (_shift) {
                if (__inputState.__selectStart == -1) __inputState.__selectStart = __inputState.__cursor;
            } else __inputState.__selectStart = -1;
            
            if (__isMultiline) {
                var _coords = __willow_textbox_get_cursor_coords(self, __inputState.__cursor);
                __inputState.__cursor = _coords.line_data.start_idx - 1;
            } else __inputState.__cursor = 0;
            
            __inputState.__blinkTimer = 0; 
            _moved = true;
        }
        
        if (keyboard_check_pressed(vk_end)) {
            if (_shift) {
                if (__inputState.__selectStart == -1) __inputState.__selectStart = __inputState.__cursor;
            } else __inputState.__selectStart = -1;
            
            if (__isMultiline) {
                var _coords = __willow_textbox_get_cursor_coords(self, __inputState.__cursor);
                __inputState.__cursor = _coords.line_data.has_newline ? (_coords.line_data.end_idx - 1) : _coords.line_data.end_idx;
            } else __inputState.__cursor = string_length(__text);
            
            __inputState.__blinkTimer = 0; 
            _moved = true;
        }

        var _cleanKB = string_replace_all(keyboard_string, "\r", "");
        if (!__isMultiline) _cleanKB = string_replace_all(_cleanKB, "\n", "");
        
        var _bufferChanged = (_cleanKB != __text);
        
        // - NATIVE TYPE ADDITIONS & DELETIONS
        if ((_del || _bs || _bufferChanged) && !_ctrl) {
            var _hasSel = (__inputState.__selectStart != -1 && __inputState.__selectStart != __inputState.__cursor);
            var _minS = _hasSel ? min(__inputState.__cursor, __inputState.__selectStart) : __inputState.__cursor;
            var _maxS = _hasSel ? max(__inputState.__cursor, __inputState.__selectStart) : __inputState.__cursor;
            
            if (_hasSel) {
                if (_del || _bs) {
                    __text = string_copy(__text, 1, _minS) + string_copy(__text, _maxS + 1, string_length(__text) - _maxS);
                    __inputState.__cursor = _minS;
                } else if (_bufferChanged && string_length(_cleanKB) > string_length(__text)) {
                    var _added = string_copy(_cleanKB, string_length(__text) + 1, string_length(_cleanKB) - string_length(__text));
                    __text = string_copy(__text, 1, _minS) + _added + string_copy(__text, _maxS + 1, string_length(__text) - _maxS);
                    __inputState.__cursor = _minS + string_length(_added);
                }
            } else {
                if (_del && __inputState.__cursor < string_length(__text)) {
                    __text = string_copy(__text, 1, __inputState.__cursor) + string_copy(__text, __inputState.__cursor + 2, string_length(__text) - __inputState.__cursor - 1);
                } else if (_bs && __inputState.__cursor > 0) {
                    __text = string_copy(__text, 1, __inputState.__cursor - 1) + string_copy(__text, __inputState.__cursor + 1, string_length(__text) - __inputState.__cursor);
                    __inputState.__cursor--;
                } else if (_bufferChanged && string_length(_cleanKB) > string_length(__text)) {
                    var _added = string_copy(_cleanKB, string_length(__text) + 1, string_length(_cleanKB) - string_length(__text));
                    __text = string_copy(__text, 1, __inputState.__cursor) + _added + string_copy(__text, __inputState.__cursor + 1, string_length(__text) - __inputState.__cursor);
                    __inputState.__cursor += string_length(_added);
                } else if (_bufferChanged && string_length(_cleanKB) < string_length(__text)) {
                    var _diff = string_length(__text) - string_length(_cleanKB);
                    if (__inputState.__cursor >= _diff) {
                        __text = string_copy(__text, 1, __inputState.__cursor - _diff) + string_copy(__text, __inputState.__cursor + 1, string_length(__text) - __inputState.__cursor);
                        __inputState.__cursor -= _diff;
                    }
                }
            }
            __inputState.__selectStart = -1; 
            keyboard_string = __text; 
            __inputState.__blinkTimer = 0; 
            _moved = true;
        } else if (_ctrl && _bufferChanged) keyboard_string = __text; 
        
        if (_moved) __scrollToCursor();
    };

    static drawText = function() {
        if (__layout.width <= 0 || __render.alpha[0] <= 0) return;
        var _sys = __WillowSystem();
        
        // Enforce strict integer coordinate snapping to prevent sub-pixel font blurring
        var _dx = round(getDrawX());
        var _dy = round(getDrawY());
        var _szW = round(__layout.width);
        var _szH = round(__layout.height);
        
        __willow_update_textbox_cache(self);

        // - FOCUS RING (Drawn outside the stencil mask)
        if (__inputState.__focus) {
            var _focusGap = 1;
            var _focusThick = 2;
            var _oc = variable_struct_exists(__render, "outline_colour") ? __render.outline_colour : _sys.theme.color.primary;
            var _oa = __render.alpha[0] * (variable_struct_exists(__render, "outline_alpha") ? __render.outline_alpha : 0.6);
            
            __willow_draw_focus_ring(_dx, _dy, _szW, _szH, __render.rounding, _focusThick, _focusGap, _oc, _oa);
        }

        var _font = __render[$ "text_font"] ?? _sys.default_font;
        var _fontName = is_string(_font) ? _font : font_get_name(_font);
        var _colour = variable_struct_exists(__render, "text_colour") ? __render.text_colour : _sys.theme.color.base_content;
        var _alpha = (variable_struct_exists(__render, "text_alpha") ? __render.text_alpha : 1) * __render.alpha[0];

        var _roundingOffset = max(10, __render.rounding * 0.5);
        var _alignV = __isMultiline ? fa_top : fa_middle;
        var _textX = round(_dx + _roundingOffset - __scrollX);
        var _textY = round(__isMultiline ? (_dy + _roundingOffset - __scrollY) : (_dy + (_szH / 2)));
        var _interactiveX = _textX + __getPrefixOffset();

        // APPLY MATRIX
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);
        
        // MASK
        var _clipInset = 2; 
        var _prevMask = __willow_mask_push(
            _dx + _clipInset, 
            _dy + _clipInset, 
            max(0, _szW - (_clipInset * 2)), 
            max(0, _szH - (_clipInset * 2)), 
            max(0, __render.rounding - _clipInset)
        );

        // - PASS 1: PLACEHOLDER
        if (__text == "" && !__inputState.__focus) {
            var _phDraw = __placeholder;
            if (!__isMultiline) _phDraw = string_replace_all(_phDraw, "\n", "");
            var _phAlpha = _alpha * 0.4;

            if (_sys.use_scribble) {
                scribble(_phDraw).starting_format(_fontName, _colour).align(fa_left, _alignV).blend(_colour, _phAlpha)
                    .wrap(__isMultiline ? (_szW - (_roundingOffset * 2)) : -1).draw(_textX, _textY);
            } else {
                draw_set_halign(fa_left); draw_set_valign(_alignV);
                draw_set_color(_colour); draw_set_alpha(_phAlpha);
                var _fidx = is_string(_font) ? asset_get_index(_font) : _font;
                if (font_exists(_fidx)) draw_set_font(_fidx);
                draw_text_ext(_textX, _textY, _phDraw, __lineHeight, __isMultiline ? (_szW - (_roundingOffset * 2)) : -1);
            }
        }
        
        // - PASS 2: ACTIVE TEXT & SELECTIONS
        else {
            if (__prefixText != "") {
                var _preAlpha = _alpha * 0.7;
                if (_sys.use_scribble) {
                    scribble(__prefixText).starting_format(_fontName, _colour).align(fa_left, _alignV)
                        .blend(_colour, _preAlpha).scale(0.8).draw(_textX, _textY);
                } else {
                    draw_set_halign(fa_left);
                    draw_set_valign(_alignV); draw_set_alpha(_preAlpha);
                    var _fidx = is_string(_font) ? asset_get_index(_font) : _font;
                    if (font_exists(_fidx)) draw_set_font(_fidx);
                    draw_text_transformed(_textX, _textY, __prefixText, 0.8, 0.8, 0);
                }
            }

            var _hasSel = (__inputState.__focus && __inputState.__selectStart != -1 && __inputState.__selectStart != __inputState.__cursor);
            var _count = array_length(__cachedLines);
            
            // LAYER A: Selection Backgrounds
            if (_hasSel) {
                var _selCol = __render.select_colour;
                var _selAlpha = __render.select_alpha * __render.alpha[0];
                var _minS = min(__inputState.__cursor, __inputState.__selectStart);
                var _maxS = max(__inputState.__cursor, __inputState.__selectStart);
                var _highlightRender = { colours: [_selCol, _selCol, _selCol, _selCol], alpha: [_selAlpha, _selAlpha, _selAlpha, _selAlpha], borderColours: [c_white, c_white, c_white, c_white], borderAlpha: [0, 0, 0, 0], borderWidth: 0, rounding: 0 };
                
                var _drawYCursor = _textY;
                var _i = 0; repeat(_count) {
                    var _line = __cachedLines[_i];
                    if (_maxS > _line.start_idx - 1 && _minS < _line.end_idx) {
                        var _masked = __willow_textbox_get_masked_str(self, _line.text);
                        var _selStart = max(0, _minS - (_line.start_idx - 1));
                        var _selEnd   = min(string_length(_line.text), _maxS - (_line.start_idx - 1));
                        var _preText  = string_copy(_masked, 1, _selStart);
                        var _selText  = string_copy(_masked, _selStart + 1, _selEnd - _selStart);
                        
                        var _selX = _interactiveX + __getTextWidth(_preText);
                        var _selW = __getTextWidth(_selText);
                        var _selY = __isMultiline ? _drawYCursor : _drawYCursor - (__lineHeight / 2);
                        
                        if (_maxS >= _line.end_idx && _line.has_newline && _selW == 0) _selW += 8;

                        if (_sys.use_clean_shapes) {
                            __willow_draw_rectangle_cleanshapes(_selX, _selY, _selW, __lineHeight, _highlightRender);
                        } else {
                            __willow_draw_rectangle_native(_selX, _selY, _selW, __lineHeight, _highlightRender);
                        }
                    }
                    _drawYCursor += __lineHeight;
                    _i++;
                }
            }

            // LAYER B: Text Content
            if (!_sys.use_scribble) {
                draw_set_halign(fa_left); draw_set_valign(_alignV);
                draw_set_color(_colour); draw_set_alpha(_alpha);
                var _fidx = is_string(_font) ? asset_get_index(_font) : _font;
                if (font_exists(_fidx)) draw_set_font(_fidx);
            }

            var _drawYCursor = _textY;
            var _i = 0; repeat(_count) {
                var _line = __cachedLines[_i];
                var _masked = __willow_textbox_get_masked_str(self, _line.text);

                if (_sys.use_scribble) {
                    scribble(string_replace_all(_masked, "[", "[[")).starting_format(_fontName, _colour).align(fa_left, _alignV).blend(_colour, _alpha).draw(_interactiveX, _drawYCursor);
                } else {
                    draw_text(_interactiveX, _drawYCursor, _masked);
                }
                _drawYCursor += __lineHeight;
                _i++;
            }
            if (!_sys.use_scribble) draw_set_alpha(1);
        }
        
        // - PASS 3: CURSOR
        if (__inputState.__focus && __inputState.__blinkTimer < __inputState.__blinkRate) {
            var _coords = __willow_textbox_get_cursor_coords(self, __inputState.__cursor);
            var _cx = _textX + _coords.x;
            var _cy = _textY + _coords.y;
            draw_set_alpha(_alpha);
            if (__isMultiline) draw_line_width_color(_cx, _cy, _cx, _cy + __lineHeight, 2, _colour, _colour);
            else draw_line_width_color(_cx, _cy - (__lineHeight / 2), _cx, _cy + (__lineHeight / 2), 2, _colour, _colour);
        }

        // POP STENCIL MASK
        __willow_mask_pop(
            _dx + _clipInset, 
            _dy + _clipInset, 
            max(0, _szW - (_clipInset * 2)), 
            max(0, _szH - (_clipInset * 2)), 
            max(0, __render.rounding - _clipInset),
            _prevMask
        );

        // RESTORE MATRIX
        if (_matrixPushed) __willow_matrix_restore_transform();
        
        draw_set_alpha(1);

        // Render accessories outside of the clipping boundaries
        __willow_draw_scrollbars(self);
        __willow_draw_resize_handle(self);
    };
    
    #endregion

    #region EVENT BINDINGS
    
    onClick(function() {
        if (__isResizing || __isMouseInResizeHandle(window_mouse_get_x(), window_mouse_get_y())) return;
        
        __inputState.__focus = true; 
        __inputState.__isDragging = true; 
        __inputState.__selectMode = WILLOW_SELECT_MODE.REGULAR;
        keyboard_string = __text;
        
        var _targetIdx = __getCursorIndexFromMouse();
        
        if (keyboard_check(vk_shift)) {
            if (__inputState.__selectStart == -1) __inputState.__selectStart = __inputState.__cursor;
            __inputState.__cursor = _targetIdx;
        } else {
            __inputState.__cursor = _targetIdx; 
            __inputState.__selectStart = _targetIdx; 
        }
        __inputState.__blinkTimer = 0;
    });

    onDoubleClick(function() {
        if (__isResizing || __text == "") return;
        var _idx = __getCursorIndexFromMouse();
        
        // Find word boundaries
        var _start = _idx;
        while (_start > 0 && !__willow_is_boundary(string_char_at(__text, _start))) _start--;
        var _end = _idx + 1;
        var _len = string_length(__text);
        while (_end <= _len && !__willow_is_boundary(string_char_at(__text, _end))) _end++;
        
        __inputState.__selectMode = WILLOW_SELECT_MODE.WORD;
        __inputState.__pivotStart = _start;
        __inputState.__pivotEnd = _end - 1;
        
        __inputState.__selectStart = _start; 
        __inputState.__cursor = _end - 1; 
        __inputState.__isDragging = true;
    });
    
    #endregion
}