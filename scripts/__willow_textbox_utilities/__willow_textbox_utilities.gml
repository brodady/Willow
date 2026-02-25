/// @ignore Centralized text layout engine for Willow text components.
function __willow_update_textbox_cache(_box) {
    var _sys = __WillowSystem();
    var _layout = _box.__layout;
    if (_layout == undefined) return;

    if (_box.__text == _box.__lastText && _layout.width == _box.__lastWidth && array_length(_box.__cachedLines) > 0) return;

    _box.__lastText = _box.__text;
    _box.__lastWidth = _layout.width;
    _box.__cachedLines = [];

    var _font = _box.__render[$ "text_font"] ?? _sys.default_font;
    
    if (_sys.use_scribble) {
        var _fontName = is_string(_font) ? _font : font_get_name(_font);
        _box.__lineHeight = scribble("A").starting_format(_fontName, c_white).get_height();
    } else {
        var _fidx = is_string(_font) ? asset_get_index(_font) : _font;
        if (font_exists(_fidx)) draw_set_font(_fidx);
        _box.__lineHeight = string_height("A");
    }

    var _textLen = string_length(_box.__text);
    var _maxW = max(10, _layout.width - 16);

    if (_textLen == 0) {
        array_push(_box.__cachedLines, { text: "", start_idx: 1, end_idx: 0, has_newline: false });
        return;
    }

    if (!_box.__isMultiline) {
        array_push(_box.__cachedLines, { text: _box.__text, start_idx: 1, end_idx: _textLen, has_newline: false });
        return; 
    }

    var _startIdx = 1;
    var _lastSpaceIdx = -1;

    for (var _i = 1; _i <= _textLen; _i++) {
        var _char = string_char_at(_box.__text, _i);

        if (_char == "\n") {
            var _lineStr = string_copy(_box.__text, _startIdx, _i - _startIdx);
            array_push(_box.__cachedLines, { text: _lineStr, start_idx: _startIdx, end_idx: _i, has_newline: true });
            _startIdx = _i + 1; _lastSpaceIdx = -1; continue;
        }
        
        if (_char == " ") _lastSpaceIdx = _i;

        if (_box.__wordWrap) {
            var _currentSub = string_copy(_box.__text, _startIdx, _i - _startIdx + 1);
            var _masked = __willow_textbox_get_masked_str(_box, _currentSub);

            if (_box.__getTextWidth(_masked) > _maxW && _startIdx < _i) {
                if (_lastSpaceIdx != -1 && _lastSpaceIdx >= _startIdx) {
                    var _lineStr = string_copy(_box.__text, _startIdx, _lastSpaceIdx - _startIdx);
                    array_push(_box.__cachedLines, { text: _lineStr, start_idx: _startIdx, end_idx: _lastSpaceIdx, has_newline: false });
                    _i = _lastSpaceIdx; _startIdx = _i + 1; _lastSpaceIdx = -1;
                } else {
                    var _lineStr = string_copy(_box.__text, _startIdx, _i - _startIdx);
                    array_push(_box.__cachedLines, { text: _lineStr, start_idx: _startIdx, end_idx: _i - 1, has_newline: false });
                    _i--; _startIdx = _i + 1; _lastSpaceIdx = -1;
                }
            }
        }
    }
    
    if (_startIdx <= _textLen + 1) {
        var _lineStr = string_copy(_box.__text, _startIdx, _textLen - _startIdx + 1);
        array_push(_box.__cachedLines, { text: _lineStr, start_idx: _startIdx, end_idx: max(_startIdx - 1, _textLen), has_newline: false });
    }
}

/// @ignore Calculates the X/Y coordinates for a character index within a textbox.
function __willow_textbox_get_cursor_coords(_box, _index) {
    __willow_update_textbox_cache(_box);
    var _count = array_length(_box.__cachedLines);
    
    for (var _i = 0; _i < _count; _i++) {
        var _l = _box.__cachedLines[_i];
        if (_index >= _l.start_idx - 1 && _index < _l.end_idx) {
            var _charOffset = _index - (_l.start_idx - 1);
            var _sub = string_copy(_l.text, 1, _charOffset);
            var _masked = __willow_textbox_get_masked_str(_box, _sub);
            return { x: _box.__getTextWidth(_masked) + _box.__getPrefixOffset(), y: _i * _box.__lineHeight, line_idx: _i, line_data: _l };
        }
    }
    
    var _lastIdx = max(0, _count - 1);
    if (_lastIdx < 0) return { x: _box.__getPrefixOffset(), y: 0, line_idx: 0, line_data: { start_idx: 1, end_idx: 0, text: "", has_newline: false } };
    
    var _l = _box.__cachedLines[_lastIdx];
    var _charOffset = _index - (_l.start_idx - 1);
    var _sub = string_copy(_l.text, 1, _charOffset);
    var _masked = __willow_textbox_get_masked_str(_box, _sub);
    return { x: _box.__getTextWidth(_masked) + _box.__getPrefixOffset(), y: _lastIdx * _box.__lineHeight, line_idx: _lastIdx, line_data: _l };
}

/// @ignore Returns a masked version of the string if a replacement character is set.
function __willow_textbox_get_masked_str(_box, _str) {
    if (_box.__replacementChar == "") return _str;

    var _res = "";
    var _len = string_length(_str);
    var _i = 1; repeat(_len) {
        var _c = string_char_at(_str, _i);
        _res += (_c == "\n" || _c == "\r") ? _c : _box.__replacementChar;
        _i++;
    }
    return _res;
}

/// @ignore Returns the word boundary index relative to the cursor.
function __willow_textbox_find_word_boundary(_box, _dir) {
    var _cur = _box.__inputState.__cursor;
    var _txt = _box.__text;
    var _len = string_length(_txt);

    if (_dir == -1) {
        while (_cur > 0 && __willow_is_boundary(string_char_at(_txt, _cur))) _cur--;
        while (_cur > 0 && !__willow_is_boundary(string_char_at(_txt, _cur))) _cur--;
    } else {
        while (_cur < _len && __willow_is_boundary(string_char_at(_txt, _cur + 1))) _cur++;
        while (_cur < _len && !__willow_is_boundary(string_char_at(_txt, _cur + 1))) _cur++;
    }
    return _cur;
}

/// @ignore Checks if a character is a word boundary.
function __willow_is_boundary(_char) {
    static _boundaries = " .,!&$%\"\':;#@()[]{}?/\\\n\r";
    return (string_pos(_char, _boundaries) > 0);
}