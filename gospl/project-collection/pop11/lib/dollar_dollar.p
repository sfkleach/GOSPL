;;; Summary: syntax for quasi-quoting prolog terms elegantly


;;; dollar_dollar.p       Copyright R.J.Popplestone, December 1987.

;;; Provides a handy syntax procedure for reading Prolog terms in POP
;;; Modified, apr89 to treat $$x$$ properly.
;;; Modified sep90 - This version now deals correctly with lvars

uses prolog;
;;; pr('New version of dollar_dollar - ^x now works for lexical x\n');

:- op( 10, fx, [?,^] ).

section dollar_dollar => $$ ;

vars procedure
    expand;                             ;;; Compiles code to create a term.

;;; This syntax procedure provides a convenient way of creating Prolog
;;; terms in POP-11 programs. The form is $$ <prolog-term> $$ where the
;;; standard Edinburgh syntax is used for the <prolog-term>. E.g. $$ x+y $$
;;; creates term  x+y  whose functor is "+" and whose arguments are "x" and
;;; "y". The functor "^" is used with a single argument to allow the value
;;; of POP-11 variables to be inserted in the term.  ^<variable> will be
;;; replaced by the value of any variable (lexical or not).
;;; ^<functor>(<arg1>...<argn>) will create a Prolog term with the functor
;;; replaced. (Depending on prolog_maketerm, this will normally be restricted
;;; to being a POP-11 word.

;;; Provides a way of getting a Prolog term into a POP-11 program. SEE ABOVE.

define syntax $$ ;
    lvars r = prolog_readterm_to("$$");    ;;; Read the term off the input
    expand(r);                             ;;; Generate code to make new term
enddefine;                                 ;;; with POP-11 variables evaluated.



define expand(r);                                ;;; Make term on stack
    lvars r;
    if prolog_complexterm(r) then
        lvars i,
             f = prolog_predword(r),
             n = prolog_nargs(r);
        if    f = "^" and n=1 then               ;;;  ^(f(a1..an)) OR ^(x)
            lvars r1 = prolog_arg(1,r),
                  n1 = prolog_nargs(r1);
            if isword(r1) then                   ;;; we had ^(x), now r1 = x
                sysPUSH(r1);                     ;;; push its value on stak
            elseif prolog_complexterm(r1) then   ;;; we had ^(f(x,y))
                 for i from 1 to n1 do
                    expand(prolog_arg(i,r1));    ;;; make the i'th  argument
                 endfor;
                 sysPUSH(prolog_functor(r1));    ;;; push the value of f
                 sysPUSHQ(n1);                   ;;; push the number of args.
                 sysCALL("prolog_maketerm");     ;;; make the term

            else                                 ;;; Cannot take value of
                mishap('Must have identifier ',  ;;; constant
                      [^r])                      ;;;
            endif
        else                                     ;;; ordinary complex term
            for i from 1 to n do                 ;;; f(a1...an)
              expand(prolog_arg(i,r))            ;;; make i'th argument
            endfor;
            sysPUSHQ(prolog_functor(r));         ;;; push "f"
            sysPUSHQ(n);                         ;;; push the number of args.
            sysCALL("prolog_maketerm");          ;;; make the term
        endif
    else                                         ;;; Not a complex term
        sysPUSHQ(r)
    endif
enddefine

endsection;

section;

prolog_write -> class_print( datakey( $$x+y$$ ) );

vars dollar_dollar = true;

endsection;
