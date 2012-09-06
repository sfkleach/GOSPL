;;; -- Reading s-expressions ------------------------------------------------

12 -> item_chartype( `\\` );
constant procedure read_sexp, read_word;

;;; -- Utilities

define mishapchar( mess, ch ); lvars mess, ch;
    mishap( mess, [% consstring( ch, 1 ) %] )
enddefine;

define illegal_char( c ); lvars c;
    mishapchar( 'Illegal char', c )
enddefine;

define is_word_char( x ); lvars x;
    (`a` <= x and x <= `z`) or
    (`A` <= x and x <= `Z`) or
    locchar( x, 1, '*/<=>!?:$%_&~^' )
enddefine;

define is_white_space( x ); lvars x;
    x == `\s` or x == `\t` or x == `\n`
enddefine;

define nonwhite() -> ch; lvars ch;
    while (cucharin() ->> ch).is_white_space do endwhile;
enddefine;

define getprefix() -> radix -> exact -> precision;
    lvars radix = undef, exact = undef, precision = undef;
    repeat
        lvars ch = cucharin();
        unless ch == `#` do
            ch -> cucharin();
            quitloop;
        endunless;
        lvars ch = cucharin();
        if locchar( ch, 1, 'BDOX' ) do
            lconstant table1 = [[`B` 2][`D` 10][`O` 8][`X` 16]].assoc;
            if radix == undef do
                table1( ch )
            else
                mishap( 'Radix specified twice', [] )
            endif -> radix;             
        elseif locchar( ch, 1, 'EI' ) do
            if exact == undef do
                if ch == `E` do true
                elseif ch == `I` do false
                else internal_error()
                endif
            else
                mishap( 'Exactness specified twice', [] )
            endif -> exact
        elseif locchar( ch, 1, 'LS' ) do
            if precision == undef do
                if ch == `L` do true
                elseif ch == `S` do false
                else internal_error()
                endif
            else
                mishap( 'Precision specified twice', [] )
            endif -> precision;
        else
            mishapchar( 'Invalid letter in numerical context', ch )
        endif
    endrepeat;
    if radix == undef do 10 -> radix endif;
    if exact == undef do true -> exact endif;
    if precision == undef do false -> precision endif;
enddefine;

define convert( ch ); lvars ch, n;
    if (locchar( ch, 1, '0123456789ABCDEF' ) ->> n) do
        n - 1
    else
        false
    endif
enddefine;

define getdigits( radix ) -> num -> hashfound;
    lvars radix, num = 0, hashfound = false, digit;
    repeat
        lvars ch = cucharin();
        if ch == `#` do
            true -> hashfound;
            num * radix -> num
        elseif (convert( ch ) ->> digit) do                   
            if hashfound do
                mishapchar( 'No digits permitted after a hash', ch )
            else
                num * radix + digit -> num
            endif;
        else
            ch -> cucharin();
            quitloop;
        endif;
    endrepeat;
enddefine;

define getafterpoint( radix ) -> num;
    lvars radix, num = 0, divisor = radix, digit;
    repeat
        lvars ch = cucharin();
        if convert( ch ) ->> digit do
            num + digit/divisor -> num;
            divisor*radix -> divisor;
        else
            ch -> cucharin();
            quitloop;
        endif;
    endrepeat
enddefine;

define throw_away_hashes();
    lvars ch;
    while (cucharin() ->> ch) == `#` do endwhile;
    ch -> cucharin();
enddefine;

define getunumber( radix ); lvars radix;
    lvars num1, num2, hashfound1;
    getdigits( radix ) -> num1 -> hashfound1;
    lvars ch = cucharin();
    if ch == `.` do
        if hashfound1 do
            throw_away_hashes();
            num1
        else
            getafterpoint( radix ) -> num2;
            num1 + num2
        endif
    elseif ch == `/` do
        getdigits( radix ) -> num2 -> ;
        num1 / num2
    else
        ch -> cucharin();
        num1;
    endif;
enddefine;

define getsuffix( radix ); lvars radix;
    lvars s;
    lvars ch = cucharin();
    if ch == `e` do
        lvars ch = cucharin();
        if ch == `+` do     1
        elseif ch == `-` do -1
        else mishapchar( 'Illegal sign following exponential', ch )
        endif -> s;
        lvars num, foundhashes;
        getdigits( radix ) -> num -> foundhashes;
        if foundhashes do
            mishap( 'Hashes not permitted inside suffix of number', [] )
        endif;
        s * num
    else
        ch -> cucharin();
        0;
    endif;
enddefine;

define getureal();
    lvars radix, exact, precision;
    getprefix() -> radix -> exact -> precision;
    lvars n = getunumber( radix );
    lvars suffix = getsuffix( radix );
    lvars num = n * radix ** suffix;
    if num.isinteger do
        num
    else
        if exact do
            number_coerce( num, 0 )
        else
            number_coerce( num, 0.0 )
        endif;
    endif;
enddefine;

define getsign();
    lvars ch = cucharin();
    if ch == `+` do 1
    elseif ch == `-` do -1
    else ch -> cucharin(); 1
    endif
enddefine;

define getreal();
    getsign() * getureal()
enddefine;

