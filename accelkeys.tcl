#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require accelkeys

proc main {} {
    set showQuality 0
    set filenames [list]
    foreach arg $::argv {
        switch $arg {
            -h - --help { puts $::USAGE }
            -q - --quality { set showQuality 1 }
            default { lappend filenames $arg }
        }
    }
    if {[llength $filenames]} {
        foreach filename $filenames {
            process_text [readFile $filename] $showQuality
        }
    } else {
        puts $::USAGE
    }
}

proc process_text {text showQuality} {
    set lines [list]
    foreach line [split $text \n] {
        set line [string trim $line]
        if {$line eq ""} {
            process_list $lines $showQuality
            set lines [list]
        } elseif {![string match "#*" $line]} {
            lappend lines $line
        }
    }
    process_list $lines $showQuality
}

proc process_list {lines showQuality} {
    if {[llength $lines] == 0} { return }
    set result [::accelkeys::accelkeys $lines]
    foreach line $result { puts $line }
    if {$showQuality} {
        set quality [::accelkeys::quality $result]
        puts [format "# Quality = %.0f%%" [expr {$quality * 100}]]
    }
    puts ""
}

const USAGE {usage: accelkeys.tcl [-q|--quality] items.txt >out.txt

The input is just plain text lines with one item per line and with any
preset accelerators preceded by an ampersand.
If you want to have multiple lists (e.g., File menu, Edit menu, a dialog,
etc.), just separate each list with a blank line.
Comments may be included on lines that begin with '#'.

If the quality flag is present each list will be followed by a quality %.

Example input | Expected output
--------------+----------------
Undo          |&Undo
Redo          |&Redo
Copy          |&Copy
Cu&t          |Cu&t
Paste         |&Paste
Find          |&Find
Find Again    |Find &Again}


main
