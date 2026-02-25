/// @desc Semantic Theme registry and constructors for the Willow UI library.
function WillowThemes() constructor {
    
    #region STATIC MAPPING
    static Template     = __WillowThemeTemplate;
    static Abyss        = __WillowThemeAbyss;
    static Acid         = __WillowThemeAcid;
    static Aqua         = __WillowThemeAqua;
    static Autumn       = __WillowThemeAutumn;
    static Black        = __WillowThemeBlack;
    static Bumblebee    = __WillowThemeBumblebee;
    static Business     = __WillowThemeBusiness;
    static CaramelLatte = __WillowThemeCaramelLatte;
    static CMYK         = __WillowThemeCMYK;
    static Coffee       = __WillowThemeCoffee;
    static Corporate    = __WillowThemeCorporate;
    static Cupcake      = __WillowThemeCupcake;
    static Cyberpunk    = __WillowThemeCyberpunk;
    static Dark         = __WillowThemeDark;
    static Dim          = __WillowThemeDim;
    static Dracula      = __WillowThemeDracula;
    static Emerald      = __WillowThemeEmerald;
    static Forest       = __WillowThemeForest;
    static Light        = __WillowThemeLight;
    static Valentine    = __WillowThemeValentine;
    static Winter       = __WillowThemeWinter;

    /// @desc Static Registry for easy iteration
    static All = [
        __WillowThemeAbyss,
        __WillowThemeAcid,
        __WillowThemeAqua,
        __WillowThemeAutumn,
        __WillowThemeBlack,
        __WillowThemeBumblebee,
        __WillowThemeBusiness,
        __WillowThemeCaramelLatte,
        __WillowThemeCMYK,
        __WillowThemeCoffee,
        __WillowThemeCorporate,
        __WillowThemeCupcake,
        __WillowThemeCyberpunk,
        __WillowThemeDark,
        __WillowThemeDim,
        __WillowThemeDracula,
        __WillowThemeEmerald,
        __WillowThemeForest,
        __WillowThemeLight,
        __WillowThemeValentine,
        __WillowThemeWinter
    ];
    #endregion
}

#region GLOBAL THEME SCRIPT FUNCTIONS
/// @ignore Base Template
function __WillowThemeTemplate() constructor {
    radius = { box: 8, field: 4, selector: 8, btn: 8 };
    size = {
        xs: 24, sm: 32, md: 40, lg: 48, xl: 56,
        pad_xs: 4, pad_sm: 8, pad_md: 12, pad_lg: 16,
        font_xs: 12, font_sm: 14, font_md: 16, font_lg: 18, font_xl: 20
    };
    anim = { btn: 0.2, focus_scale: 0.95, hover_alpha: 0.1, disabled_alpha: 0.5 };
}

function __WillowThemeDark() : __WillowThemeTemplate() constructor {
    name = "dark"; color_scheme = "dark";
    color = {
        base_100: #1d232a, base_200: #191e24, base_300: #15191e, base_content: #a6adbb,
        primary: #7480ff, primary_content: #050617, secondary: #ff52d9, secondary_content: #160211,
        accent: #00cdb8, accent_content: #000f0c, neutral: #2a323c, neutral_content: #a6adbb,
        info: #00b5ff, info_content: #000c16, success: #00a96e, success_content: #000a06,
        warning: #ffbe00, warning_content: #161000, error: #ff5861, error_content: #160305
    };
}

function __WillowThemeLight() : __WillowThemeTemplate() constructor {
    name = "light"; color_scheme = "light";
    color = {
        base_100: #ffffff, base_200: #f2f2f2, base_300: #e5e6e6, base_content: #1f2937,
        primary: #4f46e5, primary_content: #e0e7ff, secondary: #ff52d9, secondary_content: #160211,
        accent: #00cdb8, accent_content: #000f0c, neutral: #2b3440, neutral_content: #d7dde4,
        info: #00b5ff, info_content: #000c16, success: #00a96e, success_content: #000a06,
        warning: #ffbe00, warning_content: #161000, error: #ff5861, error_content: #160305
    };
}