define getnumber();
    lvars r1 = getreal();
    lvars ch = cucharin();
    if ch == `+` or ch == `-` do
        lvars r2 = getreal();
        lvars ch1 = cucharin();
        unless ch1 == `i` do
            mishapchar( 'No "i" at end of imaginary number', ch1 )
        endunless;
        if ch == `+` do nonop +: else nonop -: endif( r1, r2 );
    elseif ch == `@` do
        lvars r2 = getreal();
        r1 * cis( r2 )
    else
        ch -> cucharin();
        r1
    endif
enddefine;


;;; -- Table

constant read_table =
    {% repeat 255 times illegal_char endrepeat %};

define make_entries( p, pred ); lvars p, pred;
    lvars i;
    for i from 1 to 255 do
        if pred( i ) do
            p -> read_table( i )
        endif
    endfor
enddefine;

;;; -- Entries

define read_comma( c ); lvars c;
    lvars ch = cucharin();
    [%
        if ch == `@` do
            "unquote\-splicing"
        else
            "unquote";
             ch -> cucharin()
        endif,
        read_sexp()
    %]
enddefine;
read_comma -> read_table( `,` );

define read_comment( c ); lvars c, ch;
    repeat
        cucharin() -> ch;
        quitif( ch == `\n` );
    endrepeat;
    read_sexp();
enddefine;
read_comment -> read_table( `;` );

define read_hash( c ); lvars c;
    lvars ch = cucharin();
    if ch == `(` do
        ch -> cucharin();
        lvars s = read_sexp(), s1 = s;
        {% while s.ispair do destpair( s ) -> s endwhile %};
        unless s == nil do
            mishap( 'Cannot use dot notation inside vectors', [^s1] )
        endunless;
    elseif ch == `t` do
        true
    elseif ch == `f` do
        false
    elseif ch == `\\` do
        lvars ch = cucharin();
        if ch == `s` or ch == `n` do
            ch -> cucharin();
            lvars x = read_sexp();
            if x == "s" do `s`
            elseif x == "n" do `n`
            elseif x == "space" do `\s`
            elseif x == "newline" do `\n`
            else
                mishap( 'Illegal token after \#\\', [^x] )
            endif
        else
            ch
        endif
    elseif locchar( ch, 1, 'EILSBODX' ) do
        ch -> cucharin();
        `#` -> cucharin();
        getnumber();
    else
        mishap( 'Illegal char following \#', [code = ^ch] )
    endif
enddefine;
read_hash -> read_table( `#` );

define read_id_or_number( c ); lvars c;
    lvars ch = cucharin();
    if ch.isnumbercode do
        ch -> cucharin();
        c -> cucharin();
        getnumber();
    else
        ch -> cucharin();
        read_word( c );
    endif
enddefine;
make_entries( read_id_or_number, locchar(% 1, '+-.' %) );

define read_number( c ); lvars c;
    c -> cucharin();
    getnumber();
enddefine;
make_entries( read_number, isnumbercode );


define read_open( c );
    lvars count = 0, ch, c;
    repeat
        lvars ch = nonwhite();
        if ch == termin do
            mishap( 'Unexpected end of input', [] )
        elseif ch == `.` do
            read_sexp();
            lvars ch = nonwhite();
            unless ch == `)` do
                mishapchar( 'Unexpected char at end of dotted pair', ch )
            endunless;
            quitloop;
        elseif ch == `)` do
            nil; quitloop
        else
            ch -> cucharin();
            read_sexp();
            1 + count -> count;
        endif;
    endrepeat;
    repeat count times
        conspair()
    endrepeat;
enddefine;
read_open -> read_table( `(` );

define read_quote( c ); lvars c;
    [quote % read_sexp() %]
enddefine;
read_quote -> read_table( `'` );

define read_string( c ); lvars c;
    lvars ch;
    cons_with consstring {%
        until (cucharin() ->> ch) == `"` do
            if ch == `\\` do
                cucharin()
            elseif ch == termin do
                mishap( 'End of file inside string', [])
            else
                ch
            endif
        enduntil
    %}
enddefine;
read_string -> read_table( `"` );

define read_white_space( c ); lvars c, ch;
    repeat
        lvars ch = cucharin();
        quitunless( ch.is_white_space )
    endrepeat;
    ch -> cucharin();
    read_sexp();
enddefine;
make_entries( read_white_space, is_white_space );

define read_word( ch ); lvars ch;
    cons_with consword {%
        ch;
        repeat
            lvars ch = cucharin();
            if ch.is_word_char
            or ch.isnumbercode
            or locchar( ch, 1, '+-' )
            do
                ch
            else
                ch -> cucharin();
                quitloop
            endif
        endrepeat
    %};
enddefine;
make_entries( read_word, is_word_char );

define read_sexp;
    lvars c = cucharin();
    if c == termin do
        termin ->> cucharin();
    elseif c == 0 do
        chain(read_sexp)
    else
        subscrv( c, read_table )( c )
    endif;
enddefine;

define read_scheme;
    dlocal cucharin;
    unless cucharin.isPushable do
        newPushable( cucharin ) -> cucharin
    endunless;
    read_sexp();
enddefine;
