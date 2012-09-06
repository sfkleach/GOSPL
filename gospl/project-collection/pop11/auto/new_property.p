;;; Summary: simpler property constructor

;;; Carefully chosen optional parameters.  These are reasonably
;;; efficient to process and somewhat robust against human
;;; error.

compile_mode :pop11 +strict;

section;

uses named_args;

define new_property() with_nargs 3;
    lvars_named_args
        initial_list, eqflag, default -&-
        hash = false,
        equal = false,
        gcflag = false,
        active_default/active = false,
        valgen = false
    ;

    lvars tabsz = initial_list.listlength;
    max( tabsz, 8 ) -> tabsz;
    newanyproperty(
        initial_list,
        tabsz,                          ;;; initial table size
        1,
        false,                          ;;; undocumented best value
        if eqflag == "==" or eqflag == "perm" then
            hash, equal, gcflag or "perm"
        elseif eqflag == "tmparg" then
            hash, equal, gcflag or "tmparg"
        elseif eqflag == "=" then
            hash or syshash, equal or nonop =, gcflag or "perm"
        elseif eqflag == "==#" then
            hash or syshash, equal or nonop ==#, gcflag or "perm"
        elseif eqflag == "tmpboth" then
            hash, equal, gcflag or "tmpboth"
        else
            mishap( 'Unexpected eqflag parameter for new_property', [ ^eqflag ] )
        endif,
        default,
        active_default or
        valgen and
        procedure( key, self );
            valgen( key ) ->> self( key )
        endprocedure
    )
enddefine;

endsection;
