#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.
# License: GPLv3
#
# Kuhn-Munkres (Hungarian) algorithm for the assignment problem.
# A faithful Tcl 9 port of the algorithm used by Brian Clapper's Python
# "munkres" package (itself the classic O(n^3) Munkres/Hungarian method),
# restricted to square matrices (which is all accelkeys needs).

namespace eval ::munkres { namespace export compute make_cost_matrix }

# ::munkres::compute costMatrix
#
# costMatrix is a list of n lists, each of n numbers (a square matrix).
# Returns a list of {row col} pairs describing the minimum-cost
# assignment (one column per row).
proc ::munkres::compute costMatrix {
    if {![set n [llength $costMatrix]]} { return }

    array set C {}
    array set marked {}
    array set rowCovered {}
    array set colCovered {}

    for {set i 0} {$i < $n} {incr i} {
        set rowList [lindex $costMatrix $i]
        if {[llength $rowList] != $n} {
            error "munkres::compute requires a square matrix\
                   (row $i has [llength $rowList] columns, expected $n)"
        }
        set rowCovered($i) 0
        set colCovered($i) 0
        for {set j 0} {$j < $n} {incr j} {
            set C($i,$j) [lindex $rowList $j]
            set marked($i,$j) 0
        }
    }

    set Z0r 0
    set Z0c 0
    set step 1

    while {$step ne "done"} {
        switch -- $step {
            1 { set step [::munkres::_step1 C $n] }
            2 {
                set step [::munkres::_step2 C marked rowCovered colCovered \
                        $n]
            }
            3 { set step [::munkres::_step3 marked colCovered $n] }
            4 {
                set step [::munkres::_step4 C marked rowCovered colCovered \
                        $n Z0r Z0c]
            }
            5 {
                set step [::munkres::_step5 marked rowCovered colCovered \
                        $n $Z0r $Z0c]
            }
            6 { set step [::munkres::_step6 C rowCovered colCovered $n] }
            7 - done { set step done }
            default {
                error "munkres::compute: internal error, bad step '$step'"
            }
        }
    }

    set results {}
    foreach i [lseq $n] {
        foreach j [lseq $n] {
            if {$marked($i,$j) == 1} { lappend results [list $i $j] }
        }
    }
    return $results
}

# For each row, find the smallest element and subtract it from every
# element in its row. Go to Step 2.
proc ::munkres::_step1 {C_name n} {
    upvar 1 $C_name C

    foreach i [lseq $n] {
        set minval $C($i,0)
        for {set j 1} {$j < $n} {incr j} {
            if {$C($i,$j) < $minval} { set minval $C($i,$j) }
        }
        foreach j [lseq $n] { set C($i,$j) [expr {$C($i,$j) - $minval}] }
    }
    return 2
}

# Find a zero (Z) in the resulting matrix. If there is no starred zero
# in its row or column, star Z. Repeat for each element in the matrix.
# Go to Step 3.
proc ::munkres::_step2 {C_name marked_name rowCovered_name colCovered_name \
        n} {
    upvar 1 $C_name C
    upvar 1 $marked_name marked
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered

    foreach i [lseq $n] {
        foreach j [lseq $n] {
            if {$C($i,$j) == 0 && !$colCovered($j) && !$rowCovered($i)} {
                set marked($i,$j) 1
                set colCovered($j) 1
                set rowCovered($i) 1
                break
            }
        }
    }
    ::munkres::_clearCovers rowCovered colCovered $n
    return 3
}

# Cover each column containing a starred zero. If all n columns are
# covered, the starred zeros describe a complete set of unique
# assignments: go to DONE (7). Otherwise go to Step 4.
proc ::munkres::_step3 {marked_name colCovered_name n} {
    upvar 1 $marked_name marked
    upvar 1 $colCovered_name colCovered

    set count 0
    foreach i [lseq $n] {
        foreach j [lseq $n] {
            if {$marked($i,$j) == 1 && !$colCovered($j)} {
                set colCovered($j) 1
                incr count
            }
        }
    }
    if {$count >= $n} { return 7 }
    return 4
}

# Find a noncovered zero and prime it. If there is no starred zero in
# the row containing this primed zero, go to Step 5. Otherwise, cover
# this row and uncover the column containing the starred zero. Continue
# until there are no uncovered zeros left; go to Step 6.
proc ::munkres::_step4 {C_name marked_name rowCovered_name colCovered_name \
        n Z0r_name Z0c_name} {
    upvar 1 $C_name C
    upvar 1 $marked_name marked
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered
    upvar 1 $Z0r_name Z0r
    upvar 1 $Z0c_name Z0c

    set row 0
    set col 0
    while {1} {
        lassign [::munkres::_findAZero C rowCovered colCovered $n $row \
                $col] row col
        if {$row < 0} { return 6 }
        set marked($row,$col) 2
        set starCol [::munkres::_findStarInRow marked $n $row]
        if {$starCol >= 0} {
            set col $starCol
            set rowCovered($row) 1
            set colCovered($col) 0
        } else {
            set Z0r $row
            set Z0c $col
            return 5
        }
    }
}

