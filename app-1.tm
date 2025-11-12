# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require config_form
package require item
package require lambda 1
package require ref
package require textedit
package require ui

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
    focus [$UnhintedTextEdit tk_text]
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
    if {[set unhinted [string trim [$config lastunhinted]]] eq ""} {
        set unhinted "Undo\nRedo\nCopy\nCu&t\nPaste\nFind\nFind\
            Again\nFind && Replace"
    }
    $UnhintedTextEdit insert end $unhinted
    set HintedTextEdit [TextEdit new .mf.body]
    set tab1 [font measure TkDefaultFont "999"]
    set tab2 [expr {$tab1 + [font measure TkDefaultFont —]}]
    $HintedTextEdit configure -tabs "$tab1 numeric $tab2 left" -undo false
    $HintedTextEdit set_completion false
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
    $UnhintedTextEdit edit modified false
    my AccelAssist
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new false]
    set form [ConfigForm new $ok]
    tkwait window [$form form]
}

oo::define App method on_quit {} {
    set config [Config new]
    $config set_lastunhinted [$UnhintedTextEdit get 1.0 end]
    $config save
    exit
}

# TODO refactor
oo::define App method AccelAssist {} {
    switch $WhichAlphabet {
        az { set alphabet ABCDEFGHIJKLMNOPQRSTUVWXYZ }
        az19 { set alphabet 123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ }
        az09 { set alphabet 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ }
    }
    set unused [dict create]
    foreach c [split $alphabet ""] {
        dict set unused $c ""
    }
    set items [list]
    foreach term [split [$UnhintedTextEdit get 1.0 end] \n] {
        if {$term ne ""} {
            set item [Item new $term]
            lappend items $item
            if {[set c [$item char]] ne ""} {
                dict unset unused $c
            }
        }
    }
    set bysize [lsort -indices -command [lambda {a b} { $a compare $b }] \
        $items]
    foreach i $bysize {
        set item [lindex $items $i]
        foreach c [$item candidates] {
            if {[dict exists $unused $c]} {
                $item set_char $c
                dict unset unused $c
            }
        }
    }
    $HintedTextEdit delete 1.0 end
    foreach item $items {
        set c [$item char]
        if {[set i [$item index]] == -1} {
            $HintedTextEdit insert end \t?\t red
        } else {
            $HintedTextEdit insert end \t$i\t purple
        }
        set term [$item term]
        if {$i == -1} {
            $HintedTextEdit insert end $term
        } else {
            $HintedTextEdit insert end [string range $term 0 $i-1]
            $HintedTextEdit insert end [string index $term $i] \
                {highlight ul blue bold}
            $HintedTextEdit insert end [string range $term $i+1 end]
        }
        $HintedTextEdit insert end \n
    }
    # TODO show unused: need extra label
}
