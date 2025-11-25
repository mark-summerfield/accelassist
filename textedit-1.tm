# Copyright © 2025 Mark Summerfield. All rights reserved.

package require html 1
package require ntext 1
package require ui

oo::class create TextEdit {
    variable Frame
    variable Text
    variable Completion
    variable CompletionMenu
    variable ContextMenu
}

package require textedit_actions
package require textedit_export
package require textedit_export_html
package require textedit_import
package require textedit_initialize
package require textedit_serialize

oo::define TextEdit classmethod make_color_menu {the_menu the_callback} {
    #              K E N B L C T V G I A W D O R P U M
    const INDEXES {4 2 0 0 0 0 0 3 0 1 1 3 3 0 0 0 1 0}
    foreach index $INDEXES {name color} [TextEdit colors] {
        $the_menu add command -underline $index \
            -image [my swatch $color $::MENU_ICON_SIZE] \
            -compound left -label [string totitle $name] \
            -command "$the_callback $name"
    }
}

oo::define TextEdit classmethod swatch {color size} {
    const R [expr {max(3, $size / 4.0)}]
    const W [expr {$R + 2.5}]
    image create photo -data "<svg width=\"$size\" height=\"$size\">
        <rect x=\"0\" y=\"0\" width=\"$size\" height=\"$size\" rx=\"$R\"
        ry=\"$R\" fill=\"$color\" stroke-width=\"$W\" stroke=\"white\">
        </svg>"
}

oo::define TextEdit constructor {parent {family ""} {size 0}} {
    classvariable N
    if {![string match *. $parent]} { set parent $parent. }
    set Frame ${parent}tf#[incr N] ;# unique
    ttk::frame $Frame
    set Text [text $Frame.txt -undo true -wrap word]
    set Completion true
    set CompletionMenu [menu $Frame.completionMenu]
    my MakeContextMenu
    my MakeBindings
    my make_fonts $family $size
    my make_tags
    ui::scrollize $Frame txt vertical
}

oo::define TextEdit method completion {} { return $Completion }

oo::define TextEdit method set_completion value { set Completion $value }

oo::define TextEdit method MakeContextMenu {} {
    set ContextMenu [menu $Frame.contextMenu]
    $ContextMenu add command -command [callback apply_style highlight] \
        -label Highlight -underline 0 -compound left \
        -image [ui::icon draw-highlight.svg $::MENU_ICON_SIZE]
    $ContextMenu add separator
    my make_color_menu $ContextMenu [callback apply_color]
}

oo::define TextEdit method MakeBindings {} {
    bindtags $Text [list $Text Ntext [winfo toplevel $Text] all]
    bind $Text <<ContextMenu>> "tk_popup $ContextMenu %X %Y"
    bind $Text <BackSpace> [callback on_bs]
    bind $Text <Control-Delete> [callback on_ctrl_del]
    bind $Text <Control-BackSpace> [callback on_ctrl_bs]
    bind $Text <Control-a> [callback on_ctrl_a]
    bind $Text <Double-1> [callback on_double_click]
    bind $Text <Control-Return> [callback on_ctrl_return]
    bind $Text <Return> [callback on_return]
    bind $Text <Tab> [callback on_tab]
    bind $Text <'> [callback on_single_quote]
}

oo::define TextEdit method make_fonts {family size} {
    if {$family eq ""} {
        set family [font configure TkDefaultFont -family]
    }
    if {!$size} {
        set size [expr {1 + [font configure TkDefaultFont -size]}]
    }
    foreach name {Sans Small Bold Italic BoldItalic} {
        catch { font delete $name }
    }
    font create Sans -family $family -size $size
    font create Small -family $family \
        -size [expr {int(round($size * 0.75))}]
    font create Bold -family $family -size $size -weight bold
    font create Italic -family $family -size $size -slant italic
    font create BoldItalic -family $family -size $size -weight bold \
        -slant italic
    set tab [expr {4 * [font measure Sans n]}]
    $Text configure -font Sans -tabstyle wordprocessor -tabs "$tab left"
}

oo::define TextEdit method make_tags {} {
    classvariable URL_UL_COLOR
    classvariable HIGHLIGHT_COLOR
    classvariable COLOR_FOR_TAG
    $Text tag configure sub -font Small -offset -3p
    $Text tag configure sup -font Small -offset 3p
    $Text tag configure ul -underline true
    $Text tag configure strike -overstrike true -overstrikefg #FF1A1A
    $Text tag configure center -justify center
    $Text tag configure right -justify right
    $Text tag configure url -underline true -underlinefg $URL_UL_COLOR
    $Text tag configure bold -font Bold
    $Text tag configure italic -font Italic
    $Text tag configure bolditalic -font BoldItalic
    $Text tag configure highlight -background $HIGHLIGHT_COLOR
    set bwidth [font measure Sans "• "]
    set twidth [font measure Sans "nnnn"]
    # DEBUG: -background #E0FFFF
    $Text tag configure bindent0 -lmargin2 $bwidth
    # DEBUG: -background #ADFFFF
    $Text tag configure bindent1 -lmargin1 $twidth \
        -lmargin2 [expr {$twidth + $bwidth}]
    dict for {key value} $COLOR_FOR_TAG {
        $Text tag configure $key -foreground $value
    }
}

