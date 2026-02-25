/// @ignore   Stores target styles, callbacks, and transition settings for a specific UI event.
/// @param   {Enum.WILLOW_EVENT} _eventKind The event type this block handles.
function WillowStyleTransitionBlock(_eventKind) constructor {

    #region INTERNAL PROPERTIES
    __eventKind = _eventKind;
    __styleTarget = undefined;
    __callback = undefined;

    // Default settings
    __defaultDuration = 0.2; 
    __defaultEase = function(t) { return t; };
    __defaultAnimMode = WILLOW_ANIM.ONCE;

    // Specific overrides (applied via .withTransition())
    __specificDuration = undefined;
    __specificEase = undefined;
    __specificAnimMode = undefined;
    #endregion

    #region PUBLIC METHODS
    /// @func    setAnimMode(_mode)
    /// @desc    Sets the default animation mode (ONCE, LOOP, PING_PONG) for this block.
    /// @param   {Enum.WILLOW_ANIM} _mode The animation mode.
    /// @return  {Struct.WillowStyleTransitionBlock} Self
    static setAnimMode = function(_mode) {
        __defaultAnimMode = _mode;
        return self;
    };

    /// @func    setSpecificTransition(_duration, [_ease], [_mode])
    /// @desc    Overrides default transition settings for this specific event block.
    /// @param   {Real} _duration Duration in seconds.
    /// @param   {Function} [_ease] Easing function.
    /// @param   {Enum.WILLOW_ANIM} [_mode] Animation mode.
    /// @return  {Struct.WillowStyleTransitionBlock} Self
    static setSpecificTransition = function(_duration, _ease = undefined, _mode = undefined) {
        if (_duration != undefined) __specificDuration = max(0, _duration);
        if (_ease != undefined) __specificEase = _ease;
        if (_mode != undefined) __specificAnimMode = _mode;
        return self;
    };

    /// @func    setCallback(_fn)
    /// @desc    Sets the function to execute when this event is triggered.
    /// @param   {Function} _fn The callback method.
    /// @return  {Struct.WillowStyleTransitionBlock} Self
    static setCallback = function(_fn) {
        __callback = _fn;
        return self;
    };
    
    /// @func    setStyle(_style)
    /// @desc    Sets the target style to transition toward when this event occurs.
    /// @param   {Struct.WillowStyle} _style The target style instance.
    /// @return  {Struct.WillowStyleTransitionBlock} Self
    static setStyle = function(_style) {
        if (is_instanceof(_style, WillowStyle)) {
            __styleTarget = _style;
        } else if (_style == undefined) {
            __styleTarget = undefined;
        }
        return self;
    };

    /// @func    getTargetStyle()
    /// @desc    Returns the style struct associated with this event.
    /// @return  {Struct.WillowStyle|Undefined}
    static getTargetStyle = function() {
        return __styleTarget;
    };

    /// @func    getTransitionFor(_propName)
    /// @desc    Calculates effective transition parameters, prioritizing specific overrides.
    /// @param   {String} _propName The property name (future-proofing for per-prop easing).
    /// @return  {Struct} {duration, ease, anim_mode}
    static getTransitionFor = function(_propName) {
        var _duration = (__specificDuration != undefined) ? __specificDuration : __defaultDuration;
        var _ease_fn  = (__specificEase != undefined) ? __specificEase : __defaultEase;
        var _mode     = (__specificAnimMode != undefined) ? __specificAnimMode : __defaultAnimMode;
    
        // Validation fallback
        if (!is_method(_ease_fn)) {
            _ease_fn = function(t) { return t; }; 
        }
    
        return {
            duration: _duration,
            ease: _ease_fn,
            anim_mode: _mode
        };
    };
    
    /// @func    hasStyle()
    /// @return  {Bool} True if a target style is defined.
    static hasStyle = function() {
        return (__styleTarget != undefined);
    };

    /// @func    hasCallback()
    /// @return  {Bool} True if a callback function is defined.
    static hasCallback = function() {
        return (__callback != undefined);
    };
    #endregion
}