# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define TextEdit initialize {
    variable N 0
    variable STE_PREFIX
    variable FILETYPES
    variable COMMON_WORDS
    variable HIGHLIGHT_COLOR
    variable URL_UL_COLOR
    variable COLOR_FOR_TAG
    variable TAG_FOR_COLOR

    const STE_PREFIX STE1\n

    const FILETYPES {{{ste files} {.ste}} {{tkt files} {.tkt}} \
        {{compressed tkt files} {.tktz}}}

    const COMMON_WORDS {about above access accessories account action \
        active activities activity added additional address adult \
        advanced advertise advertising africa after again against agency \
        agreement along already although always america american among \
        amount analysis annual another application applications april \
        archive archives areas around article articles association audio \
        august australia author availability available average based \
        basic beach beauty because become before being below better \
        between black board books brand browse building business \
        calendar california called camera canada cards cases categories \
        category center central centre change changes chapter cheap \
        check child children china choose church class clear click close \
        collection college color comment comments commercial committee \
        common community companies company compare complete computer \
        computers conditions conference construction contact content \
        control copyright corporate costs could council countries \
        country county course court cover create created credit current \
        currently customer customers daily database david deals death \
        december delivery department description design designed details \
        development different digital direct director directory discount \
        discussion display district document doing domain download \
        downloads drive during early economic edition education effects \
        either electronics email employment energy engineering english \
        enough enter entertainment entry environment environmental \
        equipment error estate europe european event events every \
        everything example experience family features february federal \
        feedback field figure files final finance financial first \
        florida following force format forum forums found france french \
        friday friend friends front function further future gallery \
        games garden general germany getting gifts girls given global \
        going google government great green group groups growth guide \
        hardware having health heart higher history holiday hosting \
        hotel hotels hours house however human image images important \
        include included includes including income increase index india \
        individual industry information insurance interest international \
        internet island issue issues items james january japan journal \
        kingdom knowledge known language large later latest learn \
        learning least legal level library license light limited links \
        linux listed listing listings little living loans local location \
        login london looking lyrics magazine major makes making \
        management manager march market marketing material materials \
        means media medical meeting member members memory message \
        messages method methods michael microsoft might miles million \
        minutes mobile model models monday money month months movie \
        movies music national natural nature needs network never \
        newsletter night north notes notice november number october \
        offer offers office official often online options order orders \
        original other others overall pages paper parts party password \
        payment people percent performance period person personal phone \
        photo photos picture pictures place planning player please point \
        points poker policies policy political popular position possible \
        posted posts power powered practice present president press \
        previous price prices print privacy private problem problems \
        process product production products professional profile program \
        programs project projects property protection provide provided \
        provides public published purchase quality question questions \
        quick quote radio range rates rating reading really receive \
        received recent record records reference region register \
        registered related release remember reply report reports request \
        required requirements research reserved resource resources \
        response result results return review reviews right rights rules \
        safety sales school schools science search second section \
        security select seller september series server service services \
        several shall share shipping shoes shopping short should shows \
        similar simple since single sites small social society software \
        solutions something sound source south space special specific \
        speed sports staff standard standards start state statement \
        states status still stock storage store stores stories story \
        street student students studies study stuff style subject submit \
        subscribe summary support system systems table taken technical \
        technology terms texas thanks their there these thing things \
        think third those though thought thread three through tickets \
        times title today together tools topic topics total track trade \
        training travel treatment under united university until update \
        updated users using usually value various version video videos \
        visit washington watch water weather website weight welcome \
        western where whether which while white whole window windows \
        wireless within without women words working works world would \
        write writing written yahoo years yellow young \
    }

    const HIGHLIGHT_COLOR yellow

    const URL_UL_COLOR #6E1788 ;# darkpurple

    const COLOR_FOR_TAG [dict create \
        black "#000000" \
        grey "#555555" \
        navy "#000075" \
        blue "#0000FF" \
        lavender "#6767E0" \
        cyan "#007272" \
        teal "#469990" \
        olive "#676700" \
        green "#009C00" \
        lime "#608000" \
        maroon "#800000" \
        brown "#9A6324" \
        gold "#9A8100" \
        orange "#CD8400" \
        red "#FF0000" \
        pink "#FF5B77" \
        purple "#911EB4" \
        magenta "#F032E6" \
        ]

    const TAG_FOR_COLOR [dict map {color tag} $COLOR_FOR_TAG {
        set x $color ; set color $tag ; set tag $x }]
}
