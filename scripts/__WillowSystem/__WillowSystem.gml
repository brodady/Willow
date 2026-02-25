/// @ignore Internal state management for the Willow UI library.
/// @desc Encapsulates all library-wide data within a persistent static struct.
function __WillowSystem() {
#region INTERNAL SYSTEM DATA
    static _data = {
        active_instance: noone,
        deck: undefined,
        theme: undefined,
        overlays: [],
        ui_surface: undefined,
        use_clean_shapes: false,
        use_scribble: false,
        debug_mode: false,
        drag_threshold: 10,
        default_font: fnt_willow_arial
    };
    return _data;
}
#endregion

#region MACROS
#macro WILLOW_VERSION "0.1.0"

// --  Willow Defaults
#macro WILLOW_BOX_EVENTS 10
#macro WILLOW_DRAG_THRESHOLD 10
#macro WILLOW_CIRC_RES 32
#macro WILLOW_ROOT_DIR flexpanel_direction.LTR

// --  Interaction Constants
#macro WILLOW_DOUBLE_CLICK_TIME 300
#macro WILLOW_SCROLL_SPEED 30
#macro WILLOW_DEPTH_STEP 10
#macro WILLOW_OVERLAY_DEPTH -10000

// --  Component Constants
#macro WILLOW_MIN_WIDTH 50
#macro WILLOW_MIN_HEIGHT 30
#macro WILLOW_RESIZE_HANDLE_SIZE 16
#macro WILLOW_RESIZE_GUTTER 4
#macro WILLOW_ROUNDING_INSET_FACTOR 0.3

// -- ANIMATION DEFAULTS
#macro WILLOW_DEFAULT_DURATION 0.2
#endregion

#region ENUMS
enum WILLOW_EVENT {
    hover, click, doubleClick, rightClick, middleClick,
    scrollUp, scrollDown, drag, enter, leave
}

enum WILLOW_ANIM {
    ONCE, LOOP, PING_PONG,
}

enum WILLOW_MOD {
    xs, sm, md, lg, xl, wide, block, square, circle
}

enum WILLOW_SELECT_MODE {
    REGULAR,
    WORD,
    LINE
}
#endregion