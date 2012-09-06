compile_mode :pop11 +strict;

section;

sysunprotect( "pop_test_table" );

constant pop_test_table = (
    newanyproperty(
        [], 8, 1, 1,
         syshash, sys_=, "perm",
        false,
        procedure( k, p );
            assoc( [] ) ->> p( k )
        endprocedure
    )
);


sysprotect( "pop_test_table" );


endsection;
