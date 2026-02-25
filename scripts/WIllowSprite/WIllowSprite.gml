/// @func    WillowSprite(_name, _sprite, [_style])
/// @desc    A convenience component for displaying a sprite within the Willow layout system.
/// @param   {String} _name
/// @param   {Asset.GMSprite} _sprite
/// @param   {Struct.WillowStyle} [_style]
/// @return  {Struct.WillowSprite} self
function WillowSprite(_name, _sprite, _style = new WillowStyle()) : WillowBox(_name, _style) constructor {
    
    #region INITIALIZATION

    // - STYLE CONFIGURATION
    // Set alpha(0) to make the base box transparent
    __styleDefinition
        .sprite(_sprite)
        .alpha(0); 

    // - DIMENSION SYNC
    if (__styleDefinition.toFlexStruct().width == "auto") {
        var _sw = sprite_get_width(_sprite);
        __styleDefinition.width(_sw);
        flexpanel_node_style_set_width(__node, _sw, flexpanel_unit.point);
    }
    
    if (__styleDefinition.toFlexStruct().height == "auto") {
        var _sh = sprite_get_height(_sprite);
        __styleDefinition.height(_sh);
        flexpanel_node_style_set_height(__node, _sh, flexpanel_unit.point);
    }

    __render = __styleDefinition.toRenderStruct();

    // Ensure sprite reference variables exist for the internal renderer
    if (!variable_struct_exists(__render, "sprite_index")) __render.sprite_index = _sprite;
    if (!variable_struct_exists(__render, "image_index")) __render.image_index = 0;
    if (!variable_struct_exists(__render, "image_speed")) __render.image_speed = 1;

    #endregion

    #region PUBLIC API
    
    /// @func    setFrame(_index)
    /// @desc    Sets the current image index (frame) of the sprite.
    /// @param   {Real} _index
    /// @return  {Struct.WillowSprite} self
    static setFrame = function(_index) {
        __render.image_index = _index;
        return self;
    };

    /// @func    setAnimationSpeed(_speed)
    /// @desc    Sets the animation speed for the sprite.
    /// @param   {Real} _speed
    /// @return  {Struct.WillowSprite} self
    static setAnimationSpeed = function(_speed) {
        __render.image_speed = _speed;
        return self;
    };

    /// @func    setTint(_colour)
    /// @desc    Applies a colour tint to the sprite.
    /// @param   {Real} _colour
    /// @return  {Struct.WillowSprite} self
    static setTint = function(_colour) {
        __render.sprite_colour = _colour;
        return self;
    };

    #endregion
    
    #region SYSTEM HOOKS
    
    /// @ignore 
    static stepComponent = function() {
        if (__render.sprite_index != -1 && sprite_exists(__render.sprite_index)) {
            var _frames = sprite_get_number(__render.sprite_index);

            // Manual frame accumulation to mimic native instance animation
            if (_frames > 1) {
                __render.image_index += __render.image_speed;
                
                if (__render.image_index >= _frames) {
                    __render.image_index -= _frames;
                } else if (__render.image_index < 0) {
                    __render.image_index += _frames;
                }
            }
        }
    };

    /// @ignore 
    static draw = function(_batched = false) {
        if (__render.scaleX == 0 || __render.scaleY == 0) return;
        
        var _depthPrev = gpu_get_depth();
        gpu_set_depth(__render.depth);
        
        var _matrixPushed = __willow_matrix_apply_transform(__render, __layout);
        
        // Render only the explicit sprite data, bypassing the standard background rectangle
        var _drawX = getDrawX() + (__layout.width / 2);
        var _drawY = getDrawY() + (__layout.height / 2);
        
        if (__render.sprite_index != -1 && sprite_exists(__render.sprite_index)) {
            var _c = variable_struct_exists(__render, "sprite_colour") ? __render.sprite_colour : __render.colours[0];
            draw_sprite_ext(__render.sprite_index, __render.image_index, _drawX, _drawY, __render.scaleX, __render.scaleY, __render.rotation, _c, __render.alpha[0]);
        }
        
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
    
    #endregion
}