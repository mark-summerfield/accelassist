# Copyright © 2025 Mark Summerfield. All rights reserved.

package require lambda 1
package require textutil

oo::define TextEdit method as_text {} {
    set lines [list]
    foreach line [split [$Text get 1.0 end] \n] {
        lappend lines [textutil::adjust $line -length 76]
    }
    join $lines \n
}

oo::define TextEdit method GetTagDicts {} {
    set tags_on [list]
    set tags_off [list]
    foreach tag [$Text tag names] {
        if {$tag ne "left"} {
            foreach {from to} [$Text tag ranges $tag] {
                lassign [split $from .] frompara fromchar
                lappend tags_on [TextEditTag new $tag $frompara $fromchar]
                lassign [split $to .] topara tochar
                lappend tags_off [TextEditTag new $tag $topara $tochar]
            }
        }
    }
    set tags_on [my MergeTags $tags_on]
    set tags_off [my MergeTags $tags_off]
    list [my DictFromTagList $tags_on] [my DictFromTagList $tags_off]
}

oo::define TextEdit classmethod MergeTags old {
    set new [list]
    set prev ""
    foreach tag [lsort -command TextEditCompareTags $old] {
        if {$prev ne "" && [$prev para] == [$tag para] && \
                [$prev char] == [$tag char]} {
            $prev append [$tag tag]
        } else {
            lappend new $tag
            set prev $tag
        }
    }
    return $new
}

oo::define TextEdit classmethod DictFromTagList tag_list {
    set tag_dict [dict create]
    foreach tag $tag_list {
        dict set tag_dict [$tag para].[$tag char] $tag
    }
    return $tag_dict
}

proc TextEditCompareTags {t u} {
    set paraT [$t para]
    set paraU [$u para]
    if {$paraT < $paraU} { return -1 }
    if {$paraT > $paraU} { return 1 }
    set charT [$t char]
    set charU [$u char]
    if {$charT < $charU} { return -1 }
    if {$charT > $charU} { return 1 }
    string compare [$t tag] [$u tag]
}

oo::class create TextEditTag {
    variable Tags
    variable Para
    variable Char

    constructor {tag para char} {
        set Tags [list $tag]
        set Para $para
        set Char $char
    }

    method tag {} { return [lindex $Tags 0] }
    method tags {} {
        set Tags [lsort -nocase $Tags]
        return $Tags
    }
    method append tag {
        if {$tag eq "bindent1"} {
            if {[set i [lsearch -exact $Tags bindent0]] != -1} {
                ledit Tags $i $i $tag 
                return
            }
        }
        lappend Tags $tag
    }
    method para {} { return $Para }
    method char {} { return $Char }

    method to_string {} { return "TextEditTag: $Para.$Char $Tags" }
}
