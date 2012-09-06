;;; Given a procedure P, returns a procedure DIFF which takes a counted
;;; group of arguments.  When DIFF is applied to a group which it is
;;; different from the previous group, it applied P to the arguments.

compile_mode :pop11 +strict;

section;

define global new_apply_diff( p ); lvars procedure p;

    define lconstant macro fst;
        ;;; "fast_" <> readitem()
        readitem()
    enddefine;

    define lconstant macro sys_grbg;
        ;;; "sys_grbg_" <> readitem()
        lvars it = readitem();
        if it == "list" then
            "erase"
        else
            it
        endif
    enddefine;


    lvars previous_data = conspair( [], [] );
    lvars previous_n = 0;

    define lconstant save( n ); lvars n;

        ;;; Extend previous data if necessary.
        fst repeat max( 0, n - previous_n ) times
            conspair( 0, previous_data ) -> previous_data
        endrepeat;

        lvars data = previous_data;
        lvars i;
        fst for i from 1 to n do
            subscr_stack( i ) -> fst front( data );
            fst back( data ) -> data;
        endfor;
        n -> previous_n;

        ;;; Free any superfluous store.
        unless data == [] do
            0 -> fst front( data );
            sys_grbg list( fst back( data ) );
        endunless;
    enddefine;

    define lconstant apply_diff( n ); lvars n;
        if fi_check( n, 0, false ) == previous_n then
            ;;; They may be the same.
            lvars data = previous_data;
            lvars i;
            for i from 1 to n do
                lvars it1 = subscr_stack( i );
                lvars it2 = ( fst destpair( data ) -> data );
                unless it1 == it2 do
                    fst chain( save( n ), p )
                endunless;
            endfor;

            ;;; They are the same.
            erasenum( n )
        else
            p( save( n ) )
        endif
    enddefine;

    return( apply_diff );
enddefine;

endsection;
