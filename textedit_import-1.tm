# Copyright © 2025 Mark Summerfield. All rights reserved.

package require htmlparse 1

oo::define TextEdit method import_text txt {
    my clear
    $Text insert end $txt
    my after_load 1.0
}

oo::define TextEdit method import_html html {
    set html [regsub -all {<b><i>|<i><b>} $html <bi>]
    set html [regsub -all {</b></i>|</i></b>} $html </bi>]
    my clear
    htmlparse::parse -cmd [callback HandleHtmlTag] $html
    my after_load 1.0
}

oo::define TextEdit method HandleHtmlTag {tag slash param txt} {
    classvariable COLOR_FOR_TAG
    classvariable TAG_FOR_COLOR
    const COLOR_TAGS [dict keys $COLOR_FOR_TAG]
    set txt [string trimright [htmlparse::mapEscapes $txt] \n]
    set alignment ""
    set alignment_index ""
    set bold_index ""
    set bolditalic_index ""
    set color_index ""
    set color_tag ""
    set del_index ""
    set highlight_index ""
    set italic_index ""
    set li_index ""
    set sub_index ""
    set sup_index ""
    set ul_index ""
    if {$slash eq ""} {
        switch $tag {
            a {
                if {$txt ne ""} {
                    set prefix file://[file home]
                    if {[string match $prefix* $txt]} {
                        set txt ~[string range $txt \
                            [string length $prefix] end]
                    }
                    $Text insert end $txt
                }
            }
            b {
                if {$txt ne ""} { $Text insert end $txt bold }
                set bold_index [$Text index end]
            }
            bi {
                if {$txt ne ""} { $Text insert end $txt bolditalic }
                set bolditalic_index [$Text index end]
            }
            br {
                $Text insert end [expr {[string trim $txt] eq ""\
                                             ? " " : $txt}]
            }
            del {
                if {$txt ne ""} { $Text insert end $txt strike }
                set del_index [$Text index end]
            }
            div {
                regexp {text-align:\s*(\w+);} $param _ align
                if {[info exists align]} {
                    set alignment $align
                    set alignment_index [$Text index end]
                }
            }
            i {
                if {$txt ne ""} { $Text insert end $txt italic }
                set italic_index [$Text index end]
            }
            li {
                if {$txt ne ""} { $Text insert end "• $txt" bindent0 }
                set li_index [$Text index end]
            }
            p { if {$txt ne ""} { $Text insert end $txt } }
            span {
                if {[regexp {background-color:\s*yellow} $param]} {
                    if {$txt ne ""} { $Text insert end $txt highlight }
                    set highlight_index [$Text index end]
                } else {
                    regexp {color:\s*(#[A-Fa-f0-9]+)} $param _ color
                    if {[info exists color]} {
                        if {[set color_tag [dict getdef $TAG_FOR_COLOR \
                                [string toupper $color] \
                                [lrandom $COLOR_TAGS]]] ne ""} {
                            if {$txt ne ""} {
                                $Text insert end $txt $color_tag
                                set txt ""
                            }
                            set color_index [$Text index end]
                        }
                    }
                    if {$txt ne ""} { $Text insert end $txt }
                }
            }
            sub {
                if {$txt ne ""} { $Text insert end $txt sub }
                set sub_index [$Text index end]
            }
            sup {
                if {$txt ne ""} { $Text insert end $txt sup }
                set sup_index [$Text index end]
            }
            u {
                if {$txt ne ""} { $Text insert end $txt ul }
                set ul_index [$Text index end]
            }
            hmstart - html - head - title - body - meta - ul - ol - style {}
            default {
                puts "unhandled <$tag $param>" ;# debug
            }
        }
    } else {
        switch $tag {
            a {}
            b {
                if {$bold_index ne ""} {
                    $Text tag add bold $bold_index end
                    set bold_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            bi {
                if {$bolditalic_index ne ""} {
                    $Text tag add bolditalic $bolditalic_index end
                    set bolditalic_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            br {
                $Text insert end [expr {[string trim $txt] eq ""\
                                             ? " " : $txt}]
            }
            del {
                if {$del_index ne ""} {
                    $Text tag add strike $del_index end
                    set del_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            div {
                if {$alignment_index ne ""} {
                    $Text tag add $align $alignment_index end
                    set alignment_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            i {
                if {$italic_index ne ""} {
                    $Text tag add italic $italic_index end
                    set italic_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            li {
                if {$li_index ne ""} {
                    $Text tag add bindent0 $li_index end
                    set li_index ""
                }
                if {$txt ne ""} { $Text insert end \n$txt }
            }
            p { $Text insert end $txt\n }
            span {
                if {$highlight_index ne ""} {
                    $Text tag add yellow $highlight_index end
                    set highlight_index ""
                }
                if {$color_index ne "" && $color_tag ne ""} {
                    $Text tag add $color_tag $color_index end
                    set color_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            sub {
                if {$sub_index ne ""} {
                    $Text tag add sub $sub_index end
                    set sub_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            sup {
                if {$sup_index ne ""} {
                    $Text tag add sup $sup_index end
                    set sup_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            u {
                if {$ul_index ne ""} {
                    $Text tag add ul $ul_index end
                    set ul_index ""
                }
                if {$txt ne ""} { $Text insert end $txt }
            }
            hmstart - html - head - title - body - meta - ul - ol - style {}
            default {}
        }
    }
}
