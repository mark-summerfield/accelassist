# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::singleton create Config {
    variable Filename
    variable Blinking
    variable Geometry
    variable DataFile
}

oo::define Config constructor {} {
    set Filename [util::get_ini_filename]
    set Blinking true
    set Geometry ""
    set DataFile ""
    if {[file exists $Filename] && [file size $Filename]} {
        set ini [ini::open $Filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale 1.0]
            if {![set Blinking [ini::value $ini General Blinking \
                    $Blinking]]} {
                option add *insertOffTime 0
                ttk::style configure . -insertofftime 0
            }
            set Geometry [ini::value $ini General Geometry $Geometry]
            set DataFile [ini::value $ini General DataFile $DataFile]
        } on error err {
            puts "invalid config in '$Filename'; using defaults: $err"
        } finally {
            ini::close $ini
        }
    }
}

oo::define Config method save {} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini General Scale [tk scaling]
        ini::set $ini General Blinking [my blinking]
        ini::set $ini General Geometry [wm geometry .]
        ini::set $ini General DataFile [my datafile]
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {} { return $Filename }
oo::define Config method set_filename filename { set Filename $filename }

oo::define Config method blinking {} { return $Blinking }
oo::define Config method set_blinking blinking { set Blinking $blinking }

oo::define Config method geometry {} { return $Geometry }
oo::define Config method set_geometry geometry { set Geometry $geometry }

oo::define Config method datafile {} { return $DataFile }
oo::define Config method set_datafile datafile { set DataFile $datafile }

oo::define Config method to_string {} {
    return "Config filename=$Filename blinking=$Blinking\
        scaling=[tk scaling] geometry=$Geometry datafile=$DataFile"
}
