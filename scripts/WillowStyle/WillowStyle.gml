/// @func    WillowStyle()
/// @desc    Creates a new Willow Styling engine for layout and rendering properties.
function WillowStyle() constructor {
    var _sys = __WillowSystem();
    
    #region INTERNAL VARIABLES
    
    /// @ignore Internal layout properties used for flexpanel calculations.
    struct = { 
        width: "auto",
        height: "auto",
        display: flexpanel_display.flex,
        left: 0, right: 0, top: 0, bottom: 0,
        clipContent: true
    };

    /// @ignore Internal rendering properties used by the drawing engine.
    render = {
        // Transformations
        alpha: [1, 1, 1, 1],
        offsetX: 0, offsetY: 0,
        scaleX: 1, scaleY: 1,
        rotationX: 0, rotationY: 0, rotationZ: 0,
        depth: 0,

        // Visuals
        colours: [c_white, c_white, c_white, c_white],
        rounding: 0,
        blend_mode: bm_normal,
        
        // Borders & Outlines
        borderWidth: 0,
        borderColours: [c_white, c_white, c_white, c_white],
        borderAlpha: [1, 1, 1, 1],
        
        // Accessory Visuals (Selection & Handles)
        outline_colour: c_white,
        outline_alpha: 1,
        select_colour: c_white,
        select_alpha: 0.4,
        handle_colour: c_white,
        handle_alpha: 1,

        // Sprites
        sprite_index: -1,
        image_index: 0,
        image_speed: 0,
        sprite_draw_mode: 1,
        sprite_blend_mode: bm_normal,
        sprite_colour: c_white,

        // Text Defaults
        text_font: _sys.default_font,
        text_colour: c_white,
        text_alpha: 1,
        text_size: 1,
        textAlignH: fa_left,
        textAlignV: fa_top,
        
        transition_duration: WILLOW_DEFAULT_DURATION
    };

    __owner_box = undefined;
    
    #endregion
    
    #region STYLE MODIFIERS (EASY TEMPLATING)
    
    /// @func    modifiers(_modifiers)
    /// @desc    Applies predefined theme modifiers to the style.
    /// @param   {Enum.WILLOW_MOD, Array<Enum.WILLOW_MOD>} _modifiers
    /// @return  {Struct.WillowStyle} self
    static modifiers = function(_modifiers) {
        var _theme = __WillowSystem().theme;
        if (!is_array(_modifiers)) _modifiers = [_modifiers];
        
        var _len = array_length(_modifiers);
        var _i = 0; repeat(_len) {
            switch (_modifiers[_i]) {
                case WILLOW_MOD.xs: height(_theme.size.xs); padding(0, _theme.size.pad_xs); break;
                case WILLOW_MOD.sm: height(_theme.size.sm); padding(0, _theme.size.pad_sm); break;
                case WILLOW_MOD.md: height(_theme.size.md); padding(0, _theme.size.pad_md); break;
                case WILLOW_MOD.lg: height(_theme.size.lg); padding(0, _theme.size.pad_lg); break;
                case WILLOW_MOD.xl: height(_theme.size.xl); padding(0, _theme.size.pad_lg * 1.5); break;
                case WILLOW_MOD.block: width("100%"); break;
                case WILLOW_MOD.square:
                    var _h = is_numeric(struct.height) ? struct.height : _theme.size.md;
                    width(_h).height(_h).padding(0);
                    break;
                case WILLOW_MOD.circle:
                    var _h2 = is_numeric(struct.height) ? struct.height : _theme.size.md;
                    width(_h2).height(_h2).padding(0).rounding(9999);
                    break;
            }
            _i++;
        }
        return self;
    };
    
    #endregion
    
    #region SIZING & LAYOUT
    
    /// @func    width(_val)
    /// @desc    Sets the width of the element.
    /// @param   {Real, String} _val
    /// @return  {Struct.WillowStyle} self
    static width = function(_val) { 
        struct.width = _val; 
        if (is_numeric(_val)) render.width = _val; 
        return self; 
    };

    /// @func    height(_val)
    /// @desc    Sets the height of the element.
    /// @param   {Real, String} _val
    /// @return  {Struct.WillowStyle} self
    static height = function(_val) { 
        struct.height = _val; 
        if (is_numeric(_val)) render.height = _val; 
        return self; 
    };

    /// @func    minWidth(_val)
    /// @desc    Sets the minimum width constraint.
    /// @param   {Real, String} _val
    /// @return  {Struct.WillowStyle} self
    static minWidth = function(_val)  { struct.minWidth = _val; return self; };

    /// @func    maxWidth(_val)
    /// @desc    Sets the maximum width constraint.
    /// @param   {Real, String} _val
    /// @return  {Struct.WillowStyle} self
    static maxWidth = function(_val)  { struct.maxWidth = _val; return self; };

    /// @func    minHeight(_val)
    /// @desc    Sets the minimum height constraint.
    /// @param   {Real, String} _val
    /// @return  {Struct.WillowStyle} self
    static minHeight = function(_val) { struct.minHeight = _val; return self; };

    /// @func    maxHeight(_val)
    /// @desc    Sets the maximum height constraint.
    /// @param   {Real, String} _val
    /// @return  {Struct.WillowStyle} self
    static maxHeight = function(_val) { struct.maxHeight = _val; return self; };

    /// @func    aspectRatio(_ratio)
    /// @desc    Sets the aspect ratio (width / height) for layout.
    /// @param   {Real} _ratio
    /// @return  {Struct.WillowStyle} self
    static aspectRatio = function(_ratio) { struct.aspectRatio = _ratio; return self; };

    /// @func    flex([_f])
    /// @desc    Sets shorthand for flex-grow, flex-shrink, and flex-basis.
    /// @param   {Real} [_f]
    /// @return  {Struct.WillowStyle} self
    static flex = function(_f = 1) { struct.flex = _f; return self; };

    /// @func    flexDirection([_dir])
    /// @desc    Sets the main axis direction for children.
    /// @param   {String} [_dir]
    /// @return  {Struct.WillowStyle} self
    static flexDirection = function(_dir = "column") { struct.flexDirection = _dir; return self; };

    /// @func    justifyContent([_j])
    /// @desc    Aligns children along the main axis.
    /// @param   {String} [_j]
    /// @return  {Struct.WillowStyle} self
    static justifyContent = function(_j = "flex-start") { struct.justifyContent = _j; return self; };

    /// @func    alignItems([_a])
    /// @desc    Aligns children along the cross axis.
    /// @param   {String} [_a]
    /// @return  {Struct.WillowStyle} self
    static alignItems = function(_a = "stretch") { struct.alignItems = _a; return self; };

    /// @func    positionType([_p])
    /// @desc    Sets the layout positioning mode.
    /// @param   {String} [_p]
    /// @return  {Struct.WillowStyle} self
    static positionType = function(_p = "relative") { struct.positionType = _p; return self; };

    /// @func    inset(_l, [_t], [_r], [_b])
    /// @desc    Sets absolute positioning offsets mapping safely across 1 to 4 elements.
    /// @param   {Real, Array} _l
    /// @param   {Real} [_t]
    /// @param   {Real} [_r]
    /// @param   {Real} [_b]
    /// @return  {Struct.WillowStyle} self
    static inset = function(_l = 0, _t = undefined, _r = undefined, _b = undefined) {
        if (is_array(_l)) {
            var _len = array_length(_l);
            if (_len > 0) {
                struct.left = _l[0];
                struct.top = _len > 1 ? _l[1] : struct.left;
                struct.right = _len > 2 ? _l[2] : struct.left;
                struct.bottom = _len > 3 ? _l[3] : struct.top;
            }
        } else {
            struct.left = _l; 
            struct.top = _t ?? _l; 
            struct.right = _r ?? _l; 
            struct.bottom = _b ?? (_t ?? _l);
        }
        return self;
    };

    /// @func    clipContents([_enabled])
    /// @desc    Toggles hardware scissor clipping for this box.
    /// @param   {Bool} [_enabled]
    /// @return  {Struct.WillowStyle} self
    static clipContents = function(_enabled = true) { struct.clipContent = _enabled; return self; };

    #endregion
    
    #region SPACING (PADDING & MARGIN)
    
    /// @func    padding(_p1, [_p2], [_p3], [_p4])
    /// @desc    Sets the inner padding cascading 1 to 4 variables CSS style.
    /// @param   {Real, Array} _p1
    /// @param   {Real} [_p2]
    /// @param   {Real} [_p3]
    /// @param   {Real} [_p4]
    /// @return  {Struct.WillowStyle} self
    static padding = function(_p1 = 0, _p2 = undefined, _p3 = undefined, _p4 = undefined) {
        if (is_array(_p1)) {
            var _len = array_length(_p1);
            if (_len > 0) {
                struct.paddingTop = _p1[0];
                struct.paddingRight = _len > 1 ? _p1[1] : struct.paddingTop;
                struct.paddingBottom = _len > 2 ? _p1[2] : struct.paddingTop;
                struct.paddingLeft = _len > 3 ? _p1[3] : struct.paddingRight;
            }
        } else {
            struct.paddingTop = _p1;
            struct.paddingRight = _p2 ?? _p1;
            struct.paddingBottom = _p3 ?? _p1;
            struct.paddingLeft = _p4 ?? (_p2 ?? _p1);
        }
        
        if (__owner_box != undefined && variable_struct_exists(__owner_box, "__node")) {
            var _n = __owner_box.__node;
            flexpanel_node_style_set_padding(_n, flexpanel_edge.top, struct.paddingTop, flexpanel_unit.point);
            flexpanel_node_style_set_padding(_n, flexpanel_edge.right, struct.paddingRight, flexpanel_unit.point);
            flexpanel_node_style_set_padding(_n, flexpanel_edge.bottom, struct.paddingBottom, flexpanel_unit.point);
            flexpanel_node_style_set_padding(_n, flexpanel_edge.left, struct.paddingLeft, flexpanel_unit.point);
        }
        return self;
    };

    /// @func    margin(_m1, [_m2], [_m3], [_m4])
    /// @desc    Sets the outer margin cascading 1 to 4 variables CSS style.
    /// @param   {Real, Array} _m1
    /// @param   {Real} [_m2]
    /// @param   {Real} [_m3]
    /// @param   {Real} [_m4]
    /// @return  {Struct.WillowStyle} self
    static margin = function(_m1 = 0, _m2 = undefined, _m3 = undefined, _m4 = undefined) {
        if (is_array(_m1)) {
            var _len = array_length(_m1);
            if (_len > 0) {
                struct.marginTop = _m1[0];
                struct.marginRight = _len > 1 ? _m1[1] : struct.marginTop;
                struct.marginBottom = _len > 2 ? _m1[2] : struct.marginTop;
                struct.marginLeft = _len > 3 ? _m1[3] : struct.marginRight;
            }
        } else {
            struct.marginTop = _m1;
            struct.marginRight = _m2 ?? _m1;
            struct.marginBottom = _m3 ?? _m1;
            struct.marginLeft = _m4 ?? (_m2 ?? _m1);
        }
        
        if (__owner_box != undefined && variable_struct_exists(__owner_box, "__node")) {
            var _n = __owner_box.__node;
            flexpanel_node_style_set_margin(_n, flexpanel_edge.top, struct.marginTop, flexpanel_unit.point);
            flexpanel_node_style_set_margin(_n, flexpanel_edge.right, struct.marginRight, flexpanel_unit.point);
            flexpanel_node_style_set_margin(_n, flexpanel_edge.bottom, struct.marginBottom, flexpanel_unit.point);
            flexpanel_node_style_set_margin(_n, flexpanel_edge.left, struct.marginLeft, flexpanel_unit.point);
        }
        return self;
    };

    /// @func    spacing([_p], [_m])
    /// @desc    Shorthand to set both padding and margin simultaneously.
    /// @param   {Real} [_p]
    /// @param   {Real} [_m]
    /// @return  {Struct.WillowStyle} self
    static spacing = function(_p = 0, _m = 0) { return padding(_p).margin(_m); };
    
    #endregion
    
    #region TRANSFORMS & RENDERING
    
    /// @func    offset([_x], [_y])
    /// @desc    Sets the rendering offset translation.
    /// @param   {Real, Array} [_x]
    /// @param   {Real} [_y]
    /// @return  {Struct.WillowStyle} self
    static offset = function(_x = 0, _y = undefined) { 
        if (is_array(_x)) {
            var _len = array_length(_x);
            if (_len > 0) {
                render.offsetX = _x[0]; 
                render.offsetY = _len > 1 ? _x[1] : _x[0];
            }
        } else {
            render.offsetX = _x; 
            render.offsetY = _y ?? _x; 
        }
        return self; 
    };

    /// @func    scale([_x], [_y])
    /// @desc    Sets the rendering scale.
    /// @param   {Real, Array} [_x]
    /// @param   {Real} [_y]
    /// @return  {Struct.WillowStyle} self
    static scale = function(_x = 1, _y = undefined) { 
        if (is_array(_x)) {
            var _len = array_length(_x);
            if (_len > 0) {
                render.scaleX = _x[0]; 
                render.scaleY = _len > 1 ? _x[1] : _x[0];
            }
        } else {
            render.scaleX = _x; 
            render.scaleY = _y ?? _x; 
        }
        return self; 
    };

    /// @func    rotate(_angle)
    /// @desc    Sets the Z-axis rotation angle.
    /// @param   {Real} _angle
    /// @return  {Struct.WillowStyle} self
    static rotate = function(_angle) { render.rotationZ = _angle; return self; };

    /// @func    rotate3d(_x, _y, _z)
    /// @desc    Sets 3D rotation across all axes.
    /// @param   {Real} _x
    /// @param   {Real} _y
    /// @param   {Real} _z
    /// @return  {Struct.WillowStyle} self
    static rotate3d = function(_x, _y, _z) { render.rotationX = _x; render.rotationY = _y; render.rotationZ = _z; return self; };

    /// @func    depth(_d)
    /// @desc    Sets the rendering depth/z-index.
    /// @param   {Real} _d
    /// @return  {Struct.WillowStyle} self
    static depth = function(_d) { render.depth = _d; return self; };

    /// @func    alpha(_a1, [_a2], [_a3], [_a4])
    /// @desc    Sets vertex alpha, automatically expanding single inputs and clamping bounds.
    /// @param   {Real, Array} _a1
    /// @param   {Real} [_a2]
    /// @param   {Real} [_a3]
    /// @param   {Real} [_a4]
    /// @return  {Struct.WillowStyle} self
    static alpha = function(_a1, _a2 = undefined, _a3 = undefined, _a4 = undefined) {
        if (is_array(_a1)) {
            var _len = array_length(_a1);
            if (_len > 0) {
                var _v1 = clamp(_a1[0], 0, 1);
                var _v2 = _len > 1 ? clamp(_a1[1], 0, 1) : _v1;
                var _v3 = _len > 2 ? clamp(_a1[2], 0, 1) : _v1;
                var _v4 = _len > 3 ? clamp(_a1[3], 0, 1) : _v2;
                render.alpha = [_v1, _v2, _v3, _v4];
            }
        } else {
            var _v1 = clamp(_a1, 0, 1);
            var _v2 = _a2 != undefined ? clamp(_a2, 0, 1) : _v1;
            var _v3 = _a3 != undefined ? clamp(_a3, 0, 1) : _v1;
            var _v4 = _a4 != undefined ? clamp(_a4, 0, 1) : _v2;
            render.alpha = [_v1, _v2, _v3, _v4];
        }
        return self;
    };

    /// @func    colour(_c1, [_c2], [_c3], [_c4])
    /// @desc    Sets the background colour, automatically expanding single inputs across 4 corners.
    /// @param   {Constant.Color, Array} _c1
    /// @param   {Constant.Color} [_c2]
    /// @param   {Constant.Color} [_c3]
    /// @param   {Constant.Color} [_c4]
    /// @return  {Struct.WillowStyle} self
    static colour = function(_c1, _c2 = undefined, _c3 = undefined, _c4 = undefined) {
        if (is_array(_c1)) {
            var _len = array_length(_c1);
            if (_len > 0) {
                var _v1 = _c1[0];
                var _v2 = _len > 1 ? _c1[1] : _v1;
                var _v3 = _len > 2 ? _c1[2] : _v1;
                var _v4 = _len > 3 ? _c1[3] : _v2;
                render.colours = [_v1, _v2, _v3, _v4];
            }
        } else {
            var _v1 = _c1;
            var _v2 = _c2 ?? _v1;
            var _v3 = _c3 ?? _v1;
            var _v4 = _c4 ?? _v2;
            render.colours = [_v1, _v2, _v3, _v4];
        }
        return self;
    };
    static color = colour;

    /// @func    outlineWidth(_w)
    /// @desc    Sets the width of the element border.
    /// @param   {Real} _w
    /// @return  {Struct.WillowStyle} self
    static outlineWidth = function(_w) { render.borderWidth = _w; return self; };

    /// @func    outlineColour(_c1, [_c2], [_c3], [_c4])
    /// @desc    Sets the border colour scaling across corners.
    /// @param   {Constant.Color, Array} _c1
    /// @param   {Constant.Color} [_c2]
    /// @param   {Constant.Color} [_c3]
    /// @param   {Constant.Color} [_c4]
    /// @return  {Struct.WillowStyle} self
    static outlineColour = function(_c1, _c2 = undefined, _c3 = undefined, _c4 = undefined) {
        if (is_array(_c1)) {
            var _len = array_length(_c1);
            if (_len > 0) {
                var _v1 = _c1[0];
                var _v2 = _len > 1 ? _c1[1] : _v1;
                var _v3 = _len > 2 ? _c1[2] : _v1;
                var _v4 = _len > 3 ? _c1[3] : _v2;
                render.borderColours = [_v1, _v2, _v3, _v4];
            }
        } else {
            var _v1 = _c1;
            var _v2 = _c2 ?? _v1;
            var _v3 = _c3 ?? _v1;
            var _v4 = _c4 ?? _v2;
            render.borderColours = [_v1, _v2, _v3, _v4];
        }
        return self;
    };
    static outlineColor = outlineColour;

    /// @func    outlineAlpha(_a1, [_a2], [_a3], [_a4])
    /// @desc    Sets the transparency of the border across corners.
    /// @param   {Real, Array} _a1
    /// @param   {Real} [_a2]
    /// @param   {Real} [_a3]
    /// @param   {Real} [_a4]
    /// @return  {Struct.WillowStyle} self
    static outlineAlpha = function(_a1, _a2 = undefined, _a3 = undefined, _a4 = undefined) {
        if (is_array(_a1)) {
            var _len = array_length(_a1);
            if (_len > 0) {
                var _v1 = clamp(_a1[0], 0, 1);
                var _v2 = _len > 1 ? clamp(_a1[1], 0, 1) : _v1;
                var _v3 = _len > 2 ? clamp(_a1[2], 0, 1) : _v1;
                var _v4 = _len > 3 ? clamp(_a1[3], 0, 1) : _v2;
                render.borderAlpha = [_v1, _v2, _v3, _v4];
            }
        } else {
            var _v1 = clamp(_a1, 0, 1);
            var _v2 = _a2 != undefined ? clamp(_a2, 0, 1) : _v1;
            var _v3 = _a3 != undefined ? clamp(_a3, 0, 1) : _v1;
            var _v4 = _a4 != undefined ? clamp(_a4, 0, 1) : _v2;
            render.borderAlpha = [_v1, _v2, _v3, _v4];
        }
        return self;
    };

    /// @func    selectColour(_c)
    /// @desc    Sets the colour used for selection highlights.
    /// @param   {Constant.Color} _c
    /// @return  {Struct.WillowStyle} self
    static selectColour = function(_c) { render.select_colour = _c; return self; };
    static selectColor = selectColour;

    /// @func    selectAlpha(_a)
    /// @desc    Sets the alpha transparency for selection highlights.
    /// @param   {Real} _a
    /// @return  {Struct.WillowStyle} self
    static selectAlpha = function(_a) { render.select_alpha = _a; return self; };

    /// @func    handleColour(_c)
    /// @desc    Sets the colour for UI handles/accessories.
    /// @param   {Constant.Color} _c
    /// @return  {Struct.WillowStyle} self
    static handleColour = function(_c) { render.handle_colour = _c; return self; };
    static handleColor = handleColour;

    /// @func    handleAlpha(_a)
    /// @desc    Sets the alpha transparency for UI handles.
    /// @param   {Real} _a
    /// @return  {Struct.WillowStyle} self
    static handleAlpha = function(_a) { render.handle_alpha = _a; return self; };

    /// @func    blend(_bm)
    /// @desc    Sets the GPU blend mode for this element.
    /// @param   {Constant.BlendMode} _bm
    /// @return  {Struct.WillowStyle} self
    static blend = function(_bm) { render.blend_mode = _bm; return self; };

    /// @func    rounding(_r)
    /// @desc    Sets the corner rounding radius.
    /// @param   {Real} _r
    /// @return  {Struct.WillowStyle} self
    static rounding = function(_r) { render.rounding = max(0, _r); return self; };
    
    #endregion

    #region SPRITES
    
    /// @func    sprite(_spr, [_index], [_speed])
    /// @desc    Assigns a background sprite to the element.
    /// @param   {Asset.GMSprite} _spr
    /// @param   {Real} [_index]
    /// @param   {Real} [_speed]
    /// @return  {Struct.WillowStyle} self
    static sprite = function(_spr, _index = 0, _speed = 0) {
        render.sprite_index = _spr; 
        render.image_index = _index; 
        render.image_speed = _speed;
        return self;
    };

    /// @func    spriteDrawMode(_mode)
    /// @desc    Sets the scaling/tiling mode for the assigned sprite.
    /// @param   {Real} _mode
    /// @return  {Struct.WillowStyle} self
    static spriteDrawMode = function(_mode) { render.sprite_draw_mode = _mode; return self; };

    /// @func    spriteTint(_colour)
    /// @desc    Sets the blend colour for the background sprite.
    /// @param   {Constant.Color} _colour
    /// @return  {Struct.WillowStyle} self
    static spriteTint = function(_colour) { render.sprite_colour = _colour; return self; };
    
    #endregion
    
    #region TEXT
    
    /// @func    textAlignH([_a])
    /// @desc    Sets the horizontal text alignment.
    /// @param   {Constant.HAlign} [_a]
    /// @return  {Struct.WillowStyle} self
    static textAlignH = function(_a = fa_left) { render.textAlignH = _a; return self; };

    /// @func    textAlignV([_a])
    /// @desc    Sets the vertical text alignment.
    /// @param   {Constant.VAlign} [_a]
    /// @return  {Struct.WillowStyle} self
    static textAlignV = function(_a = fa_middle) { render.textAlignV = _a; return self; };

    /// @func    textSize(_s)
    /// @desc    Sets the text scale factor.
    /// @param   {Real} _s
    /// @return  {Struct.WillowStyle} self
    static textSize = function(_s) { render.text_size = _s; return self; };

    /// @func    textColour(_c)
    /// @desc    Sets the primary text colour.
    /// @param   {Constant.Color} _c
    /// @return  {Struct.WillowStyle} self
    static textColour = function(_c) { render.text_colour = _c; return self; };
    static textColor = textColour;

    /// @func    textAlpha(_a)
    /// @desc    Sets the transparency of text elements.
    /// @param   {Real} _a
    /// @return  {Struct.WillowStyle} self
    static textAlpha = function(_a) { render.text_alpha = _a; return self; };

    /// @func    textFont(_f)
    /// @desc    Sets the font asset for text rendering.
    /// @param   {Asset.GMFont} _f
    /// @return  {Struct.WillowStyle} self
    static textFont = function(_f) { render.text_font = _f; return self; };
    
    #endregion
    
    #region ANIMATION
    
    /// @func    transition(_dur)
    /// @desc    Sets the default transition duration for style property interpolations.
    /// @param   {Real} _dur
    /// @return  {Struct.WillowStyle} self
    static transition = function(_dur) { render.transition_duration = _dur; return self; };
    
    #endregion
    
    #region UTILITIES
    
    /// @func    clone()
    /// @desc    Creates a deep copy of the current style object.
    /// @return  {Struct.WillowStyle}
    static clone = function() {
        var _new = new WillowStyle();
        _new.struct = variable_clone(self.struct);
        _new.render = variable_clone(self.render);
        return _new;
    };
    
    /// @func    toFlexStruct()
    /// @desc    Returns the internal struct used for flexbox layout.
    /// @return  {Struct}
    static toFlexStruct = function() { return struct; };

    /// @func    toRenderStruct()
    /// @desc    Returns the internal struct used for visual rendering.
    /// @return  {Struct}
    static toRenderStruct = function() { return render; };
    
    #endregion
}