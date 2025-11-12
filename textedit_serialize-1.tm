# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define TextEdit method serialize {{file_format .ste}} {
    classvariable STE_PREFIX
    set txt_dump [$Text dump -text -mark -tag 1.0 "end -1 char"]
    if {$file_format eq ".tkt"} {
        return $txt_dump
    }
    set txt_dumpz [zlib deflate [encoding convertto utf-8 $txt_dump] 9]
    if {$file_format eq ".tktz"} {
        return $txt_dumpz
    }
    return $STE_PREFIX$txt_dumpz ;# .ste
}

oo::define TextEdit method deserialize {raw file_format} {
    my clear
    set txt_dump [my GetTxtDump $raw $file_format]
    array set tags {}
    set insert_index end
    set pending [list]
    foreach {key value index} $txt_dump {
        switch $key {
            text { $Text insert $index $value }
            mark { 
                switch $value {
                    current {}
                    insert { set insert_index $index}
                    default { $Text mark set $value $index }
                }
            }
            tagon {
                set tags($value) $index
                lappend pending $value
            }
            tagoff {
                $Text tag add $value $tags($value) $index
                lpop pending
            }
        }
    }
    while {[llength $pending]} {
        set value [lpop pending]
        $Text tag add $value $tags($value) end
    }
    my after_load $insert_index
}

oo::define TextEdit method GetTxtDump {raw file_format} {
    if {$file_format eq ".tkt"} {
        return [encoding convertfrom utf-8 $raw]
    }
    if {$file_format eq ".ste"} {
        set i [string first \n $raw]
        # check here for STE_PREFIX if required
        set raw [string range $raw [incr i] end]
    }
    # elseif $file_format eq ".tktz" then use $raw direct
    encoding convertfrom utf-8 [zlib inflate $raw]
}
