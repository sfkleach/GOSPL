compile_mode :pop11 +strict;

section;

uses simple_read;

define global new_infix_parser( read_initial, table, makenode );
    lvars read_initial, table, makenode;

    define lconstant read_expr( read_initial, table, makenode );
        lvars read_initial, table, makenode;

        ;;; unique value denoting a "maximum" representable number
        lconstant infinity = 'infinity';

        define lconstant procedure read_expr_prec( n ) -> expr; lvars n, expr;
            read_initial() -> expr;
            repeat
              quitif( proglist.null );
                lvars token = peek_token();
                lvars prec = table( token );
              quitunless( prec.isinteger and ( n == infinity or prec <= n ) );
                drop_token();
                makenode( token )( expr )( read_expr_prec( prec ) ) -> expr
            endrepeat;
        enddefine;

        read_expr_prec( infinity )
    enddefine;

    read_expr(% read_initial, table, makenode %)
enddefine;

;;; Make it work with -uses-.  Yuk.
global vars simple_parse = true;

endsection;
