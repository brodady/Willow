/// @func Willow()
/// @desc Creates a new Willow UI controller for creating and managing compositions, styles, and themes.
function Willow() constructor {
    var _sys = __WillowSystem();
    _sys.active_instance = self;

    #region INITIALIZATION

    // Setup Cassette for animations
    if (_sys.deck == undefined) {
        _sys.deck = new CassetteDeck(true, true);
    }

    // Public API for direct animation access
    anim = _sys.deck;
    ease = static_get(CassetteEase);

    // UI Component Constructors
    Style    = WillowStyle;
    Box      = WillowBox;
    Sprite   = WillowSprite;
    Text     = WillowText;
    TextBox  = WillowTextBox;
    Button   = WillowButton;
    DropDown = WillowDropDown;
    // TODO:
    /* CheckBox = WillowCheckBox;*/
    /* Radio    = WillowRadio;*/
    /* Slider   = WillowSlider;*/
    /* FileDrop = WillowFileDrop;*/
    /* Accordian = WillowSlider;*/
    /* Menu      = WillowMenu;*/
    
    // Setup Themes
    new WillowThemes(); 
    Themes = static_get(WillowThemes);

    // Private system state
    __boxes = [];
    __themeCallbacks = [];
    __last_hovered_box = noone;
    __win_w_mem = window_get_width();
    __win_h_mem = window_get_height();

    // Initialize the Root UI tree
    __root = new Box("root", new Style().width("100%").height("100%").alpha(0));
    __n_root = __root.getNode();

    // GPU state initialization
    gpu_set_ztestenable(true);
    gpu_set_alphatestenable(true);
    
    // Apply default theme
    setTheme(Themes.Light);
    #endregion

    #region CONFIGURATION (FLUENT API)

    /// @desc Sets the active UI theme, instantiates it if necessary, and propagates it top-down.
    static setTheme = function(_themeInput) {
        var _themeData = is_callable(_themeInput) ? new _themeInput() : _themeInput;
        
        if (!is_struct(_themeData)) {
            show_debug_message(__report + " setTheme: Invalid input. Expected Constructor or Struct.");
            return self;
        }

        var _sys = __WillowSystem();
        _sys.theme = _themeData;

        // Theme the internal root
        if (variable_struct_exists(self, "__root") && __root != undefined) {
            __propagateTheme(__root, _themeData);
        }

        // Theme the active top-level composition
        var _boxLen = array_length(__boxes);
        for (var i = 0; i < _boxLen; i++) {
            __propagateTheme(__boxes[i], _themeData);
        }

        // Trigger user-side callbacks
        var _len = array_length(__themeCallbacks);
        var _i = 0; repeat(_len) {
            __themeCallbacks[_i](_themeData);
            _i++;
        }

        // Reflow layout
        if (variable_struct_exists(self, "__n_root") && __n_root != undefined) {
            flexpanel_calculate_layout(__n_root, __win_w_mem, __win_h_mem, flexpanel_direction.LTR);
            __updateAllPositions();
        }
        
        return self;
    };
    
    static onThemeChange = function(_callback) {
        array_push(__themeCallbacks, _callback);
        return self;
    };

    static debugEnabled = function(_enable) {
        __WillowSystem().debug_mode = _enable;
        return self;
    };

    static useScribble = function(_enable) {
        __WillowSystem().use_scribble = _enable;
        return self;
    };

    static useCleanShapes = function(_enable) {
        __WillowSystem().use_clean_shapes = _enable;
        return self;
    };

    static useAntiAlias = function(_enable) {
        if (__WillowSystem().use_clean_shapes) {
            CleanAntialiasSet(_enable); 
        } else {
            show_debug_message("{0} ERROR: CleanShapes not enabled. Call .useCleanShapes(true) first.", __willow_get_report_tag());
        }
        return self;
    };
    #endregion

    #region THEME PROPAGATION (INTERNAL)
    static __propagateTheme = function(_box, _theme) {
        if (!is_struct(_box)) return;
        
        if (variable_struct_exists(_box, "__children")) {
            var _len = array_length(_box.__children);
            for (var i = 0; i < _len; i++) {
                __propagateTheme(_box.__children[i], _theme);
            }
        }

        if (variable_struct_exists(_box, "__applyTheme") && is_callable(_box.__applyTheme)) {
            _box.__applyTheme(_theme);
        }
    };
    #endregion

    #region CORE LOOP
    /// @desc Updates logic, handles responsive resizing, and input dispatching.
    static step = function() {
        if (!window_has_focus()) return;
        
        // Responsive Resizing Check
        var _win_w = window_get_width();
        var _win_h = window_get_height();
        if ((_win_w != __win_w_mem || _win_h != __win_h_mem) && _win_w > 0) {
            __win_w_mem = _win_w;
            __win_h_mem = _win_h;
            flexpanel_calculate_layout(__n_root, _win_w, _win_h, flexpanel_direction.LTR);
            display_set_gui_size(_win_w, _win_h);
            __updateAllPositions();
        }

        // Input Dispatching
        var _mouse_x = window_mouse_get_x();
        var _mouse_y = window_mouse_get_y();
        var _hovered = __willow_get_top_box(__boxes, _mouse_x, _mouse_y);

        if (_hovered != __last_hovered_box) {
            if (__last_hovered_box != noone) __last_hovered_box.__handleEvent(WILLOW_EVENT.leave);
            if (_hovered != noone) _hovered.__handleEvent(WILLOW_EVENT.enter);
            __last_hovered_box = _hovered;
        }

        if (_hovered != noone) {
            _hovered.__handleEvent(WILLOW_EVENT.hover);
            if (device_mouse_check_button_pressed(0, mb_left)) {
                _hovered.__handleEvent(WILLOW_EVENT.click);
            }
            if (device_mouse_check_button_pressed(0, mb_right)) {
                _hovered.__handleEvent(WILLOW_EVENT.rightClick);
            }
            
            if (mouse_wheel_up()) _hovered.__handleEvent(WILLOW_EVENT.scrollUp);
            if (mouse_wheel_down()) _hovered.__handleEvent(WILLOW_EVENT.scrollDown);
        }

        // Execute Root Logic
        __root.step();

        // FLAT STEP EXECUTION
        var _len = array_length(__boxes);
        for (var i = 0; i < _len; i++) {
            var _box = __boxes[i];
            if (is_struct(_box)) {
                if (variable_struct_exists(_box, "step")) _box.step();
                if (variable_struct_exists(_box, "stepComponent")) _box.stepComponent();
            }
        }
    };
    
    /// @desc Renders the UI hierarchy. Call once per Draw GUI event.
    static draw = function() {
        var _sys = __WillowSystem();
        
        // Setup UI Surface
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();
        
        if (!surface_exists(_sys.ui_surface)) {
            _sys.ui_surface = surface_create(_gw, _gh);
        } else if (surface_get_width(_sys.ui_surface) != _gw || surface_get_height(_sys.ui_surface) != _gh) {
            surface_resize(_sys.ui_surface, round(_gw), round(_gh));
        }
        
        surface_set_target(_sys.ui_surface);
        
        // Clear Color and Stencil Buffers
        draw_clear_alpha(c_black, 0);
        draw_clear_stencil(0);
        
        // Disable Depth Testing and Writing. 
        // This prevents PASS 2 masks from being rejected by PASS 1 backgrounds sharing the same Z-depth.
        var _depth_prev = gpu_get_depth();
        var _ztest_prev = gpu_get_ztestenable();
        var _zwrite_prev = gpu_get_zwriteenable();
        gpu_set_ztestenable(false);
        gpu_set_zwriteenable(false);
        
        var _prev_cp = draw_get_circle_precision();
        draw_set_circle_precision(WILLOW_CIRC_RES);
    
        var _len = array_length(__boxes);
    
        // PASS 1: Standard background and component pass
        for (var i = 0; i < _len; i++) {
            var _box = __boxes[i];
            if (is_struct(_box) && variable_struct_exists(_box, "draw")) {
                _box.draw(_sys.use_clean_shapes);
            }
        }
        
        // PASS 2: Text and UI accessory pass
        for (var i = 0; i < _len; i++) {
            var _box = __boxes[i];
            if (is_struct(_box) && variable_struct_exists(_box, "drawText")) {
                _box.drawText();
            }
        }
    
        // PASS 3: Overlay pass for high-depth elements (Modals, Dropdowns)
        var _ol = _sys.overlays;
        var _ol_len = array_length(_ol);
        for (var i = 0; i < _ol_len; i++) {
            var _item = _ol[i];
            if (is_struct(_item)) {
                if (variable_struct_exists(_item, "draw")) _item.draw(_sys.use_clean_shapes);
                if (variable_struct_exists(_item, "drawText")) _item.drawText();
            }
        }
    
        // Restore GPU State
        gpu_set_depth(_depth_prev);
        gpu_set_ztestenable(_ztest_prev);
        gpu_set_zwriteenable(_zwrite_prev);
        draw_set_circle_precision(_prev_cp);
        surface_reset_target();
        
        // Draw UI Surface using premultiplied alpha rules to prevent glowing halos
        gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
        draw_surface(_sys.ui_surface, 0, 0);
        gpu_set_blendmode(bm_normal);
    };

    static destroy = function() {
        __WillowSystem().deck.destroy();
        flexpanel_delete_node(__n_root);
    };
    #endregion

    #region UTILITIES & STRUCTURE
    static compose = function(_input_array) {
        __boxes = is_array(_input_array) ? _input_array : [_input_array];
        flexpanel_node_remove_all_children(__n_root);

        var _sys = __WillowSystem();
        var _len = array_length(__boxes);
        
        for (var i = 0; i < _len; i++) {
            var _box = __boxes[i];
            if (is_struct(_box)) {
                if (variable_struct_exists(_box, "getNode")) {
                    flexpanel_node_insert_child(__n_root, _box.getNode(), i);
                }
                __propagateTheme(_box, _sys.theme);
            }
        }

        flexpanel_calculate_layout(__n_root, __win_w_mem, __win_h_mem, WILLOW_ROOT_DIR);
        __updateAllPositions();
        return self;
    };

    static __updateAllPositions = function() {
        var _len = array_length(__boxes);
        var _i = 0; repeat(_len) {
            if (variable_struct_exists(__boxes[_i], "updatePosition")) {
                __boxes[_i].updatePosition(true);
            }
            _i++;
        }
    };
    #endregion
}