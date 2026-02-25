/// @ignore    Calculates and pushes a transformation matrix to the stack based on render properties.
/// @param   {Struct} _render The rendering property struct from WillowStyle.
/// @param   {Struct} _layout The layout property struct (left, top, width, height).
/// @return  {Bool} True if a matrix was pushed to the stack.
function __willow_matrix_apply_transform(_render, _layout) {
    var _needsTransform = (_render.scaleX != 1 || _render.scaleY != 1 ||
                           _render.rotationX != 0 || _render.rotationY != 0 || _render.rotationZ != 0 ||
                           _render.offsetX != 0 || _render.offsetY != 0);

    if (_needsTransform) {
        var _baseX = _layout.left + _render.offsetX;
        var _baseY = _layout.top + _render.offsetY;
        var _centerX = _baseX + _layout.width * 0.5;
        var _centerY = _baseY + _layout.height * 0.5;

        var _mToOrigin = matrix_build(-_centerX, -_centerY, 0, 0, 0, 0, 1, 1, 1);
        var _mTransform = matrix_build(_centerX, _centerY, 0, _render.rotationX, _render.rotationY, -_render.rotationZ, _render.scaleX, _render.scaleY, 1);
        var _mFinal = matrix_multiply(_mToOrigin, _mTransform);

        matrix_stack_push(_mFinal);
        matrix_set(matrix_world, matrix_stack_top());

        return true; 
    }

    return false;
}

/// @ignore Pops the matrix stack and restores the previous world matrix state.
function __willow_matrix_restore_transform() {
    if (!matrix_stack_is_empty()) {
        matrix_stack_pop();

        if (matrix_stack_is_empty()) {
            matrix_set(matrix_world, matrix_build_identity());
        } else {
            matrix_set(matrix_world, matrix_stack_top());
        }
    } else {
        // - ERROR
        var _report = __willow_get_report_tag();
        show_debug_message("{0} ERROR: Matrix stack empty! Imbalance detected in restore transform.", _report);
        matrix_set(matrix_world, matrix_build_identity());
    }
}