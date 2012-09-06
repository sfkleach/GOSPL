compile_mode :pop11 +strict;

uses $-kers_syntax$-useful_syntax;

section $-kers_syntax => <$ $>;

global constant syntax $>;
global constant syntax |;

define lconstant nested_name( name ); lvars name;

    define to_chars( x ); lvars x;
        if x then x.explode else '(none)'.explode endif
    enddefine;

    define nest( l ); lvars l;
        unless l.null do `.`, l.hd.pdprops.to_chars, l.tl.nest endunless
    enddefine;

    consword(#|
        to_chars( name or "anon_".gensym ),
        pop_vm_compiling_list.nest
    |#)

enddefine;

define global syntax <$;
    lvars args = read_arg_sequence( "|" );
    sysPROCEDURE( false.nested_name, args.length );
    applist( args.rev, declare_arg );
    "$>".pop11_comp_stmnt_seq_to.erase;
    sysPUSHQ( sysENDPROCEDURE() )
enddefine;

endsection;
