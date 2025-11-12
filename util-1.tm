# Copyright © 2025 Mark Summerfield. All rights reserved.

proc commas n {regsub -all {\d(?=(\d{3})+($|\.))} $n {\0,}}

proc bool_to_str b {expr {$b ? true : false}}

proc list_to_str lst {
    set str [list]
    foreach x $lst { lappend str "'$x'" }
    return "{[join $str " "]}"
}

proc lrandom lst { lindex $lst [expr {int(rand() * [llength $lst])}] }

namespace eval util {}

proc util::pre_process_args argv {
    set ppargv [list]
    foreach arg $argv {
        if {[string match {-*} $arg]} {
            if {[set i [string first = $arg]] == -1} {
                if {[string match {--*} $arg] || \
                        [string length $arg] == 2} {
                    lappend ppargv $arg
                } else {
                    lappend ppargv [string range $arg 0 1] \
                                   [string range $arg 2 end]
                }
            } else {
                lappend ppargv \
                    [string range $arg 0 [expr {$i - 1}]] \
                    [string range $arg [expr {$i + 1}] end]
            }
        } else {
            lappend ppargv $arg
        }
    }
    list [llength $ppargv] $ppargv
}

proc util::term_width {{defwidth 72}} {
    if {[dict exists [chan configure stdout] -mode]} { ;# tty
        return [lindex [chan configure stdout -winsize] 0]
    }
    return $defwidth ;# redirected
}

proc util::islink filename { expr {![catch {file link $filename}]} }

proc util::uid {} { return #[string range [clock clicks] end-8 end] }

proc util::get_ini_filename {} {
    set name [string totitle [tk appname]].ini
    set home [file home]
    if {[tk windowingsystem] eq "win32"} {
        set names [list [file join $home $name] $::APPPATH/$name]
        set index 0
    } else {
        set names [list [file join $home .config/$name] \
                        [file join $home .$name] $::APPPATH/$name]
        set index [expr {[file isdirectory [file join $home .config]] ? 0 \
                                                                      : 1}]
    }
    foreach name $names {
        set name [file normalize $name]
        if {[file exists $name]} { return $name }
    }
    lindex $names $index
}

proc util::open_url url {
    if {[tk windowingsystem] eq "win32"} {
        set cmd [list {*}[auto_execok start] {}]
    } else {
        set cmd [auto_execok xdg-open]
    }
    # may throw an error
    exec {*}$cmd $url &
}

proc util::n_s {size {comma false}} {
    if {!$size} { return [list "no" "s"] }
    if {$size == 1} { return [list "one" ""] }
    if {$comma} { return [list [commas $size] "s"] }
    list $size "s"
}

proc util::humanize {value {suffix B}} {
    if {!$value} {
        return "$value $suffix"
    }
    set factor 1
    if {$value < 0} {
        set factor -1
        set value [expr {$value * $factor}]
    }

    set log_n [expr {int(log($value) / log(1024))}]
    set prefix [lindex [list "" "Ki" "Mi" "Gi" "Ti" "Pi" "Ei" "Zi" "Yi"] \
        $log_n]
    set value [expr {$value / (pow(1024, $log_n))}]
    set value [expr {$value * $factor}]
    set dp [expr {$log_n < 2 ? 0 : 1}]
    return "[format %.${dp}f $value] ${prefix}${suffix}"
}
