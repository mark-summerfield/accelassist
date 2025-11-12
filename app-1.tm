# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require config_form
package require ref
package require textedit
package require ui

namespace eval app {}

oo::singleton create App {
    variable UnhintedTextEdit
    variable HintedTextEdit
    variable WhichAlphabet
    variable DoneLabel
}

oo::define App constructor {} {
    ui::wishinit
    tk appname AccelAssist
    Config new ;# we need tk scaling done early
    set WhichAlphabet az
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    set config [Config new]
    wm geometry . [$config geometry]
    raise .
    update
}

oo::define App method make_ui {} {
    my prepare_ui
    my make_widgets
    my make_layout
    my make_bindings
}

oo::define App method prepare_ui {} {
    wm title . [tk appname]
    wm iconname . [tk appname]
    wm iconphoto . -default [ui::icon icon.svg]
}

oo::define App method make_widgets {} {
    set config [Config new]
    ttk::frame .mf
    ttk::frame .mf.body
    set UnhintedTextEdit [TextEdit new .mf.body]
    set HintedTextEdit [TextEdit new .mf.body]
    ttk::frame .mf.ctrl
    ttk::label .mf.ctrl.label -text Alphabet: -underline 0
    ttk::radiobutton .mf.ctrl.az -text A-Z -underline 0 \
        -value az -variable [my varname WhichAlphabet] \
        -command [callback on_change]
    ttk::radiobutton .mf.ctrl.az19 -text 1-9A-Z -underline 0 \
        -value az19 -variable [my varname WhichAlphabet] \
        -command [callback on_change]
    ttk::radiobutton .mf.ctrl.az09 -text 0-9A-Z -underline 0 \
        -value az09 -variable [my varname WhichAlphabet] \
        -command [callback on_change]
    ttk::button .mf.ctrl.configButton -text Config… -underline 0 \
        -command [callback on_config] -width 7 -compound left \
        -image [ui::icon preferences-system.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.quitButton -text Quit -underline 0 \
        -command [callback on_quit] -width 7 -compound left \
        -image [ui::icon quit.svg $::ICON_SIZE]
    set DoneLabel [ttk::label .mf.ctrl.donelabel -text 0/0 -relief sunken \
        -padding 3]
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    grid [$UnhintedTextEdit ttk_frame] -row 0 -column 0 -sticky news \
        {*}$opts
    grid [$HintedTextEdit ttk_frame] -row 0 -column 1 -sticky news {*}$opts
    grid rowconfigure .mf.body 0 -weight 1
    grid columnconfigure .mf.body 0 -weight 1
    grid columnconfigure .mf.body 1 -weight 1
    pack .mf.ctrl.label -side left {*}$opts
    pack .mf.ctrl.az -side left {*}$opts
    pack .mf.ctrl.az19 -side left {*}$opts
    pack .mf.ctrl.az09 -side left {*}$opts
    pack $DoneLabel -side left {*}$opts
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand true {*}$opts
    pack .mf.ctrl.configButton -side left {*}$opts
    pack .mf.ctrl.quitButton -side left {*}$opts
    grid .mf.body -row 0 -column 0 -sticky news
    grid .mf.ctrl -row 1 -column 0 -sticky we
    grid columnconfigure .mf 0 -weight 1
    grid rowconfigure .mf 0 -weight 1
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind . <Alt-0> {.mf.ctrl.az09 invoke}
    bind . <Alt-Key-1> {.mf.ctrl.az19 invoke}
    bind . <Alt-a> {.mf.ctrl.az invoke}
    bind . <Alt-c> [callback on_config]
    bind . <Alt-q> [callback on_quit]
    bind [$UnhintedTextEdit tk_text] <<Modified>> [callback on_change]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_change {} {
    puts on_change ;# TODO recompute
    $UnhintedTextEdit edit modified false
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new false]
    set form [ConfigForm new $ok]
    tkwait window [$form form]
}

oo::define App method on_quit {} {
    set config [Config new]
    $config save
    exit
}
