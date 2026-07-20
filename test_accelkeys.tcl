#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.
# License: GPLv3
#
# test_accelkeys.tcl -- mirrors test_accelkeys.py: reads input.txt /
# expected.txt as blank-line separated paragraphs, runs accelkeys on
# each, and checks both the exact output and the quality score.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require accelkeys
package require munkres


proc read_lists filename {
    set fh [open $filename r]
    fconfigure $fh -encoding utf-8
    set text [read $fh]
    close $fh

    set lists {}
    set current {}
    foreach line [split $text "\n"] {
        set trimmed [string trim $line]
        if {$trimmed eq ""} {
            lappend lists $current
            set current {}
        } elseif {![string match "#*" $trimmed]} {
            lappend current $trimmed
        }
    }
    lappend lists $current
    return $lists
}

set qualities {
    0.75 0.75 0.71 0.33 0.58 0.62 0.72 1 1 0.81 0.65
    0.48 0.62 0.64 0.55 0.61 0.49 0.55 0.63 0.55 0.63
    0.81 0.53 0.57 0.67 0.75 0.62 0.56 0.57 0.57 0.49
    0.0
}

set inputs [read_lists $::APPPATH/input.txt]
set expecteds [read_lists $::APPPATH/expected.txt]

if {[llength $inputs] != [llength $expecteds]} {
    puts "FAIL: input.txt has [llength $inputs] lists but expected.txt has\
          [llength $expecteds]"
    exit 1
}

set failures 0
set checked 0
for {set i 0} {$i < [llength $inputs]} {incr i} {
    set lines [lindex $inputs $i]
    if {[llength $lines] == 0} continue
    incr checked

    set actual [accelkeys::accelkeys $lines]
    set expected [lindex $expecteds $i]

    set ok 1
    if {$actual ne $expected} {
        set ok 0
        puts "FAIL list #[expr {$i + 1}]:"
        puts "  A=$actual"
        puts "  E=$expected"
    }

    set expectedQuality [lindex $qualities $i]
    set actualQuality [accelkeys::quality $actual]
    if {abs($actualQuality - $expectedQuality) > 0.005} {
        set ok 0
        puts "FAIL list #[expr {$i + 1}] quality: got\
              [format %.2f $actualQuality], want\
              [format %.2f $expectedQuality]"
    }

    if {!$ok} {
        incr failures
    }
}

puts -nonewline "Checked $checked non-empty lists, $failures failed."
if {$failures > 0} { puts "" ; exit 1 }
puts " OK."
