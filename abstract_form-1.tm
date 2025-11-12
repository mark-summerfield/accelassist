# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::abstract create AbstractForm {
    variable Form
}

oo::define AbstractForm constructor {form on_close {modal true}} {
    set Form $form
    wm withdraw $Form
    if {[tk windowingsystem] eq "x11"} { wm attributes $Form -type dialog }
    if {$modal} { wm transient $Form . }
    wm group $Form .
    set parent [winfo parent $Form]
    set x [expr {[winfo x $parent] + [winfo width $parent] / 3}]
    set y [expr {[winfo y $parent] + [winfo height $parent] / 3}]
    wm geometry $Form "+$x+$y"
    wm protocol $Form WM_DELETE_WINDOW $on_close
}

oo::define AbstractForm method form {} { return $Form }

oo::define AbstractForm method show_modal {{focus_widget ""}} {
    wm deiconify $Form
    grab set $Form
    raise $Form
    update
    focus $Form
    if {$focus_widget ne ""} { focus $focus_widget }
}

oo::define AbstractForm method show_modeless {{focus_widget ""}} {
    wm deiconify $Form
    raise $Form
    update
    focus $Form
    if {$focus_widget ne ""} { focus $focus_widget }
}

oo::define AbstractForm method delete {} {
    grab release $Form
    destroy $Form
}

oo::define AbstractForm method hide {} {
    grab release $Form
    wm withdraw $Form
}