function __WillowThemeAbyss() : __WillowThemeTemplate() constructor {
    name = "abyss"; color_scheme = "dark";
    color = {
        base_100: #293444, base_200: #1d2633, base_300: #121822, base_content: #f4e8d1,
        primary: #47ff2f, primary_content: #008000, secondary: #ecd9ff, secondary_content: #8367a1,
        accent: #6d6d6d, accent_content: #fafafa, neutral: #3d4f66, neutral_content: #f4e8d1,
        info: #00d2ff, info_content: #223f5e, success: #00ffbc, success_content: #123e2b,
        warning: #ffcf24, warning_content: #735900, error: #ff5e67, error_content: #73000d
    };
    radius = { box: 8, field: 4, selector: 32, btn: 8 };
}

function __WillowThemeAcid() : __WillowThemeTemplate() constructor {
    name = "acid"; color_scheme = "light";
    color = {
        base_100: #fafafa, base_200: #f2f2f2, base_300: #e8e8e8, base_content: #000000,
        primary: #ff00ff, primary_content: #400040, secondary: #ff8c00, secondary_content: #402300,
        accent: #00ff00, accent_content: #004000, neutral: #381e51, neutral_content: #d6cfdc,
        info: #008eff, info_content: #002340, success: #00ff9f, success_content: #004027,
        warning: #f8ff00, warning_content: #3e4000, error: #ff0055, error_content: #400015
    };
    radius = { box: 16, field: 16, selector: 16, btn: 16 };
}

