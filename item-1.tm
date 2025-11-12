# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::class create Item {
    variable Term
    variable Index
}

oo::define Item constructor term {
    set Term [string trim $term]
    if {[set Index [string first & [regsub -all -- && $Term ..]]] != -1} {
        set Term [string replace $Term $Index $Index]
    }
}

oo::define Item method term {} { return $Term }
oo::define Item method set_term term { set Term $term }

oo::define Item method index {} { return $Index }
oo::define Item method set_index index { set Pos $index }

oo::define Item method done {} { expr {$Index != -1} }

oo::define Item method char {} {
    if {$Index == -1} { return "" }
    string toupper [string index $Term $Index]
}

oo::define Item method set_char c {
    set term [string toupper $Term]
    set Index [string first $c $term]
}

oo::define Item method size {} {
    string length [regsub -all -- & [regsub -all -- && $Term ..] ""]
}

oo::define Item method compare other {
    set asize [my size]
    set bsize [$other size]
    if {$asize < $bsize} { return -1 }
    if {$asize > $bsize} { return 1 }
    set aterm [my term]
    set bterm [$other term]
    set awords [llength [split $aterm]]
    set bwords [llength [split $bterm]]
    if {$awords < $bwords} { return -1 }
    if {$awords > $bwords} { return 1 }
    string compare [string tolower $aterm] [string tolower $bterm]
}

oo::define Item method candidates {} {
    set chars [list]
    if {$Index != -1} { return $chars }
    foreach word [split $Term] {
        set c [string toupper [string index $word 0]]
        if {[string is alpha $c]} {
            lappend chars $c
        }
    }
    return $chars
}

oo::define Item method to_string {} {
    return "Item Term=$Term Index=$Index"
}
