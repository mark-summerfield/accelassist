# Copyright © 2025 Mark Summerfield. All rights reserved.

package require util

oo::define TextEdit method on_undo {} {
    if {[$Text edit canundo]} { $Text edit undo }
}

oo::define TextEdit method on_redo {} {
    if {[$Text edit canredo]} { $Text edit redo }
}

oo::define TextEdit method on_copy {} { tk_textCopy $Text }

oo::define TextEdit method on_cut {} { tk_textCut $Text }

oo::define TextEdit method on_paste {} { tk_textPaste $Text }

oo::define TextEdit method on_bs {} {
    set i [$Text index "insert linestart"]
    set j [$Text index "insert lineend"]
    set line [$Text get $i $j]
    if {[regexp {^•\s+$} $line]} {
        set i [$Text index "$i -1 char"]
        set j [$Text index "$j +1 char"]
        $Text tag remove NtextTab $i $j
        $Text tag remove bindent0 $i $j
        $Text tag remove bindent1 $i $j
    }
}

oo::define TextEdit method on_ctrl_del {} {
    set i [$Text index "insert +1 char"]
    set x [$Text index "$i wordstart"]
    set y [$Text index "$x wordend"]
    $Text delete $x $y
}

oo::define TextEdit method on_ctrl_a {} { $Text tag add sel 1.0 end }

oo::define TextEdit method on_ctrl_bs {} {
    set i [$Text index "insert -1 char"]
    set x [$Text index "$i wordstart"]
    set y [$Text index "$x wordend"]
    $Text delete $x $y
}

oo::define TextEdit method on_no_list {} {
    set i [$Text index "insert linestart"]
    set j [$Text index "insert lineend"]
    set i [$Text index "$i -1 char"]
    set j [$Text index "$j +1 char"]
    $Text tag remove NtextTab $i $j
    $Text tag remove bindent0 $i $j
    $Text tag remove bindent1 $i $j
}

oo::define TextEdit method on_ctrl_return {} {
    $Text insert insert \n
    my on_no_list
    return -code break
}

oo::define TextEdit method on_return {} {
    set i [$Text index "insert -1 char"]
    set i [$Text index "$i linestart"]
    set line [$Text get $i "$i lineend"]
    $Text insert insert \n
    regexp {^\s*•\s+} $line bullet
    regexp {^\s+} $line ws
    if {[info exists bullet] && $bullet ne ""} {
        if {"bindent1" in [$Text tag names insert] || \
                ([info exists ws] && $ws ne "")} {
            $Text insert insert "• " bindent1
        } else {
            $Text insert insert "• " bindent0
        }
    } elseif {[info exists ws] && $ws ne ""} {
        $Text insert insert ${ws}
    }
    return -code break
}

oo::define TextEdit method on_tab {{user true}} {
    set p [$Text index "insert -1 char"]
    set i [$Text index "$p linestart"]
    set j [$Text index "$i lineend"]
    set line [$Text get $i $j]
    if {[string match "• " $line]} {
        $Text tag add bindent1 $i "$j +1 char"
        if {$user} { return -code break }
    }
    if {$Completion && [my TryCompletion $p] && $user} {
        return -code break
    }
}

oo::define TextEdit method TryCompletion p {
    classvariable COMMON_WORDS
    set i $p
    set i [$Text index "$p wordstart"]
    set j [$Text index "$i wordend"]
    set prefix [string tolower [$Text get $i $j]]
    if {[string trim $prefix] eq ""} { return false }
    set candidates [dict create]
    foreach word [list {*}$COMMON_WORDS {*}[split [$Text get 1.0 end]]] {
        set word [regsub {^\W+} [regsub {\W+$} $word ""] ""]
        set lword [string tolower $word]
        if {$lword ne "" && $prefix ne $lword && \
                [string match $prefix* $lword]} {
            dict set candidates $lword $word
        }
    }
    set possibles [lsort [dict keys $candidates]]
    switch [llength $possibles] {
        0 {}
        1 {
            set word [lindex $possibles 0]
            $Text insert insert \
                [string range $word [string length $prefix] end]
        }
        default {
            set size [string length $prefix]
            set possibles [lsort -command [callback ByLength] $possibles]
            $CompletionMenu delete 0 end 
            set n 0
            foreach lword $possibles {
                if {$n > 9 || [string length $lword] <= $size} { break }
                if {$lword eq ""} { continue }
                set word [dict get $candidates $lword]
                $CompletionMenu add command -label "$n $word" -underline 0 \
                    -command [callback Complete \
                        [string range $word [string length $prefix] end]]
                incr n
            }
            lassign [$Text bbox insert] x y
            tk_popup $CompletionMenu \
                [expr {[winfo rootx $Text] + $x + 3}] $y
        }
    }
    return true
}

# longest to shortest or compare strings for tie-break
oo::define TextEdit classmethod ByLength {a b} {
    set asize [string length $a]
    set bsize [string length $b]
    if {$asize < $bsize} { return 1 }
    if {$asize > $bsize} { return -1 }
    string compare $a $b
}

oo::define TextEdit method Complete word { $Text insert insert $word }

oo::define TextEdit method on_single_quote {} {
    $Text insert insert ’
    return -code break
}

oo::define TextEdit method on_double_click {} {
    set url [my get_whole_word]
    if {[string match ~* $url]} {
        set url file://[file home][string range $url 1 end]
    }
    if {[regexp {^(?:file|https?)://} $url]} {
        my highlight_urls
        util::open_url $url
    }
}
