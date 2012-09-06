/*
HELP PRINTI                                     Robin Popplestone, Oct 93

    printi( STRING, LIST )

This  procedure  provides  a  way   of  printing  recursive  structures
with indentation.  It  will  print  the LIST  along
the  lines  of printf, except that  any %t occurring  in the STRING
will cause an  indenting counter, n_tab, to  be incremented  by 2.  Any
newline  characters printed  by printi will be followed by n_tab spaces.
Thus if you define printing functions for mutually recursive
data-structures (e.g. the abstract syntax of a computer language) using
printi,  with  %t  preceding any  %p  that  causes  recursive printing,
substructures will be neatly indented.

Notes:
    -printi- does NOT accept arguments in the alternative form
        printi( ITEM1, ITEM2, ..., ITEMn, STRING )
    as -printf- and -sprintf- do.


Example:

    : printi(
    :     'Data%t\n%p -- type\n%p -- name%t\n%p -- left \n%p -- right\n',
    :     [alpha beta gamma delta]
    : );

    Data
      alpha -- type
      beta -- name
        gamma -- left
        delta -- right

*/

compile_mode :pop11 +strict;
section;

lvars n_tab = 0;

define global printi( String, List ); lvars String, List;
    lvars i, n = datalength(String);
    dlocal n_tab;
    for i from 1 to n do
        lvars c = subscrs(i,String);
        if c == `%` then
            i + 1 -> i;
            subscrs( i, String ) -> c;
            if c == `p` then
                pr( List.dest -> List )
            elseif c == `P` then
                sys_syspr( List.dest -> List );
            elseif c == `c` then
                cucharout( c )
            elseif c == `t` then
                n_tab + 2 -> n_tab;
            else
                mishap('Wrong use of % in print string',[^String^List]);
            endif
        elseif c = `\n` then
            nl( 1 );
            sp( n_tab );
        else
            cucharout(c)
        endif
    endfor;
enddefine;

endsection;
