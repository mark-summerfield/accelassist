# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::class create Ref {
    variable Value
    constructor value { set Value $value }
    method get {} { return $Value }
    method set value { set Value $value }
}
