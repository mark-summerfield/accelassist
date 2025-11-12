# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require tooltip 2
package require ui

oo::class create ConfigForm {
    superclass AbstractForm

    variable Ok
    variable Blinking
}

oo::define ConfigForm constructor ok {
    set Ok $ok
    set config [Config new]
    set Blinking [$config blinking]
    my make_widgets 
    my make_layout
    my make_bindings
    next .configForm [callback on_cancel]
    my show_modal .configForm.frame.scaleSpinbox
}

oo::define ConfigForm method make_widgets {} {
    set config [Config new]
    tk::toplevel .configForm
    wm resizable .configForm false false
    wm title .configForm "[tk appname] — Config"
    ttk::frame .configForm.frame
    set tip tooltip::tooltip
    ttk::label .configForm.frame.scaleLabel -text "Application Scale" \
        -underline 12
    ttk::spinbox .configForm.frame.scaleSpinbox -format %.2f -from 1.0 \
        -to 10.0 -increment 0.1
    $tip .configForm.frame.scaleSpinbox "Application’s scale factor.\n\
        Restart to apply."
    .configForm.frame.scaleSpinbox set [format %.2f [tk scaling]]
    ttk::checkbutton .configForm.frame.blinkCheckbutton \
        -text "Cursor Blink" -underline 7 \
        -variable [my varname Blinking]
    if {$Blinking} { .configForm.frame.blinkCheckbutton state selected }
    $tip .configForm.frame.blinkCheckbutton \
        "Whether the text cursor should blink."
    set opts "-compound left -width 15"
    ttk::label .configForm.frame.configFileLabel -foreground gray25 \
        -text "Config file"
    ttk::label .configForm.frame.configFilenameLabel -foreground gray25 \
        -text [$config filename] -relief sunken
    ttk::frame .configForm.frame.buttons
    ttk::button .configForm.frame.buttons.okButton -text OK -underline 0 \
        -compound left -image [ui::icon ok.svg $::ICON_SIZE] \
        -command [callback on_ok]
    ttk::button .configForm.frame.buttons.cancelButton -text Cancel \
        -compound left -command [callback on_cancel] \
        -image [ui::icon gtk-cancel.svg $::ICON_SIZE]
}

oo::define ConfigForm method make_layout {} {
    const opts "-padx 3 -pady 3"
    grid .configForm.frame.scaleLabel -row 0 -column 0 -sticky w {*}$opts
    grid .configForm.frame.scaleSpinbox -row 0 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid .configForm.frame.blinkCheckbutton -row 1 -column 1 -sticky we
    grid .configForm.frame.configFileLabel -row 8 -column 0 -sticky we \
        {*}$opts
    grid .configForm.frame.configFilenameLabel -row 8 -column 1 \
        -columnspan 2 -sticky we {*}$opts
    grid .configForm.frame.buttons -row 9 -column 0 -columnspan 3 \
        -sticky we
    pack [ttk::frame .configForm.frame.buttons.pad1] -side left -expand true
    pack .configForm.frame.buttons.okButton -side left {*}$opts
    pack .configForm.frame.buttons.cancelButton -side left {*}$opts
    pack [ttk::frame .configForm.frame.buttons.pad2] -side right \
        -expand true
    grid columnconfigure .configForm.frame 1 -weight 1
    pack .configForm.frame -fill both -expand true
}

oo::define ConfigForm method make_bindings {} {
    bind .configForm <Escape> [callback on_cancel]
    bind .configForm <Return> [callback on_ok]
    bind .configForm <Alt-b> {.configForm.frame.blinkCheckbutton invoke}
    bind .configForm <Alt-o> [callback on_ok]
    bind .configForm <Alt-s> {focus .configForm.frame.scaleSpinbox}
}

oo::define ConfigForm method on_ok {} {
    set config [Config new]
    tk scaling [.configForm.frame.scaleSpinbox get]
    $config set_blinking $Blinking
    $Ok set true
    my delete
}

oo::define ConfigForm method on_cancel {} { my delete }
