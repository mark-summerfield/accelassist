#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.
# License: GPLv3
#
# Tcl 9 port of accelkeys.py / accelhint (Go) / accelhints (Rust).
#
# Given a list of strings (menu options/dialog labels), computes an
# optimal assignment of accelerator keys (indicated by a preceding
# ampersand) using the Kuhn-Munkres (Hungarian) algorithm, so that the
# maximum possible number of strings get a (unique) accelerator, honouring
# any accelerators already preset in the input (marked with '&').

package require munkres

namespace eval ::accelkeys { namespace export ALPHABET accelkeys }

set ::accelkeys::ALPHABET "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"

# accelkeys lines
#
# lines is a Tcl list of strings. Returns a new list of the same length
# where each string has at most one '&' inserted before its accelerator
# letter/digit. Strings that already contain a preset '&' are left as-is.
proc ::accelkeys::accelkeys {lines {alphabet ""}} {
    if {$alphabet eq ""} { set alphabet $::accelkeys::ALPHABET }
    set weights [::accelkeys::_get_weights $lines $alphabet]
    set costMatrix [::munkres::make_cost_matrix $weights]
    set indexes [::munkres::compute $costMatrix]
    ::accelkeys::_update_lines $lines $alphabet $indexes
}

# Build a size x size profit matrix (size == [string length $alphabet]).
# weights(row, col) is the desirability of assigning the col'th letter of
# alphabet as the accelerator for lines(row):
#    1  - the letter occurs anywhere else
#    2  - the letter starts a word (preceded by whitespace)
#    4  - the letter is the first character of the line
#   99 - the letter was already preset with an ampersand in the input
# Rows beyond [llength $lines] (needed to keep the matrix square) and
# columns never matched stay at weight 0.
proc ::accelkeys::_get_weights {lines alphabet} {
    set size [string length $alphabet]
    set weights {}
    for {set initRow 0} {$initRow < $size} {incr initRow} {
        set zeroRow {}
        for {set c 0} {$c < $size} {incr c} { lappend zeroRow 0 }
        lappend weights $zeroRow
    }

    set row 0
    foreach line $lines {
        set prev ""
        set column 0
        foreach ch [split $line ""] {
            set c [string toupper $ch]
            set i [string first $c $alphabet]
            if {$i > -1} {
                if {$column == 0} {
                    set weight 4
                } elseif {$prev eq "&"} {
                    set weight 99
                } elseif {[string is space -strict $prev]} {
                    set weight 2
                } else {
                    set weight 1
                }
                set current [lindex $weights $row $i]
                if {$current < $weight} {
                    set weights [::accelkeys::lreplace_2d $weights $row $i \
                            $weight]
                }
            }
            set prev $c
            incr column
        }
        incr row
    }
    return $weights
}

# Helper: replace element [r][i] of a list-of-lists matrix, returning the
# updated matrix (lset works fine on a nested list variable in place, but
# we take/return a value here to keep _get_weights straightforward).
proc ::accelkeys::lreplace_2d {matrix r i value} {
    set rowList [lindex $matrix $r]
    set rowList [lreplace $rowList $i $i $value]
    lreplace $matrix $r $r $rowList
}

# Apply the Munkres assignment (a list of {row col} pairs) to lines,
# inserting '&' before the chosen accelerator character in each line
# that doesn't already have a preset accelerator.
proc ::accelkeys::_update_lines {lines alphabet indexes} {
    set rows [llength $lines]
    foreach pos $indexes {
        lassign $pos row column
        set c [string index $alphabet $column]
        if {$row >= $rows} continue
        set line [lindex $lines $row]
        if {[string first "&" $line] > -1} continue
        set uline [string toupper $line]
        if {[string index $uline 0] eq $c} {
            set index 0
        } else {
            set index [string first " $c" $uline]
            if {$index > -1} {
                incr index
            } else {
                set index [string first $c $uline]
            }
        }
        if {$index > -1} {
            set newLine "[string range $line 0 \
                    [expr {$index - 1}]]&[string range $line $index end]"
            set lines [lreplace $lines $row $row $newLine]
        }
    }
    return $lines
}

# quality lines
#
# Returns a 0..1 score describing how well lines has been accelerated,
# relative to the theoretical best (every line accelerated at its first
# character, no duplicate accelerators). Raises an error (via 'error')
# for a duplicate accelerator letter, a trailing '&', or an empty list.
proc ::accelkeys::quality lines {
    set target 0.0
    set actual 0.0
    set size [llength $lines]
    set countForChar [dict create]
    set row 0
    foreach line $lines {
        set ideal [expr {25.0 * $size + $row}]
        set target [expr {$target + $ideal}]
        if {[string index $line 0] eq "&"} {
            set actual [expr {$actual + $ideal}]
            set ch [string toupper [string index $line 1]]
            dict set countForChar $ch [dict getdef $countForChar $ch 0]
        } else {
            set factor {}
            set i [string first " &" $line]
            if {$i > -1} {
                set factor 5.0
                incr i 2
            } else {
                set i [string first "&" $line]
                if {$i > -1} {
                    incr i
                    if {$i == [string length $line]} {
                        error "& at end of line"
                    }
                    set factor 1.0
                }
            }
            if {$factor ne {}} {
                set actual [expr {$actual + ($factor * $size) + $row - $i}]
                set ch [string toupper [string index $line $i]]
                dict set countForChar $ch [dict getdef $countForChar $ch 0]
            }
        }
        incr row
    }
    if {!$size} { error "missing lines" }
    dict for {ch count} $countForChar {
        if {$count > 1} { error "&$ch occurs $count times" }
    }
    expr {$actual / $target}
}
