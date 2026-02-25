/// @ignore Builds a random theme color.
function __willow_generate_colour() {
    return make_color_hsv(irandom_range(0, 255), 120, 154);
}