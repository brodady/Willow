ui = new Willow()
    .setTheme(WillowThemes.Dark) 
    .useScribble(false)
    .useCleanShapes(false)
    .useAntiAlias(false)
    .debugEnabled(false);

themeList = ui.Themes.All;
themeIndex = 0;

ui.onThemeChange(function(_t) {
    if (!variable_instance_exists(id, "login_modal")) return;

    var _colBase100 = [_t.color.base_100, _t.color.base_100, _t.color.base_100, _t.color.base_100];
    var _colBase200 = [_t.color.base_200, _t.color.base_200, _t.color.base_200, _t.color.base_200];
    var _colPrimary = [_t.color.primary, _t.color.primary, _t.color.primary, _t.color.primary];

    login_modal.animateTo({ rounding: _t.radius.box, colours: _colBase100 }, 0.4, CassetteEase.OutCubic);
    
    var _modalShake = ui.anim.getTape("modal_shake");
    if (_modalShake != undefined) {
        _modalShake.rewind().play();
    } else {
        login_modal.__render.offsetX = -40;
        ui.anim.insert("modal_shake")
            .bind(login_modal.__render)
            .from({ offsetX: -40 })
            .to({ offsetX: 0 })
            .duration(0.8)
            .ease(CassetteEase.OutElastic)
            .play();
    }
    
    var _inputRenderProps = { 
        colours: _colBase200, 
        borderColours: _colPrimary, 
        borderAlpha: [0.6, 0.6, 0.6, 0.6] 
    };
    
    txt_username.animateTo(_inputRenderProps, 0.4, CassetteEase.OutCubic);
    txt_password.animateTo(_inputRenderProps, 0.4, CassetteEase.OutCubic);
    txt_notes.animateTo(_inputRenderProps, 0.4, CassetteEase.OutCubic);
    
    btn_login.setText("SWITCH THEME: " + string_upper(_t.name));
    
    my_dropdown.__styleDefinition
        .rounding(_t.radius.box)
        .color(_t.color.base_100); 

    my_dropdown.__itemStyle
        .height(_t.size.md)
        .rounding(_t.radius.field)
        .color(_t.color.base_100)
        .textColor(_t.color.base_content);
    
    var _dropShake = ui.anim.getTape("dropdown_shake");
    if (_dropShake != undefined) {
        _dropShake.rewind().play();
    } else {
        my_dropdown.__render.offsetX = 20;
        ui.anim.insert("dropdown_shake")
            .bind(my_dropdown.__render)
            .from({ offsetX: 20 })
            .to({ offsetX: 0 })
            .duration(0.8)
            .ease(CassetteEase.OutElastic)
            .play();
    }
});

build_ui = function() {
    var _t = __WillowSystem().theme; 

    #region STYLES
    var _styleWrapper = new WillowStyle().width("100%").height("100%").justifyContent("center").alignItems("center").alpha(0);

    var _styleModal = new WillowStyle().width(420).minWidth(420).height(480).minHeight(480)
        .rounding(_t.radius.box).color(_t.color.base_100)
        .justifyContent("flex-start").alignItems("center").flexDirection("column")
        .clipContents(true).padding(40)
        .alpha(0).scale(0.8);

    var _styleHeader = new WillowStyle()
        .width("100%").minHeight(40).modifiers(WILLOW_MOD.xl)
        .textAlignH(fa_center).textColor(_t.color.base_content).textFont(fnt_ubuntu_bold)
        .margin(0, 0, 25, 0).alpha(0).offset(0, -20);

    var _styleInput = new WillowStyle().modifiers(WILLOW_MOD.lg)
        .width(320).height(_t.size.md).rounding(_t.radius.field).color(_t.color.base_200)
        .margin(0, 0, 15, 0).alpha(0).scale(0.6)
        .textColor(_t.color.base_content).outlineColor(_t.color.primary).outlineAlpha(0.6);
    
    var _styleButton = new WillowStyle()
    .modifiers(WILLOW_MOD.xl).width(320).alpha(0).margin(25, 0).textFont(fnt_open_sans_semibold);
    #endregion

    #region LAYOUT
    screen_wrapper = new ui.Box("wrapper", _styleWrapper);
    login_modal    = new ui.Box("modal", _styleModal).setResizable(true, true);

    lbl_welcome  = new ui.Text("title", "SIGN UP", _styleHeader).setSelectable(true).setAutoWrap(true);
    txt_username = new ui.TextBox("user", "Username", _styleInput.clone());
    txt_password = new ui.TextBox("pass", "Password", _styleInput.clone()).setReplacementChar("*");
    
    txt_notes = new ui.TextBox("notes", "Tell us about yourself...", _styleInput.clone().height(120))
        .setMultiline(true, false).setResizable(false, true);

    btn_login = new ui.Button("SWITCH THEME: " + string_upper(_t.name), _styleButton);
    btn_login.onClick(method(self, function() {
        themeIndex = (themeIndex + 1) % array_length(themeList);
        ui.setTheme(themeList[themeIndex]); 
    }));

    var _fileOptions = [
        { label: "New Project", callback: function() { show_debug_message("New"); } },
        { label: "Save File",   callback: function() { show_debug_message("Saved"); } }
    ];

    my_dropdown = new WillowDropDown("file_menu", _fileOptions, new WillowStyle(), new WillowStyle());

    for (var i = 0; i < array_length(my_dropdown.__children); i++) {
        my_dropdown.__children[i].setIcon(spr_circle, 0.5, 0, 0.5, "right");
    }
    my_dropdown.close(); 

    btn_login.onRightClick(method({ drop: my_dropdown }, function() {
        drop.open(window_mouse_get_x(), window_mouse_get_y());
        drop.animateTo({ alpha: 1 }, 0.15, CassetteEase.OutQuad);
    }));
    
    login_modal.contains([lbl_welcome, txt_username, txt_password, txt_notes, btn_login]);
    screen_wrapper.contains([login_modal, my_dropdown]);
    ui.compose([screen_wrapper]);

    // Intro Animations using partial structs
    // Note: alpha requires the [1, 1, 1, 1] array because the render engine evaluates 4 corners
    login_modal.animateTo({ alpha: [1, 1, 1, 1], scaleX: 1, scaleY: 1 },  0.4, CassetteEase.OutCubic, 0.0);
    lbl_welcome.animateTo({ alpha: [1, 1, 1, 1], offsetY: 0 }, 0.4, CassetteEase.OutBack,  0.1);
    txt_username.animateTo({ alpha: [1, 1, 1, 1], scaleX: 1, scaleY: 1 }, 0.4, CassetteEase.OutBack,  0.2);
    txt_password.animateTo({ alpha: [1, 1, 1, 1], scaleX: 1, scaleY: 1 }, 0.4, CassetteEase.OutBack,  0.3);
    txt_notes.animateTo({ alpha: [1, 1, 1, 1], scaleX: 1, scaleY: 1 }, 0.4, CassetteEase.OutBack,  0.4); 
    btn_login.animateTo({ alpha: [1, 1, 1, 1] }, 0.4, CassetteEase.OutBack, 0.5);
    #endregion
};

build_ui();
