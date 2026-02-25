/// @func    WillowBox(_name, [_style], [_layoutDir])
/// @desc    Base structural component for the Willow UI library.
/// @param   {String} _name
/// @param   {Struct.WillowStyle} [_style]
/// @param   {Real} [_layoutDir]
/// @return  {Struct.WillowBox} self
function WillowBox(_name, _style = new WillowStyle(), _layoutDir = flexpanel_direction.LTR) constructor {

    #region INTERNAL VARIABLES
    
    // - SYSTEM IDENTITY
    static __numBoxes = 0;
    __id = __numBoxes++;
    __name = _name;
    __report = __willow_get_report_tag();

    // - STRUCTURAL HIERARCHY
    __styleDefinition = _style;
    __style = _style.toFlexStruct();
    __render = _style.toRenderStruct();
    __layout = undefined;
    __parent = undefined;
    __children = [];
    __layoutDir = _layoutDir;

    // - NODE STATE
    __node = flexpanel_create_node(__style);
    __isOverlay = false;
    __isHittable = true;
    __render.depth = __render.depth - __id;

    // - INTERACTION & RESIZING
    __cursorStyle = cr_default;
    __isResizing = false;
    __resizableH = false;
    __resizableV = false;
    __targetW = undefined;
    __targetH = undefined;
    __resizeStartW = 0; __resizeStartH = 0;
    __resizeStartMx = 0; __resizeStartMy = 0;

    // - SCROLLING
    __allowScroll = true;
    __scrollX = 0; __scrollY = 0;
    __maxScrollX = 0; __maxScrollY = 0;

    // - EVENTS & TRANSITIONS
    __eventState = {
        hover: false,           
        click_time: -1,         
        last_event: undefined,  
        entered: false
    };
    __eventBlocks = array_create(WILLOW_BOX_EVENTS, undefined);
    __lastEventBlock = undefined; 
    
    #endregion

    #region PUBLIC API: GEOMETRY & HIERARCHY

    /// @func    getNode()
    /// @desc    Retrieves the Flexpanel node pointer.
    /// @return  {Pointer}
    static getNode = function() { return __node; };
    
    /// @func    getDrawX()
    /// @desc    Calculates the local X coordinate including offsets and scrolling.
    /// @return  {Real}
    static getDrawX = function() { 
        return __layout.left + __render.offsetX - (variable_struct_exists(__render, "scroll_x") ? __render.scroll_x : 0); 
    };

    /// @func    getDrawY()
    /// @desc    Calculates the local Y coordinate including offsets and scrolling.
    /// @return  {Real}
    static getDrawY = function() {
        return __layout.top + __render.offsetY - (variable_struct_exists(__render, "scroll_y") ? __render.scroll_y : 0); 
    };

    /// @func    alwaysOnTop()
    /// @desc    Configures the box as a top-level overlay.
    /// @return  {Struct.WillowBox} self
    static alwaysOnTop = function() {
        var _sys = __WillowSystem();
        __isOverlay = true;
        __render.depth = WILLOW_OVERLAY_DEPTH;
        
        var _exists = false;
        var _len = array_length(_sys.overlays);
        var _i = 0; repeat(_len) {
            if (_sys.overlays[_i] == self) { _exists = true; break; }
            _i++;
        }
        if (!_exists) array_push(_sys.overlays, self);
        
        __syncChildrenDepth();
        return self;
    };

    /// @func    contains(_input)
    /// @desc    Populates the box with children and updates the flex tree.
    /// @param   {Struct.WillowBox, Array<Struct.WillowBox>} _input
    /// @return  {Struct.WillowBox} self
    static contains = function(_input) {
        var _new = is_array(_input) ? _input : [_input];
        __children = [];
        flexpanel_node_remove_all_children(__node);

        var _len = array_length(_new);
        var _i = 0; repeat(_len) {
            var _child = _new[_i];
            if (is_struct(_child) && variable_struct_exists(_child, "getNode")) {
                array_push(__children, _child);
                flexpanel_node_insert_child(__node, _child.getNode(), _i);
                _child.__parent = self;
            }
            _i++;
        }
        __syncChildrenDepth();
        return self;
    };

    /// @func    updatePosition([_forceChildren])
    /// @desc    Synchronizes render boundaries with the calculated layout.
    /// @param   {Bool} [_forceChildren] 
    /// @return  {Undefined}
    static updatePosition = function(_forceChildren = false) {
        var _sys = __WillowSystem();
        __layout = flexpanel_node_layout_get_position(__node, false);

        var _tapeKey = "willow_box_" + string(__id);
        if (!_sys.deck.isPlaying(_tapeKey)) {
            __render.width  = __layout.width;
            __render.height = __layout.height;
        }

        if (_forceChildren) {
            var _len = array_length(__children);
            var _i = 0; repeat(_len) {
                var _child = __children[_i];
                if (is_struct(_child) && variable_struct_exists(_child, "updatePosition")) {
                    _child.updatePosition(true);
                }
                _i++;
            }
        }
    };
    
    #endregion

    #region PUBLIC API: EVENTS & TRANSITIONS
    
    /// @func    setCursor(_cursor)
    /// @desc    Sets the cursor style to display when hovering or resizing this box.
    /// @param   {Constant.Cursor} _cursor 
    /// @return  {Struct.WillowBox} self
    static setCursor = function(_cursor) {
        __cursorStyle = _cursor;
        return self;
    };

    /// @func    setResizable([_horizontal], [_vertical])
    /// @desc    Configures whether this box can be manually resized by the user.
    /// @param   {Bool} [_horizontal] 
    /// @param   {Bool} [_vertical] 
    /// @return  {Struct.WillowBox} self
    static setResizable = function(_horizontal = true, _vertical = true) {
        __resizableH = _horizontal;
        __resizableV = _vertical;
        
        flexpanel_node_style_set_flex_shrink(__node, 1);
        flexpanel_node_style_set_max_width(__node, 100, flexpanel_unit.percent);
        flexpanel_node_style_set_max_height(__node, 100, flexpanel_unit.percent);
        return self;
    };

    /// @func    onEnter(_styleOrFn, [_fn])
    /// @desc    Registers a hover enter event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onEnter = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.enter, _s, _f); return self; };
    
    /// @func    onLeave(_styleOrFn, [_fn])
    /// @desc    Registers a hover leave event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onLeave = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.leave, _s, _f); return self; };

    /// @func    onClick(_styleOrFn, [_fn])
    /// @desc    Registers a left-click event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onClick = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.click, _s, _f); return self; };

    /// @func    onDoubleClick(_styleOrFn, [_fn])
    /// @desc    Registers a double-click event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onDoubleClick = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.doubleClick, _s, _f); return self; };

    /// @func    onMiddleClick(_styleOrFn, [_fn])
    /// @desc    Registers a middle-click event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onMiddleClick = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.middleClick, _s, _f); return self; };

    /// @func    onRightClick(_styleOrFn, [_fn])
    /// @desc    Registers a right-click event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onRightClick = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.rightClick, _s, _f); return self; };

    /// @func    onScrollUp(_styleOrFn, [_fn])
    /// @desc    Registers an upward scroll event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onScrollUp = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.scrollUp, _s, _f); return self; };

    /// @func    onScrollDown(_styleOrFn, [_fn])
    /// @desc    Registers a downward scroll event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onScrollDown = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.scrollDown, _s, _f); return self; };

    /// @func    onDrag(_styleOrFn, [_fn])
    /// @desc    Registers a drag event callback or style transition.
    /// @param   {Struct, Function} _styleOrFn
    /// @param   {Function} [_fn]
    /// @return  {Struct.WillowBox} self
    static onDrag = function(_s, _f=undefined) { __createEventBlock(WILLOW_EVENT.drag, _s, _f); return self; };

    /// @func    transition(_seconds, [_ease], [_animMode])
    /// @desc    Sets blanket animation parameters for ALL defined events on this box.
    /// @param   {Real} _seconds
    /// @param   {Function} [_ease]
    /// @param   {Constant} [_animMode]
    /// @return  {Struct.WillowBox} self
    static transition = function(_seconds, _ease = undefined, _animMode = undefined) {
        var _i = 0; repeat(WILLOW_BOX_EVENTS) {
            var _block = __eventBlocks[_i];
            if (_block != undefined) {
                _block.__defaultDuration = max(0, _seconds);
                if (_ease != undefined && is_method(_ease)) _block.__defaultEase = _ease;
                if (_animMode != undefined) _block.setAnimMode(_animMode);
            }
            _i++;
        }
        return self;
    };

    /// @func    withTransition(_duration, [_ease], [_mode])
    /// @desc    Configures timing for the LAST defined event block specifically.
    /// @param   {Real} _duration
    /// @param   {Function} [_ease]
    /// @param   {Constant} [_mode]
    /// @return  {Struct.WillowBox} self
    static withTransition = function(_dur, _ease=undefined, _mode=undefined) {
        if (__lastEventBlock != undefined) {
            __lastEventBlock.setSpecificTransition(_dur, _ease, _mode);
        }
        return self;
    };

    /// @func    animateTo(_style, _duration, [_ease], [_delay])
    /// @desc    Manually triggers a style transition parsing partial properties through WillowStyle mappings.
    /// @param   {Struct.WillowStyle, Struct} _style
    /// @param   {Real} _dur
    /// @param   {Function} [_ease]
    /// @param   {Real} [_delay]
    /// @return  {Struct.WillowBox} self
    static animateTo = function(_style, _dur, _ease=undefined, _delay=0) {
        var _target = {};
        
        if (is_instanceof(_style, WillowStyle)) {
            _target = _style.toRenderStruct();
        } else if (is_struct(_style)) {
            var _tempStyle = new WillowStyle();
            
            _tempStyle.render = {};
            _tempStyle.struct = {};
            
            var _keys = variable_struct_get_names(_style);
            var _len = array_length(_keys);
            var _i = 0; repeat(_len) {
                var _k = _keys[_i];
                var _val = _style[$ _k];
                var _handled = false;
                
                with (_tempStyle) {
                    var _func = self[$ _k];
                    if (_func != undefined && is_callable(_func)) {
                        self[$ _k](_val); 
                        _handled = true;
                    }
                }
                
                if (!_handled) _target[$ _k] = _val;
                _i++;
            }
            
            var _rKeys = variable_struct_get_names(_tempStyle.render);
            var _rLen = array_length(_rKeys);
            var _j = 0; repeat(_rLen) {
                var _rk = _rKeys[_j];
                _target[$ _rk] = _tempStyle.render[$ _rk];
                _j++;
            }
        }
    
        var _sys = __WillowSystem();
        _sys.deck.insert("willow_box_" + string(__id))
            .bind(__render)
            .startDelay(max(0, _delay))
            .to(_target)
            .duration(max(0.01, _dur))
            .ease(_ease ?? CassetteEase.Linear)
            .play();
            
        return self;
    };

    // -- DEPRECATED API METHODS --
    
    /// @func    Title(_txt, [_align])
    /// @desc    Deprecated API wrapper.
    /// @param   {String} _txt
    /// @param   {Constant.HAlign} [_align]
    /// @return  {Struct.WillowBox} self
    static Title = function(_txt, _align = fa_left) { show_debug_message("{0} WARNING: Title() not fully implemented in Willow", __report); return self; };
    
    /// @func    HandleSize(_h)
    /// @desc    Deprecated API wrapper.
    /// @param   {Real} _h
    /// @return  {Struct.WillowBox} self
    static HandleSize = function(_h) { show_debug_message("{0} WARNING: HandleSize() not fully implemented in Willow", __report); return self; };
    
    /// @func    CloseButton(_spriteOrObj, [_align])
    /// @desc    Deprecated API wrapper.
    /// @param   {Asset.GMSprite, Asset.GMObject} _spriteOrObj
    /// @param   {Constant.HAlign} [_align]
    /// @return  {Struct.WillowBox} self
    static CloseButton = function(_spriteOrObj, _align = fa_right) { show_debug_message("{0} WARNING: CloseButton() not fully implemented in Willow", __report); return self; };
    
    /// @func    onClose(_f)
    /// @desc    Deprecated API wrapper.
    /// @param   {Function} _f
    /// @return  {Struct.WillowBox} self
    static onClose = function(_f) { show_debug_message("{0} WARNING: onClose() not fully implemented in Willow", __report); return self; };
    
    #endregion

    #region PRIVATE SYSTEM METHODS
    
    /// @ignore
    static __getRenderSize = function() {
        return {
            w: (is_numeric(__render.width) && __render.width != 0)   ? __render.width  : __layout.width,
            h: (is_numeric(__render.height) && __render.height != 0) ? __render.height : __layout.height
        };
    };

    /// @ignore 
    static __createEventBlock = function(_enum, _styleOrFn, _fn = undefined) {
        var _block = __eventBlocks[_enum];
        if (_block == undefined) _block = new WillowStyleTransitionBlock(_enum);

        if (is_method(_styleOrFn)) {
            _block.setCallback(_styleOrFn);
            _block.setStyle(undefined); 
        } else if (is_struct(_styleOrFn)) {
            _block.setStyle(_styleOrFn);
            if (is_method(_fn)) _block.setCallback(_fn);
        }

        __eventBlocks[_enum] = _block;
        __lastEventBlock = _block;
    };
    
    /// @ignore
    static __isMouseInResizeHandle = function(_mx, _my) {
        if (!__resizableH && !__resizableV) return false;
        var _drawX = getDrawX();
        var _drawY = getDrawY();
        var _inset = variable_struct_exists(__render, "rounding") ? ceil(__render.rounding * 0.3) : 0;
        
        var _hx = _drawX + __layout.width - (__resizableH ? _inset + 4 : 0);
        var _hy = _drawY + __layout.height - (__resizableV ? _inset + 4 : 0);
        
        if (__resizableH && __resizableV) {
            return point_in_rectangle(_mx, _my, _hx - 16, _hy - 16, _hx + _inset, _hy + _inset);
        } else if (__resizableV) {
            return point_in_rectangle(_mx, _my, _drawX, _hy - 12, _drawX + __layout.width, _hy + _inset);
        } else if (__resizableH) {
            return point_in_rectangle(_mx, _my, _hx - 12, _drawY, _hx + _inset, _drawY + __layout.height);
        }
        return false;
    };
    
    /// @ignore
    static __getCursorStyle = function(_mx, _my) {
        if (__isResizing || ((__resizableH || __resizableV) && __isMouseInResizeHandle(_mx, _my))) {
            if (__resizableH && __resizableV) return cr_size_nwse;
            if (__resizableV) return cr_size_ns;
            if (__resizableH) return cr_size_we;
        }
        return __cursorStyle;
    };

    /// @ignore 
    static __handleEvent = function(_type) {
        __eventState.last_event = _type;

        switch (_type) {
            case WILLOW_EVENT.enter:
                __eventState.entered = true; __eventState.hover = true;
                __startTransitionFromBlock(__eventBlocks[WILLOW_EVENT.enter]);
                break;

            case WILLOW_EVENT.leave:
                __eventState.hover = false; __eventState.entered = false;
                __startTransitionFromBlock(__eventBlocks[WILLOW_EVENT.leave]);
                break;

            case WILLOW_EVENT.click:
                var _now = current_time;
                var _finalType = WILLOW_EVENT.click;
                var _doubleClick = (_now - __eventState.click_time < WILLOW_DOUBLE_CLICK_TIME);
                if (__eventState.click_time != -1 && _doubleClick) {
                    _finalType = WILLOW_EVENT.doubleClick;
                    __eventState.click_time = -1;
                } else __eventState.click_time = _now;

                __startTransitionFromBlock(__eventBlocks[_finalType]);
                break;

            case WILLOW_EVENT.scrollUp:
            case WILLOW_EVENT.scrollDown:
                var _consumed = false;
                if (!__isResizing && __allowScroll) {
                    var _isUp = (_type == WILLOW_EVENT.scrollUp);
                    var _spd = WILLOW_SCROLL_SPEED;
                    
                    if (keyboard_check(vk_shift) && __maxScrollX > 0) {
                        var _old = __scrollX;
                        __scrollX = _isUp ? max(0, __scrollX - _spd) : min(__maxScrollX, __scrollX + _spd);
                        if (__scrollX != _old) _consumed = true;
                    } else if (__maxScrollY > 0 && !keyboard_check(vk_shift)) {
                        var _old = __scrollY;
                        __scrollY = _isUp ? max(0, __scrollY - _spd) : min(__maxScrollY, __scrollY + _spd);
                        if (__scrollY != _old) _consumed = true;
                    }
                }
                
                // Event Bubbling: Pass scroll inputs up to parent if we didn't use them
                if (!_consumed && __parent != undefined && variable_struct_exists(__parent, "__handleEvent")) {
                    __parent.__handleEvent(_type);
                }

                __startTransitionFromBlock(__eventBlocks[_type]);
                break;

            default:
                __startTransitionFromBlock(__eventBlocks[_type]);
                break;
        }
    };

    /// @ignore 
    static __startTransitionFromBlock = function(_block) {
        if (_block == undefined || !is_struct(_block)) return;
        
        if (_block.hasCallback()) _block.__callback(self);
        var _targetStyle = _block.getTargetStyle();
        if (_targetStyle == undefined) return;

        var _config = _block.getTransitionFor("");
        var _sys = __WillowSystem();
        var _tapeKey = "willow_box_" + string(__id);
        
        var _tape = _sys.deck.insert(_tapeKey)
            .bind(__render)
            .to(_targetStyle.toRenderStruct())
            .duration(max(0.01, _config.duration))
            .ease(_config.ease);
            
        if (_config.anim_mode == WILLOW_ANIM.LOOP) _tape.loop();
        else if (_config.anim_mode == WILLOW_ANIM.PING_PONG) _tape.pingpongTape();

        _tape.play();
    };

    /// @ignore 
    static __applyStyleToNode = function() {
        var _s = __styleDefinition.struct;
        var _n = __node;
        if (variable_struct_exists(_s, "paddingTop"))    flexpanel_node_style_set_padding(_n, flexpanel_edge.top,    _s.paddingTop,    flexpanel_unit.point);
        if (variable_struct_exists(_s, "paddingRight"))  flexpanel_node_style_set_padding(_n, flexpanel_edge.right,  _s.paddingRight,  flexpanel_unit.point);
        if (variable_struct_exists(_s, "paddingBottom")) flexpanel_node_style_set_padding(_n, flexpanel_edge.bottom, _s.paddingBottom, flexpanel_unit.point);
        if (variable_struct_exists(_s, "paddingLeft"))   flexpanel_node_style_set_padding(_n, flexpanel_edge.left,   _s.paddingLeft,   flexpanel_unit.point);
        if (variable_struct_exists(_s, "marginTop"))     flexpanel_node_style_set_margin(_n, flexpanel_edge.top,     _s.marginTop,     flexpanel_unit.point);
        if (variable_struct_exists(_s, "marginRight"))   flexpanel_node_style_set_margin(_n, flexpanel_edge.right,   _s.marginRight,   flexpanel_unit.point);
        if (variable_struct_exists(_s, "marginBottom"))  flexpanel_node_style_set_margin(_n, flexpanel_edge.bottom,  _s.marginBottom,  flexpanel_unit.point);
        if (variable_struct_exists(_s, "marginLeft"))    flexpanel_node_style_set_margin(_n, flexpanel_edge.left,    _s.marginLeft,    flexpanel_unit.point);
    };

    /// @ignore 
    static __syncChildrenDepth = function() {
        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (variable_struct_exists(_child, "__render") && !(_child.__isOverlay)) {
                _child.__render.depth = __render.depth - ((_i + 1) * WILLOW_DEPTH_STEP);
                if (variable_struct_exists(_child, "__syncChildrenDepth")) _child.__syncChildrenDepth();
            }
            _i++;
        }
    };
    
    #endregion

    #region PUBLIC API: CORE LOOP
    
    /// @func    step()
    /// @desc    Core layout validation, scrolling, and interaction processing event.
    /// @return  {Undefined}
    static step = function() {
        var _len = array_length(__children);

        // - RESIZE & SCROLL BOUNDARY CALCULATION
        var _furthestR = 0; var _furthestB = 0;
        if (_len > 0) {
            var _i = 0; repeat(_len) {
                var _c = __children[_i];
                if (variable_struct_exists(_c, "__layout") && _c.__layout != undefined) {
                    var _cw = variable_struct_exists(_c, "getContentWidth") ? _c.getContentWidth() : _c.__layout.width;
                    var _ch = variable_struct_exists(_c, "getContentHeight") ? _c.getContentHeight() : _c.__layout.height;

                    _furthestR = max(_furthestR, _c.__layout.left + _cw);
                    _furthestB = max(_furthestB, _c.__layout.top + _ch);
                }
                _i++;
            }
            __maxScrollX = max(0, ceil(_furthestR - (__layout.left + __layout.width)));
            __maxScrollY = max(0, ceil(_furthestB - (__layout.top + __layout.height)));
        }

        // - SCROLL ACCUMULATION & PROPAGATION
        __scrollX = clamp(__scrollX, 0, __maxScrollX);
        __scrollY = clamp(__scrollY, 0, __maxScrollY);
        
        var _myAccumX = (variable_struct_exists(__render, "scroll_x") ? __render.scroll_x : 0) + __scrollX;
        var _myAccumY = (variable_struct_exists(__render, "scroll_y") ? __render.scroll_y : 0) + __scrollY;
        
        var _i = 0; repeat(_len) {
            if (variable_struct_exists(__children[_i], "__render")) {
                __children[_i].__render.scroll_x = _myAccumX;
                __children[_i].__render.scroll_y = _myAccumY;
            }
            _i++;
        }

        // - RESIZE LOGIC
        if ((__resizableH || __resizableV) && !__isResizing) {
            var _mx = window_mouse_get_x(); var _my = window_mouse_get_y();
            if (device_mouse_check_button_pressed(0, mb_left) && __isMouseInResizeHandle(_mx, _my)) {
                __isResizing = true;
                __resizeStartMx = _mx; __resizeStartMy = _my;
                __resizeStartW = (__targetW != undefined) ? __targetW : __layout.width;
                __resizeStartH = (__targetH != undefined) ? __targetH : __layout.height;
            }
        }
        
        if (__isResizing) {
            if (!device_mouse_check_button(0, mb_left)) {
                __isResizing = false;
            } else {
                var _mx = window_mouse_get_x(); var _my = window_mouse_get_y();
                if (__resizableH) __targetW = max(WILLOW_MIN_WIDTH, __resizeStartW + (_mx - __resizeStartMx));
                if (__resizableV) __targetH = max(WILLOW_MIN_HEIGHT, __resizeStartH + (_my - __resizeStartMy));
                
                if (__resizableH) flexpanel_node_style_set_width(__node, __targetW, flexpanel_unit.point);
                if (__resizableV) flexpanel_node_style_set_height(__node, __targetH, flexpanel_unit.point);
                
                var _trunk = self; while (_trunk.__parent != undefined) _trunk = _trunk.__parent;
                flexpanel_calculate_layout(_trunk.getNode(), window_get_width(), window_get_height(), WILLOW_ROOT_DIR);
                _trunk.updatePosition(true);
            }
            return;
        }

        if (__eventState.hover && !mouse_check_button(mb_left)) {
            var _cur = __getCursorStyle(window_mouse_get_x(), window_mouse_get_y());
            if (window_get_cursor() != _cur) window_set_cursor(_cur);
        }

        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child)) {
                if (variable_struct_exists(_child, "step")) _child.step();
                if (variable_struct_exists(_child, "stepComponent")) _child.stepComponent();
            }
            _i++;
        }
    };

    /// @func    draw([_batched])
    /// @desc    Core rendering event for the element's shapes, sprites, and properties.
    /// @param   {Bool} [_batched]
    /// @return  {Undefined}
    static draw = function(_batched = false) {
        if (__render.scaleX == 0 || __render.scaleY == 0) return;

        var _depthPrev = gpu_get_depth();
        gpu_set_depth(__render.depth);

        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);

        var _dx = getDrawX(); var _dy = getDrawY();
        var _sz = __getRenderSize();
        
        var _hasSprite = (variable_struct_exists(__render, "sprite_index") && __render.sprite_index != -1);
        if (__render.alpha[0] > 0 || _hasSprite) {
            if (__WillowSystem().use_clean_shapes) __willow_draw_rectangle_cleanshapes(_dx, _dy, _sz.w, _sz.h, __render);
            else __willow_draw_rectangle_native(_dx, _dy, _sz.w, _sz.h, __render);
        }

        var _clip = (__maxScrollX > 0 || __maxScrollY > 0 || (variable_struct_exists(__styleDefinition.struct, "clipContent") && __styleDefinition.struct.clipContent));
        var _prevScissor = gpu_get_scissor();
        
        if (_clip && array_length(__children) > 0) {
            var _realW = _sz.w * __render.scaleX;
            var _realH = _sz.h * __render.scaleY;
            var _realX = _dx + (_sz.w - _realW) / 2;
            var _realY = _dy + (_sz.h - _realH) / 2;
            __willow_gpu_set_scissor_intersect(_realX, _realY, _realW, _realH);
        }

        if (variable_struct_exists(self, "drawComponent")) drawComponent();

        if (_matrixPushed) __willow_matrix_restore_transform();
        gpu_set_depth(_depthPrev);

        var _len = array_length(__children);
        var _i = 0; repeat(_len) {
            var _child = __children[_i];
            if (is_struct(_child)) {
                if (!(variable_struct_exists(_child, "__isOverlay") && _child.__isOverlay)) {
                    _child.draw(_batched);
                }
            }
            _i++;
        }

        if (_clip && _len > 0) gpu_set_scissor(_prevScissor);
    };

    /// @func    drawText()
    /// @desc    Pass handling text rendering and topmost UI visuals above shapes.
    /// @return  {Undefined}
    static drawText = function() {
        __layout = flexpanel_node_layout_get_position(__node, false); 
        var _numChildren = array_length(__children);
        var _depthPrev = gpu_get_depth();
        
        gpu_set_depth(__render.depth); 

        var _drawX = getDrawX();
        var _drawY = getDrawY();

        __willow_draw_scrollbars(self);
        __willow_draw_resize_handle(self);

        var _sys = __WillowSystem();
        if (_sys.debug_mode) {
            var _textCol = _sys.theme.color.base_content; 
            draw_set_colour(_textCol);
            draw_set_alpha(1);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_text(_drawX + 5, _drawY + 5, __name + " (Box #" + string(__id) + ")");
            draw_set_colour(c_white);
        }

        gpu_set_depth(_depthPrev);

        var _needsClip = (__maxScrollX > 0 || __maxScrollY > 0 || (variable_struct_exists(__styleDefinition.struct, "clipContent") && __styleDefinition.struct.clipContent));
        var _prevScissor = gpu_get_scissor();
        
        if (_needsClip && _numChildren > 0) {
            var _sz = __getRenderSize();
            var _realW = _sz.w * __render.scaleX;
            var _realH = _sz.h * __render.scaleY;
            var _realX = _drawX + (_sz.w - _realW) / 2;
            var _realY = _drawY + (_sz.h - _realH) / 2;
            __willow_gpu_set_scissor_intersect(_realX, _realY, _realW, _realH);
        }

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
        
        if (_needsClip && _numChildren > 0) gpu_set_scissor(_prevScissor);
    };
    
    #endregion

    #region INITIALIZATION EXECUTION
    
    // - SETUP STATE 
    if (is_undefined(__render.colours)) __render.colours = __willow_ensure_colour_array(__willow_generate_colour());
    __applyStyleToNode();

    #endregion
}