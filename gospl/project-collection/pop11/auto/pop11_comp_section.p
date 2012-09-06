;;; Summary: service function for module/endmodule syntax

;;; Implements the publish/subscribe section syntax.  Slightly
;;; generalised to support the module/endmodule syntax.

uses section_publish;
uses section_subscribe;

section;
compile_mode :pop11 +strict;

lconstant keywords = [ import export publish subscribe ];

define lconstant Apply_subscribes( subscribes ); lvars subscribes;
    lvars sect, prefix;
    ncrev( subscribes ) -> subscribes;
    until subscribes == [] do
        dest( subscribes ) -> subscribes -> sect;
        if subscribes.ispair and front( subscribes ).isword then
            dest( subscribes ) -> subscribes
        else
            false
        endif -> prefix;
        section_subscribe( sect, prefix );
    enduntil;
enddefine;

define lconstant Check_word( item ) -> item; lvars item;
    unless isword( item ) then
        mishap( item, 1, 'IMPERMISSIBLE ITEM IN section STATEMENT' )
    endunless;
enddefine;

define global pop11_comp_section( closing_keyword ); lvars closing_keyword;
    dlocal current_section;
    lvars item, exports, imports, subscribes;

    define lconstant Read_subscribe( item ); lvars item;
        conspair(
            sys_read_path( item, false, true ),
            subscribes
        ) -> subscribes;
        if pop11_try_nextreaditem( "with_prefix" ) then
            conspair( Check_word( readitem() ), subscribes ) -> subscribes;
        endif;
    enddefine;

    define lconstant read_exports();
        until
            ( readitem() ->> item ) == ";" or
            ( lmember( item, keywords ) and pop11_try_nextreaditem( ":" ) )
        do
            unless item == "," then
                conspair( Check_word( item ), exports ) -> exports;
            endunless;
        enduntil;
    enddefine;

    define lconstant read_imports();
        until
            ( readitem() ->> item ) == ";" or item == "=>" or
            ( lmember( item, keywords ) and pop11_try_nextreaditem(":") )
        do
            unless item == "," then
                conspair( Check_word(item), imports ) -> imports;
            endunless;
        enduntil;
    enddefine;

    lvars publishes = undef;

    if ( readitem() ->> item ) == "=>" then
        mishap( 0, 'MISSING SECTION NAME' )
    elseif item == "subscribe" and pop11_try_nextreaditem( ":" ) then
        ;;; transporting variables from a section to the toplevel section.
        [] -> subscribes;
        until ( readitem() ->> item ) == ";" do
            ;;; we only parse subscriptions
            Read_subscribe( item );
            pop11_try_nextreaditem( "," ).erase;
        enduntil;
        pop_section -> current_section;
        Apply_subscribes( subscribes );
    elseunless item == ";" then
        ;;; not the top-level section

        lvars anon = item == "_";
        lvars sect_list = sys_read_path( item, false, [] );
        [] ->> imports ->> exports ->> publishes -> subscribes;

        read_imports();
        if item == "=>" then
            read_exports()
        endif;

        repeat
            if item == "import" and poplastitem == ":" then
                read_imports()
            elseif item == "export" and poplastitem == ":" then
                read_exports()
            elseif item == "subscribe" and poplastitem == ":" then
                until
                    ( readitem() ->> item ) == ";" or
                    lmember( item, keywords ) and
                    pop11_try_nextreaditem( ":" )
                do
                    Read_subscribe( item );
                    pop11_try_nextreaditem( "," ).erase;
                enduntil;
            elseif item == "publish" and poplastitem == ":" then
                until
                    ( readitem() ->> item ) == ";" or
                    lmember( item, keywords ) and
                    pop11_try_nextreaditem( ":" )
                do
                    unless item == "," then
                        conspair( Check_word( item ), publishes ) -> publishes;
                    endunless;
                enduntil;
            else
                unless item == ";" do
                    item :: proglist -> proglist;
                    pop11_need_nextreaditem( ";" ).erase;  ;;; Get right error.
                endunless;
                quitloop
            endif;
        endrepeat;

        ;;; Cope with imports and exports.  Note that this magically
        ;;; leaves us in the correct section.
        for item in sect_list do
            item -> current_section;
            if item /== pop_section then
                applist( imports, section_import );
                applist( exports, section_export )
            endif;
        endfor;

        ;;; do the subscribes
        Apply_subscribes( subscribes );
        ;;; define the published names
        applist( publishes, section_publish );
    else
        ;;; the top-level
        pop_section -> current_section
    endif;
    if popclosebracket == popclosebracket_exec then
        pop11_exec_stmnt_seq_to
    else
        pop11_comp_stmnt_seq_to
    endif( closing_keyword ).erase;
    if anon then
        ;;; This guard never applies - just defensive programming.
        unless current_section == pop_section do
            section_cancel( current_section )
        endunless
    endif;
enddefine;

endsection;