oo::define TextEdit classmethod filetypes {} {
    variable FILETYPES
    return $FILETYPES
}

oo::define TextEdit classmethod colors {} {
    variable COLOR_FOR_TAG
    return $COLOR_FOR_TAG
}

oo::define TextEdit method unknown {the_method args} {
    $Text $the_method {*}$args
}

oo::define TextEdit method focus {} { focus $Text }

oo::define TextEdit method ttk_frame {} { return $Frame }

oo::define TextEdit method tk_text {} { return $Text }

oo::define TextEdit method isempty {} {
    expr {[string trim [$Text get 1.0 end]] eq ""}
}

oo::define TextEdit method clear {} {
    $Text delete 1.0 end
    $Text edit reset
    $Text edit modified false
}

oo::define TextEdit method after_load {{index insert}} {
    my highlight_urls
    $Text edit reset
    $Text edit modified false
    if {$index ne "insert"} { $Text mark set insert $index }
    $Text see $index
}

oo::define TextEdit method first_line {} { string trim [$Text get 1.0 2.0] }

oo::define TextEdit method highlight_urls {} {
    foreach i [$Text search -all -regexp {(?:https?://|~/)} 1.0] {
        set j [$Text search -regexp {[\s>]} $i]
        if {[$Text get "$j -1 char"] eq "."} {
            set j [$Text index "$j -1 char"]
        }
        $Text tag add url $i $j
    }
}

oo::define TextEdit method selected {} {
    if {[set indexes [$Text tag ranges sel]] ne ""} {
        return $indexes
    }
    return "[$Text index "insert wordstart"] [$Text index "insert wordend"]"
}

oo::define TextEdit method get_whole_word {} {
    set a [$Text index "insert linestart"]
    set b [$Text index "insert lineend"]
    set c [$Text index "insert wordstart"]
    set i [$Text search -backwards -exact " " $c "$a -1 char"]
    if {$i eq ""} { set i $a }
    set j [$Text search -exact " " insert "$b +1 char"]
    if {$j eq ""} { set j [$Text index $b] }
    string trim [string trimright [$Text get $i $j] ",;:!?."]
}

oo::define TextEdit method apply_style style {
    my apply_style_to [my selected] $style
}

oo::define TextEdit method apply_style_to {indexes style} {
    if {$indexes ne ""} {
        set tags [$Text tag names [lindex $indexes 0]]
        if {$style eq "bold" && "bolditalic" in $tags} {
            $Text tag remove bolditalic {*}$indexes
            $Text tag add italic {*}$indexes
        } elseif {$style eq "italic" && "bolditalic" in $tags} {
            $Text tag remove bolditalic {*}$indexes
            $Text tag add bold {*}$indexes
        } elseif {($style eq "bold" && "italic" in $tags) ||
                  ($style eq "italic" && "bold" in $tags)} {
            $Text tag remove bold {*}$indexes
            $Text tag remove italic {*}$indexes
            $Text tag add bolditalic {*}$indexes
        } elseif {$style eq "bold" && "bold" in $tags} {
            $Text tag remove bold {*}$indexes
        } elseif {$style eq "italic" && "italic" in $tags} {
            $Text tag remove italic {*}$indexes
        } elseif {$style eq "highlight" && "highlight" in $tags} {
            $Text tag remove highlight {*}$indexes
        } elseif {$style eq "sub" && "sub" in $tags} {
            $Text tag remove sub {*}$indexes
        } elseif {$style eq "sup" && "sup" in $tags} {
            $Text tag remove sup {*}$indexes
        } elseif {$style eq "ul" && "ul" in $tags} {
            $Text tag remove ul {*}$indexes
        } elseif {$style eq "strike" && "strike" in $tags} {
            $Text tag remove strike {*}$indexes
        } else {
            $Text tag add $style {*}$indexes
        }
        $Text edit modified true
    }
}

oo::define TextEdit method apply_align align {
    set i [$Text index "insert linestart"]
    set j [$Text index "insert lineend"]
    my apply_align_to [list $i $j] $align
}

oo::define TextEdit method apply_align_to {indexes align} {
    if {$indexes ne ""} {
        if {$align eq "left"} {
            $Text tag remove center {*}$indexes
            $Text tag remove right {*}$indexes
        } else {
            set tags [$Text tag names [lindex $indexes 0]]
            if {$align eq "center" && "center" in $tags} {
                $Text tag remove center {*}$indexes
            } elseif {$align eq "right" && "right" in $tags} {
                $Text tag remove right {*}$indexes
            } else {
                if {$align eq "center" && "right" in $tags} {
                    $Text tag remove right {*}$indexes
                } elseif {$align eq "right" && "center" in $tags} {
                    $Text tag remove center {*}$indexes
                }
                $Text tag add $align {*}$indexes
            }
        }
        $Text edit modified true
    }
}

oo::define TextEdit method apply_color color {
    my apply_color_to [my selected] $color
}

oo::define TextEdit method apply_color_to {indexes color} {
    classvariable COLOR_FOR_TAG
    foreach tag [dict keys $COLOR_FOR_TAG] {
        $Text tag remove $tag {*}$indexes
    }
    if {$color ne "black"} {
        $Text tag add $color {*}$indexes
    }
    $Text edit modified true
}
