;;; Implements the publish/subscribe section syntax.  Slightly
;;; generalised to support the module/endmodule syntax.

section;
compile_mode :pop11 +strict;
include vm_flags.ph;


;;; This table maps from sections to lists of their published
;;; identifiers.
;;;
lconstant procedure section_table =
    newproperty( [], 16, [], "tmparg" );

define lconstant check_section( sect ); lvars sect;
    unless sect.issection then
        mishap( sect, 1, 'SECTION NEEDED' );
    endunless;
enddefine;

define lconstant check_word( name ); lvars name;
    unless name.isword then
        mishap( name, 1, 'WORD NEEDED' );
    endunless;
enddefine;

define global is_section_published( sect, name ); lvars sect, name;
    check_section( sect );
    check_word( name );
    lmember( name, section_table( sect ) ) and true
enddefine;

define global app_section_published( sect, p ); lvars sect, p;
    check_section( sect );
    applist( section_table( sect ), p )
enddefine;

define global section_publish( name ); lvars name;
    lvars sect = current_section;
    if sect == pop_section then
        mishap( name, 1, 'CAN\'T PUBLISH WORD FROM TOP LEVEL SECTION' )
    endif;
    check_section( sect );
    check_word( name );

    lvars current_names = section_table( sect );
    unless lmember( name, current_names ) then
        conspair( name, current_names ) -> section_table( sect );
    endunless;
enddefine;

define global section_subscribe( from_sect, prefix ); lvars from_sect, prefix;
    lvars sect = current_section, names, wid, old_id;
    returnif( sect == from_sect );

    check_section( from_sect );

    if from_sect == pop_section then
        mishap( from_sect, 1, 'CANNOT SUBSCRIBE FROM TOP LEVEL SECTION' );
    endif;

    ;;; test if there is no published names to bring in
    if ( section_table( from_sect ) ->> names ) == [] then
        if section_name( from_sect ) then
            sys_autoload( section_name( from_sect ) ).erase
        endif;
        if ( section_table( from_sect ) ->> names ) == [] then
            warning(
                'SUBSCRIBING TO SECTION WHICH PUBLISHES NOTHING',
                [% from_sect %]
            );
            return;
        endif;
    endif;

    lvars w;
    for w in names do
        ;;; get the source identifier word
        word_identifier( w, from_sect, true ) -> wid;

        unless wid then
            ;;; trying to subscribe to a non-declared identifier. Declare it.
            warning(
                'VARIABLE PUBLISHED BY SECTION NOT DECLARED',
                [^w ^(section_name(from_sect))]
            );

            procedure();
                ;;; this is a bit slow...
                dlocal current_section = from_sect;
                sysdeclare( w );
            endprocedure();

            ;;; now get the word identifier again (this time we know its local)
            word_identifier( w, from_sect, false ) -> wid;
        endunless;

        ;;; see if the user specified a prefix for imported variables
        if prefix then
            if prefix.isprocedure then
                prefix( w ) -> w;
                check_word( w );
            else
                prefix <> w -> w;
            endif;
        endif;
        ;;; do nothing if the words are currently declared to be the same
        ;;; identifier.
        nextif( sys_current_ident( w ) == sys_current_ident( wid ) );

        if isdeclared( w ) ->> old_id then
            if
                isprotected( old_id ) and
                pop_vm_flags &&=_0 VM_NOPROT_PVARS
            then
                mishap( w, 1, 'ATTEMPT TO CANCEL PROTECTED IDENTIFIER' );
            endif;
            warning(
                sprintf(
                    'SUBSCRIBING TO SECTION %p CANCELS %p IDENTIFIER',
                    [%
                        section_name( from_sect ),
                        if word_identifier( w, sect, false ) then
                            'LOCAL'
                        else
                            'IMPORTED'
                        endif
                    %]
                ),
                [^w]
            );
            syscancel( w );
        endif;

        ;;; link the two words
        identof( wid ) -> identof( w );
    endfor;
enddefine;

endsection;