function __WillowThemeAqua() : __WillowThemeTemplate() constructor {
    name = "aqua"; color_scheme = "dark";
    color = {
        base_100: #426cb3, base_200: #334e85, base_300: #293e6a, base_content: #cde4ff,
        primary: #63eeff, primary_content: #006b7a, secondary: #b976ff, secondary_content: #f1f0ff,
        accent: #ffe84a, accent_content: #302d00, neutral: #33538a, neutral_content: #a2c7ff,
        info: #0089ff, info_content: #e2f2ff, success: #00b97c, success_content: #002a1c,
        warning: #d79f00, warning_content: #734f00, error: #ff7c7b, error_content: #410100
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeAutumn() : __WillowThemeTemplate() constructor {
    name = "autumn"; color_scheme = "light";
    color = {
        base_100: #f1f1f1, base_200: #e0e0e0, base_300: #cfcfcf, base_content: #313131,
        primary: #8c0327, primary_content: #f4dede, secondary: #d53910, secondary_content: #3a0d01,
        accent: #c1a12e, accent_content: #342b00, neutral: #8e8271, neutral_content: #f4f0ec,
        info: #00abc6, info_content: #002b31, success: #00a480, success_content: #002920,
        warning: #d4a300, warning_content: #352900, error: #bc233c, error_content: #f8dedf
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeBlack() : __WillowThemeTemplate() constructor {
    name = "black"; color_scheme = "dark";
    color = {
        base_100: #000000, base_200: #303030, base_300: #383838, base_content: #dadada,
        primary: #595959, primary_content: #ffffff, secondary: #595959, secondary_content: #ffffff,
        accent: #595959, accent_content: #ffffff, neutral: #595959, neutral_content: #ffffff,
        info: #007bff, info_content: #e1f1ff, success: #00a54e, success_content: #e3f8ec,
        warning: #ffff00, warning_content: #404000, error: #ff5c6a, error_content: #400000
    };
    radius = { box: 0, field: 0, selector: 0, btn: 0 };
    anim = { btn: 0, focus_scale: 1, hover_alpha: 0.1, disabled_alpha: 0.5 };
}

function __WillowThemeBumblebee() : __WillowThemeTemplate() constructor {
    name = "bumblebee"; color_scheme = "light";
    color = {
        base_100: #ffffff, base_200: #f7f7f7, base_300: #eaeaea, base_content: #333333,
        primary: #f2cc00, primary_content: #7a5400, secondary: #ff9800, secondary_content: #833900,
        accent: #000000, accent_content: #ffffff, neutral: #5e5e54, neutral_content: #ebebe5,
        info: #00b5ff, info_content: #315082, success: #00bd8b, success_content: #123e2b,
        warning: #ffca00, warning_content: #735900, error: #ff6e65, error_content: #741712
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeBusiness() : __WillowThemeTemplate() constructor {
    name = "business"; color_scheme = "dark";
    color = {
        base_100: #3e3e3e, base_200: #393939, base_300: #343434, base_content: #d1d1d1,
        primary: #1e4b8a, primary_content: #e0e9f4, secondary: #97a4b0, secondary_content: #212528,
        accent: #e28e00, accent_content: #382300, neutral: #444950, neutral_content: #d8d9db,
        info: #1b90ff, info_content: #002440, success: #00bd7e, success_content: #002f20,
        warning: #e3bc21, warning_content: #382f00, error: #9f3131, error_content: #f6e6e6
    };
    radius = { box: 4, field: 4, selector: 0, btn: 4 };
}

function __WillowThemeCaramelLatte() : __WillowThemeTemplate() constructor {
    name = "caramellatte"; color_scheme = "light";
    color = {
        base_100: #fff9f0, base_200: #fff2df, base_300: #f4e8d1, base_content: #833900,
        primary: #000000, primary_content: #ffffff, secondary: #48332a, secondary_content: #f4e8d1,
        accent: #976b50, accent_content: #f4e8d1, neutral: #ba5e34, neutral_content: #fff9f0,
        info: #0060df, info_content: #f4e8d1, success: #006b50, success_content: #f4e8d1,
        warning: #ffca00, warning_content: #735900, error: #ff6e65, error_content: #741712
    };
    radius = { box: 16, field: 8, selector: 32, btn: 16 };
}

function __WillowThemeCMYK() : __WillowThemeTemplate() constructor {
    name = "cmyk"; color_scheme = "light";
    color = {
        base_100: #ffffff, base_200: #f2f2f2, base_300: #e5e5e5, base_content: #333333,
        primary: #0097fb, primary_content: #00263f, secondary: #ff007b, secondary_content: #40001f,
        accent: #f8ff00, accent_content: #3e4000, neutral: #393939, neutral_content: #d6d6d6,
        info: #00a3ff, info_content: #00293f, success: #8e00cf, success_content: #f4e0ff,
        warning: #d7ab00, warning_content: #362b00, error: #ff6657, error_content: #3f1915
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeCoffee() : __WillowThemeTemplate() constructor {
    name = "coffee"; color_scheme = "dark";
    color = {
        base_100: #3f363d, base_200: #372f35, base_300: #292428, base_content: #c29f63,
        primary: #c2592d, primary_content: #311600, secondary: #505c5c, secondary_content: #dbdede,
        accent: #407590, accent_content: #e1eef4, neutral: #292428, neutral_content: #d3d2d3,
        info: #a3ccf1, info_content: #29333c, success: #97c49d, success_content: #263127,
        warning: #f8d77e, warning_content: #3e3620, error: #ff9d89, error_content: #402722
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeCorporate() : __WillowThemeTemplate() constructor {
    name = "corporate"; color_scheme = "light";
    color = {
        base_100: #ffffff, base_200: #ededed, base_300: #dbdbdb, base_content: #3d4151,
        primary: #0093ff, primary_content: #ffffff, secondary: #7f8a9e, secondary_content: #ffffff,
        accent: #00a4a4, accent_content: #ffffff, neutral: #000000, neutral_content: #ffffff,
        info: #0099ff, info_content: #ffffff, success: #00bd7e, success_content: #ffffff,
        warning: #f2cc00, warning_content: #000000, error: #ff6e65, error_content: #000000
    };
    radius = { box: 4, field: 4, selector: 4, btn: 4 };
}

function __WillowThemeCupcake() : __WillowThemeTemplate() constructor {
    name = "cupcake"; color_scheme = "light";
    color = {
        base_100: #faf7f5, base_200: #f0ebe8, base_300: #eae3e0, base_content: #632e83,
        primary: #65c3c8, primary_content: #3a7073, secondary: #ef9fbc, secondary_content: #8e184b,
        accent: #eeaf3a, accent_content: #895d00, neutral: #454245, neutral_content: #ebebe5,
        info: #00abc6, info_content: #223f5e, success: #00a480, success_content: #123e2b,
        warning: #f1b300, warning_content: #483600, error: #ff6675, error_content: #480000
    };
    radius = { box: 16, field: 32, selector: 16, btn: 16 };
}

function __WillowThemeCyberpunk() : __WillowThemeTemplate() constructor {
    name = "cyberpunk"; color_scheme = "light";
    color = {
        base_100: #ffee00, base_200: #e0d000, base_300: #c2b400, base_content: #000000,
        primary: #ff003c, primary_content: #260009, secondary: #00f0ff, secondary_content: #002226,
        accent: #d100c4, accent_content: #1e001c, neutral: #130032, neutral_content: #ffee00,
        info: #00ccff, info_content: #000000, success: #00ff99, success_content: #000000,
        warning: #ffb300, warning_content: #000000, error: #ff003c, error_content: #000000
    };
    radius = { box: 0, field: 0, selector: 0, btn: 0 };
}

function __WillowThemeDim() : __WillowThemeTemplate() constructor {
    name = "dim"; color_scheme = "dark";
    color = {
        base_100: #494e5a, base_200: #424651, base_300: #3d4149, base_content: #b4c2da,
        primary: #9ee18e, primary_content: #223e19, secondary: #ff856a, secondary_content: #400d00,
        accent: #f896ff, accent_content: #3e0040, neutral: #3a3e47, neutral_content: #b4c2da,
        info: #98d1ff, info_content: #223440, success: #97e1c1, success_content: #223e31,
        warning: #f7e08e, warning_content: #3e3819, error: #ffb1a3, error_content: #40231e
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeDracula() : __WillowThemeTemplate() constructor {
    name = "dracula"; color_scheme = "dark";
    color = {
        base_100: #282a36, base_200: #21222c, base_300: #191a21, base_content: #f8f8f2,
        primary: #ff79c6, primary_content: #28101d, secondary: #bd93f9, secondary_content: #1a1025,
        accent: #f1fa8c, accent_content: #191a0c, neutral: #414558, neutral_content: #f8f8f2,
        info: #8be9fd, info_content: #0d1e22, success: #50fa7b, success_content: #09200e,
        warning: #f1fa8c, warning_content: #191a0c, error: #ff5555, error_content: #220505
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeEmerald() : __WillowThemeTemplate() constructor {
    name = "emerald"; color_scheme = "light";
    color = {
        base_100: #ffffff, base_200: #ededed, base_300: #dbdbdb, base_content: #4e5e77,
        primary: #66cc8a, primary_content: #20412c, secondary: #377cfb, secondary_content: #ffffff,
        accent: #f68067, accent_content: #000000, neutral: #4e5e77, neutral_content: #f9fbfc,
        info: #00b5ff, info_content: #000000, success: #00a96e, success_content: #000000,
        warning: #ffbe00, warning_content: #000000, error: #ff5861, error_content: #000000
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}

function __WillowThemeForest() : __WillowThemeTemplate() constructor {
    name = "forest"; color_scheme = "dark";
    color = {
        base_100: #363636, base_200: #303030, base_300: #292929, base_content: #d6d6d6,
        primary: #1eb854, primary_content: #000000, secondary: #1db88e, secondary_content: #002e23,
        accent: #1db8ab, accent_content: #002e2b, neutral: #315241, neutral_content: #dae1de,
        info: #00b5ff, info_content: #000000, success: #00a96e, success_content: #000000,
        warning: #ffbe00, warning_content: #000000, error: #ff5861, error_content: #000000
    };
    radius = { box: 16, field: 32, selector: 16, btn: 16 };
}

function __WillowThemeValentine() : __WillowThemeTemplate() constructor {
    name = "valentine"; color_scheme = "light";
    color = {
        base_100: #fef1f6, base_200: #f6d1e4, base_300: #ef9fbc, base_content: #9e0e1f,
        primary: #e96d7b, primary_content: #ffffff, secondary: #a991f7, secondary_content: #fef1f6,
        accent: #88dbdf, accent_content: #333333, neutral: #af4670, neutral_content: #ef9fbc,
        info: #8be9fd, info_content: #002b36, success: #50fa7b, success_content: #003300,
        warning: #f1fa8c, warning_content: #333300, error: #ff5555, error_content: #fef1f6
    };
    radius = { box: 16, field: 32, selector: 16, btn: 16 };
}

function __WillowThemeWinter() : __WillowThemeTemplate() constructor {
    name = "winter"; color_scheme = "light";
    color = {
        base_100: #ffffff, base_200: #f2f7ff, base_300: #e5efff, base_content: #394e7c,
        primary: #046bd2, primary_content: #e0ecff, secondary: #463aa2, secondary_content: #e1def1,
        accent: #c148ac, accent_content: #31002a, neutral: #1a2233, neutral_content: #d1d5db,
        info: #a3ccf1, info_content: #29333c, success: #97c49d, success_content: #263127,
        warning: #f8d77e, warning_content: #3e3620, error: #ff9d89, error_content: #402722
    };
    radius = { box: 16, field: 8, selector: 16, btn: 16 };
}
#endregion