;;; Summary: compose a list of repeaters into a single repeater

compile_mode :pop11 +strict;

section;

define chain_repeaters( L ); lvars L;
    copylist( L ) -> L;

    lvars procedure rep = <| termin |>;

    define lconstant procedure self();
        if rep().dup == termin then
            if L then
                if L == [] do
                    false -> L;
                else
                    -> _;
                    fast_destpair( L ) -> L -> rep;
                    chain( self );
                endif
            else
                mishap( 'Repeater(s) exhausted', [] )
            endif
        endif
    enddefine;

    self
enddefine;

sysprotect( "chain_repeaters" );
endsection;
