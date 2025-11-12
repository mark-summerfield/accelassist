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
    variable CountLabel
    variable UnusedLabel
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
    set tab1 [font measure TkDefaultFont "A-999"]
    set tab2 [expr {$tab1 + [font measure TkDefaultFont —]}]
    $HintedTextEdit configure -tabs "$tab1 numeric $tab2 left" -undo false
    $HintedTextEdit set_completion false
    $HintedTextEdit tag configure ul -underlinefg purple
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
    ttk::frame .mf.state
    const opts "-relief sunken -padding 3"
    ttk::label .mf.state.countLabelLabel -text Done -padding 3
    set CountLabel [ttk::label .mf.state.countLabel -text 0/0 {*}$opts]
    ttk::label .mf.state.unusedLabelLabel -text Unused -padding 3
    set UnusedLabel [ttk::label .mf.state.unusedLabel {*}$opts]
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
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand true {*}$opts
    pack .mf.ctrl.configButton -side left {*}$opts
    pack .mf.ctrl.quitButton -side left {*}$opts
    grid .mf.body -row 0 -column 0 -sticky news
    pack .mf.state.countLabelLabel -side left {*}$opts
    pack .mf.state.countLabel -side left {*}$opts
    pack .mf.state.unusedLabelLabel -side left {*}$opts
    pack .mf.state.unusedLabel -side left -fill x -expand true {*}$opts
    grid .mf.state -row 1 -column 0 -sticky we {*}$opts
    grid .mf.ctrl -row 2 -column 0 -sticky we
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

oo::define App method Alphabet {} {
    switch $WhichAlphabet {
        az { return ABCDEFGHIJKLMNOPQRSTUVWXYZ }
        az19 { return 123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ }
        az09 { return "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
    }
}

oo::define App method AccelAssist {} {
    $HintedTextEdit delete 1.0 end
    set unused [dict create]
    set alphabet [my Alphabet]
    $CountLabel configure -text 0/0
    $UnusedLabel configure -text $alphabet -foreground navy
    foreach c [split $alphabet ""] { dict set unused $c "" }
    if {[set items [my GetItems unused]] eq ""} { return }
    my PrepareUnused $items unused
    set done [my PopulateHinted $items]
    set total [llength $items]
    $CountLabel configure -text "$done/$total" \
        -foreground [expr {$done == $total ? "green" : "magenta"}]
    $UnusedLabel configure -text [join [dict keys $unused] ""]
}

oo::define App method GetItems unused {
    upvar 1 $unused unused_
    set used [dict create]
    set items [list]
    foreach term [split [$UnhintedTextEdit get 1.0 end] \n] {
        if {$term ne ""} {
            set item [Item new $term]
            lappend items $item
            if {[set c [$item char]] ne ""} {
                dict unset unused_ $c
                if {[dict exists $used $c]} {
                    $HintedTextEdit insert end "\nDuplicate &$c" \
                        {center bold red}
                    return ""
                }
                dict set used $c ""
            }
        }
    }
    return $items
}

oo::define App method PrepareUnused {items unused} {
    upvar 1 $unused unused_
    set bysize [lsort -indices -command [lambda {a b} { $a compare $b }] \
        $items]
    foreach i $bysize {
        set item [lindex $items $i]
        foreach c [$item candidates] {
            if {[dict exists $unused_ $c]} {
                $item set_char $c
                dict unset unused_ $c
            }
        }
    }
}

oo::define App method PopulateHinted items {
    set done 0
    foreach item $items {
        set c [$item char]
        $HintedTextEdit insert end [expr {$c eq "" ? " " : $c}]\t \
            {green bold}
        if {[set i [$item index]] == -1} {
            $HintedTextEdit insert end ?\t red
        } else {
            $HintedTextEdit insert end $i\t purple
            incr done
        }
        set term [$item term]
        if {$i == -1} {
            $HintedTextEdit insert end $term
        } else {
            $HintedTextEdit insert end [string range $term 0 $i-1]
            $HintedTextEdit insert end [string index $term $i] \
                {ul green bold}
            $HintedTextEdit insert end [string range $term $i+1 end]
        }
        $HintedTextEdit insert end \n
    }
    return $done
}