# Construct a series of alternating primed and starred zeros as follows.
# Let Z0 be the uncovered primed zero found in Step 4. Let Z1 be the
# starred zero in the column of Z0 (if any). Let Z2 be the primed zero
# in the row of Z1 (there will always be one). Continue until the series
# terminates at a primed zero that has no starred zero in its column.
# Unstar each starred zero of the series, star each primed zero of the
# series, erase all primes, and uncover every line. Return to Step 3.
proc ::munkres::_step5 {marked_name rowCovered_name colCovered_name n Z0r \
        Z0c} {
    upvar 1 $marked_name marked
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered

    array set pathR {}
    array set pathC {}
    set count 0
    set pathR($count) $Z0r
    set pathC($count) $Z0c

    while {1} {
        set row [::munkres::_findStarInCol marked $n $pathC($count)]
        if {$row < 0} { break }
        incr count
        set pathR($count) $row
        set pathC($count) $pathC([expr {$count - 1}])

        set col [::munkres::_findPrimeInRow marked $n $pathR($count)]
        incr count
        set pathR($count) $pathR([expr {$count - 1}])
        set pathC($count) $col
    }

    ::munkres::_convertPath marked pathR pathC $count
    ::munkres::_clearCovers rowCovered colCovered $n
    ::munkres::_erasePrimes marked $n
    return 3
}

# Add the value found (the smallest uncovered value) to every element
# of each covered row, and subtract it from every element of each
# uncovered column. Return to Step 4 without altering stars, primes, or
# covered lines.
proc ::munkres::_step6 {C_name rowCovered_name colCovered_name n} {
    upvar 1 $C_name C
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered

    set minval [::munkres::_findSmallest C rowCovered colCovered $n]
    foreach i [lseq $n] {
        foreach j [lseq $n] {
            if {$rowCovered($i)} {
                set C($i,$j) [expr {$C($i,$j) + $minval}]
            }
            if {!$colCovered($j)} {
                set C($i,$j) [expr {$C($i,$j) - $minval}]
            }
        }
    }
    return 4
}

proc ::munkres::_findSmallest {C_name rowCovered_name colCovered_name n} {
    upvar 1 $C_name C
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered

    set minval {}
    foreach i [lseq $n] {
        if {$rowCovered($i)} continue
        foreach j [lseq $n] {
            if {$colCovered($j)} continue
            if {$minval eq {} || $C($i,$j) < $minval} {
                set minval $C($i,$j)
            }
        }
    }
    if {$minval eq {}} {
        error "munkres: matrix cannot be solved (no uncovered elements)"
    }
    return $minval
}

# Find the first uncovered zero, searching row-major starting at
# (i0, j0) and wrapping around -- matching the reference implementation.
proc ::munkres::_findAZero {C_name rowCovered_name colCovered_name n i0 \
        j0} {
    upvar 1 $C_name C
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered

    set row -1
    set col -1
    set i $i0
    set done 0

    while {!$done} {
        set j $j0
        while {1} {
            if {$C($i,$j) == 0 && !$rowCovered($i) && !$colCovered($j)} {
                set row $i
                set col $j
                set done 1
            }
            set j [expr {($j + 1) % $n}]
            if {$j == $j0} break
        }
        set i [expr {($i + 1) % $n}]
        if {$i == $i0} { set done 1 }
    }
    list $row $col
}

proc ::munkres::_findStarInRow {marked_name n row} {
    upvar 1 $marked_name marked
    foreach j [lseq $n] { if {$marked($row,$j) == 1} { return $j } }
    return -1
}

proc ::munkres::_findStarInCol {marked_name n col} {
    upvar 1 $marked_name marked
    foreach i [lseq $n] { if {$marked($i,$col) == 1} { return $i } }
    return -1
}

proc ::munkres::_findPrimeInRow {marked_name n row} {
    upvar 1 $marked_name marked
    foreach j [lseq $n] { if {$marked($row,$j) == 2} { return $j } }
    return -1
}

proc ::munkres::_convertPath {marked_name pathR_name pathC_name count} {
    upvar 1 $marked_name marked
    upvar 1 $pathR_name pathR
    upvar 1 $pathC_name pathC

    for {set i 0} {$i <= $count} {incr i} {
        set r $pathR($i)
        set c $pathC($i)
        if {$marked($r,$c) == 1} {
            set marked($r,$c) 0
        } else {
            set marked($r,$c) 1
        }
    }
}

proc ::munkres::_clearCovers {rowCovered_name colCovered_name n} {
    upvar 1 $rowCovered_name rowCovered
    upvar 1 $colCovered_name colCovered
    foreach i [lseq $n] {
        set rowCovered($i) 0
        set colCovered($i) 0
    }
}

proc ::munkres::_erasePrimes {marked_name n} {
    upvar 1 $marked_name marked
    foreach i [lseq $n] {
        foreach j [lseq $n] {
            if {$marked($i,$j) == 2} { set marked($i,$j) 0 }
        }
    }
}

# ::munkres::make_cost_matrix profitMatrix ?maximum?
#
# Converts a profit (weight) matrix into a cost matrix suitable for
# ::munkres::compute, using cost = maximum - profit for every cell.
# If maximum isn't supplied, it defaults to the largest value in the
# matrix (matching the Python munkres.make_cost_matrix default).
proc ::munkres::make_cost_matrix {profitMatrix {maximum {}}} {
    if {$maximum eq {}} {
        set maximum {}
        foreach row $profitMatrix {
            foreach value $row {
                if {$maximum eq {} || $value > $maximum} {
                    set maximum $value
                }
            }
        }
    }
    set costMatrix {}
    foreach row $profitMatrix {
        set costRow {}
        foreach value $row { lappend costRow [expr {$maximum - $value}] }
        lappend costMatrix $costRow
    }
    return $costMatrix
}
