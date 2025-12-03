# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config
package require config_form
package require item
package require lambda 1
package require ref
package require textedit
package require ui

oo::singleton create App {
    variable Filename
    variable UnhintedTextEdit
    variable HintedTextEdit
    variable UnusedLabel
    variable CountLabel
}

oo::define App constructor {} {
    ui::wishinit
    tk appname AccelAssist
    set config [Config new] ;# we need tk scaling done early
    set Filename [$config lastfilename]
    if {$::argc > 0} { set Filename [lindex $::argv 0] }
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    set config [Config new]
    wm geometry . [$config geometry]
    raise .
    update
    after idle [callback at_startup]
}

oo::define App method at_startup {} {
    if {$Filename ne ""} { my FileOpen }
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
    ttk::frame .mf.ctrl
    ttk::button .mf.ctrl.newButton -text New -underline 0 \
        -command [callback on_new] -width 7 -compound left \
        -image [ui::icon document-new.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.openButton -text Open… -underline 0 \
        -command [callback on_open] -width 7 -compound left \
        -image [ui::icon document-open.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.saveButton -text Save -underline 0 \
        -command [callback on_save] -width 7 -compound left \
        -image [ui::icon document-save.svg $::ICON_SIZE]
    ttk::menubutton .mf.ctrl.moreButton -text More -underline 0 \
        -compound left -image [ui::icon blank.svg $::ICON_SIZE]
    menu .mf.ctrl.moreButton.menu
    .mf.ctrl.moreButton.menu add command -label Config… -underline 0 \
        -compound left -command [callback on_config] \
        -image [ui::icon preferences-system.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton.menu add command -label About -underline 0 \
        -compound left -command [callback on_about] \
        -image [ui::icon about.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton.menu add separator
    .mf.ctrl.moreButton.menu add command -label Quit -underline 0 \
        -compound left -command [callback on_quit] -accelerator Ctrl+Q \
        -image [ui::icon quit.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton configure -menu .mf.ctrl.moreButton.menu
    ttk::frame .mf.body
    set UnhintedTextEdit [TextEdit new .mf.body]
    set HintedTextEdit [TextEdit new .mf.body]
    set tab1 [font measure TkDefaultFont "A-999"]
    set tab2 [expr {$tab1 + [font measure TkDefaultFont —]}]
    $HintedTextEdit configure -tabs "$tab1 numeric $tab2 left" -undo false
    $HintedTextEdit set_completion false
    $HintedTextEdit tag configure ul -underlinefg purple
    ttk::frame .mf.state
    const opts "-relief sunken -padding 3"
    ttk::label .mf.state.countLabelLabel -text Done -padding 3
    set CountLabel [ttk::label .mf.state.countLabel -text 0/0 {*}$opts]
    ttk::label .mf.state.unusedLabelLabel -text Unused -padding 3
    set UnusedLabel [ttk::label .mf.state.unusedLabel {*}$opts]
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    grid .mf.ctrl -row 0 -column 0 -sticky we
    pack .mf.ctrl.newButton -side left {*}$opts
    pack .mf.ctrl.openButton -side left {*}$opts
    pack .mf.ctrl.saveButton -side left {*}$opts
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand true {*}$opts
    pack .mf.ctrl.moreButton -side left {*}$opts
    grid [$UnhintedTextEdit ttk_frame] -row 0 -column 0 -sticky news \
        {*}$opts
    grid [$HintedTextEdit ttk_frame] -row 0 -column 1 -sticky news {*}$opts
    grid rowconfigure .mf.body 0 -weight 1
    grid columnconfigure .mf.body 0 -weight 1
    grid columnconfigure .mf.body 1 -weight 1
    grid .mf.body -row 1 -column 0 -sticky news
    pack .mf.state.unusedLabelLabel -side left {*}$opts
    pack .mf.state.unusedLabel -side left -fill x -expand true {*}$opts
    pack .mf.state.countLabelLabel -side left {*}$opts
    pack .mf.state.countLabel -side left {*}$opts
    grid .mf.state -row 2 -column 0 -sticky we {*}$opts
    grid columnconfigure .mf 0 -weight 1
    grid rowconfigure .mf 1 -weight 1
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind . <Alt-n> [callback on_new]
    bind . <Alt-o> [callback on_open]
    bind . <Alt-m> {
        tk_popup .mf.ctrl.moreButton.menu \
            [expr {[winfo rootx .mf.ctrl.moreButton]}] \
            [expr {[winfo rooty .mf.ctrl.moreButton] + \
                   [winfo height .mf.ctrl.moreButton]}]
    }
    bind . <Control-q> [callback on_quit]
    bind . <Alt-s> [callback on_save]
    bind [$UnhintedTextEdit tk_text] <<Modified>> [callback on_change]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_change {} {
    $UnhintedTextEdit edit modified false
    my AccelAssist
}

oo::define App method on_new {} {
    my MaybeSave
    set Filename ""
    wm title . "[tk appname] — «unsaved»"
    $UnhintedTextEdit delete 1.0 end
    focus [$UnhintedTextEdit tk_text]
}

oo::define App method on_open {} {
    my MaybeSave
    set dir [expr {$Filename eq "" ? [file home] \
                                   : [file dirname $Filename]}]
    if {[set filename [tk_getOpenFile -initialdir $dir \
                -filetypes {{{AccelAssist files} {.acc}}} \
            -title "[tk appname] — Open" -parent .]] ne ""} {
        set Filename $filename
        my FileOpen
    }
}

oo::define App method on_save {} {
    if {$Filename ne ""} {
        my FileSave
    } else {
        set dir [file home]
        if {[set filename [tk_getSaveFile -initialdir $dir \
                -filetypes {{{AccelAssist files} {.acc}}} \
                -title "[tk appname] — Save As" -parent .]] ne ""} {
            set Filename $filename
            my FileSave
        }
    }
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new false]
    set form [ConfigForm new $ok]
    tkwait window [$form form]
}

oo::define App method on_about {} {
    AboutForm new "Keyboard accelerators assistant" \
        https://github.com/mark-summerfield/accelassist
}

oo::define App method on_quit {} {
    my MaybeSave
    set config [Config new]
    $config set_lastfilename [file normalize $Filename]
    $config save
    exit
}

oo::define App method MaybeSave {} {
    if {$Filename ne "" || \
            [string trim [$UnhintedTextEdit get 1.0 end]] ne ""} {
        my on_save
    }
}

oo::define App method FileOpen {} {
    $UnhintedTextEdit delete 1.0 end
    $UnhintedTextEdit insert end [string trim [readFile $Filename]]
    $UnhintedTextEdit edit modified false
    wm title . "[tk appname] — [file tail $Filename]"
    my AccelAssist
}

oo::define App method FileSave {} {
    if {[set txt [string trim [$UnhintedTextEdit get 1.0 end]]] ne ""} {
        writeFile $Filename $txt
    }
}

oo::define App method AccelAssist {} {
    $HintedTextEdit delete 1.0 end
    set unused [dict create]
    const ALPHABET "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $CountLabel configure -text 0/0
    $UnusedLabel configure -text $ALPHABET -foreground navy
    foreach c [split $ALPHABET ""] { dict set unused $c "" }
    if {[set items [my GetItems unused]] eq ""} { return }
    my ApplyHints $items unused
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
                    return
                }
                dict set used $c ""
            }
        }
    }
    return $items
}

oo::define App method ApplyHints {items unused} {
    upvar 1 $unused unused_
    my HandleCutAndCopy $items unused_
    set bysize [lsort -indices -command [lambda {a b} { $a compare $b }] \
        $items]
    my TryFirstChar $items unused_ $bysize
    my TryFirstCharOfWords $items unused_ $bysize
    my TryAnyChar $items unused_ $bysize
}

oo::define App method HandleCutAndCopy {items unused} {
    upvar 1 $unused unused_
    if {[dict exists $unused_ C] && [dict exists $unused_ T]} {
        set cut_index -1
        set copy_index -1
        for {set i 0} {$i < [llength $items]} {incr i} {
            set item [lindex $items $i]
            if {[$item is_done]} { continue }
            set term [string toupper [$item term]]
            if {$term eq "CUT"} {
                set cut_index $i
            } elseif {$term eq "COPY"} {
                set copy_index $i
            }
        }
        if {$cut_index != -1 && $copy_index != -1} {
            [lindex $items $cut_index] set_char T
            [lindex $items $copy_index] set_char C
        }
    }
}

oo::define App method TryFirstChar {items unused bysize} {
    upvar 1 $unused unused_
    foreach i $bysize {
        set item [lindex $items $i]
        if {[$item is_done]} { continue }
        if {[set c [$item first_char]] ne ""} {
            my TryChar $c $item unused_
        }
    }
}

oo::define App method TryChar {c item unused} {
    upvar 1 $unused unused_
    if {[dict exists $unused_ $c]} {
        dict unset unused_ $c
        $item set_char $c
        return true
    }
    return false
}

oo::define App method TryFirstCharOfWords {items unused bysize} {
    upvar 1 $unused unused_
    foreach i $bysize {
        set item [lindex $items $i]
        if {[$item is_done]} { continue }
        foreach c [$item first_word_chars] {
            if {[my TryChar $c $item unused_]} { break }
        }
    }
}

oo::define App method TryAnyChar {items unused bysize} {
    upvar 1 $unused unused_
    foreach i $bysize {
        set item [lindex $items $i]
        if {[$item is_done]} { continue }
        foreach c [$item unique_chars] {
            if {[my TryChar $c $item unused_]} { break }
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
