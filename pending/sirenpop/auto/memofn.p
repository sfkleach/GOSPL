compile_mode :pop11 +strict;

section;

define global memofn( p ); lvars p;
    newanyproperty(
        [], 16, 1, false,
        false, false, "tmparg",
        <# consundef( false ) #>,
        procedure( k, self ); lvars k, self;
            lvars n = #| p( k ) |#;
            if n == 1 then
                () ->> self( k )
            elseif n < 0 then
                mishap( 'TOO FEW RESULTS FROM MEMOISED FUNCTION', [ ^n ^p ] )
            else
                mishap( 'TOO MANY RESULTS FROM MEMOISED FUNCTION', [ ^n ^p ] )
            endif
        endprocedure
    )
enddefine;

endsection
