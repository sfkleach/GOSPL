compile_mode :pop11 +strict;

section;

define global unexpected_eof =
    new_exception()
enddefine;

define lconstant procedure eof_mishap();
    raise unexpected_eof()
enddefine;

define lconstant procedure dest_proglist();
    if null( proglist ) then
        eof_mishap()
    else
        fast_destpair( proglist )
    endif
enddefine;

define global peek_token();
    if null( proglist ) then
        eof_mishap()
    else
        fast_front( proglist )
    endif
enddefine;

define global drop_token();
    if null( proglist ) then
        eof_mishap()
    else
        fast_back( proglist ) -> proglist
    endif
enddefine;

define global read_token();
    dest_proglist() -> proglist
enddefine;

define global read_word();
    check_word( dest_proglist() -> proglist )
enddefine;

define global read_number();
    check_number( dest_proglist() -> proglist )
enddefine;

define global can_read( x ); lvars x, h, t;
    returnif( null( proglist ) )( false );
    dest_proglist() -> t -> h;
    if
        islist( x ) and lmember( h, x ) or
        isprocedure( x ) and x( h ) or
        x = h
    then
        t -> proglist;
        h
    else
        false
    endif
enddefine;

define global must_read( x ) -> t; lvars x;
    lvars t = read_token();
    if x.islist then
        unless lmember( t, x ) do
            mishap(
                'SYNTAX: Wanted one of ' sys_>< x,
                [^t]
            )
        endunless
    elseif x.isprocedure then
        unless x( t ) do
            mishap( 'SYNTAX: Unexpected token', [^t] )
        endunless
    elseunless t == x then
        mishap(
            'SYNTAX: Wanted ' sys_>< x,
            [^t]
        )
    endif
enddefine;

;;; Make it work with -uses-.
global vars simple_read = true;

endsection;
