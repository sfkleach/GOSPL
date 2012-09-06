;;; Summary:  abbreviation expansion table

/* LIB VEDABBPROPS                                  Chris Slymon, October 1983

Two properties defining some abbreviations for use with LIB VEDABBS. */

section $-ved => ved_pop_abbs ved_text_abbs;

uses vedendabbs;

global vars ved_pop_abbs ved_text_abbs;

newproperty([
    [df 'define']           [dg 'define global']
    [dfgm 'define global macro']
    [dm 'define macro']     [cs 'constant']
    [rt 'return']           [tt 'then']
    [v 'vars']              [sc 'section']
    [lv 'lvars']            [gb 'global']
    [sw 'switchon']         [fc 'foreach']
    [fv 'forevery']         [ul 'unless']
    [ut 'until']            [wh 'while']
    [pd 'procedure']        [l 'else']
    [li 'elseif']           [lu 'elseunless']
    [qi 'quitif']           [ql 'quitloop']
    [qu 'quitunless']       [rp 'repeat']
    [ei 'endif']            [ed 'enddefine']
    [er 'endrepeat']        [esc 'endsection']
    [esw 'endswitchon']     [ef 'endfor']
    [efc 'endforeach']      [efv 'endforevery']
    [eul 'endunless']       [eut 'enduntil']
    [ew 'endwhile']         [ep 'endprocedure']
    [ex 'exported']         [nx 'nonexported']
    [ukgnp 'UNITED KINGDOM GROSS NATIONAL PRODUCT 1980-83']
    [er ^veder_abbfn]
    [e ^vede_abbfn]
    [eb ^vedeb_abbfn]
],
        30,false,true) -> ved_pop_abbs;

newproperty([
    [er ^veder_abbfn]
    [e ^vede_abbfn]
    [eb ^vedeb_abbfn]
    [df 'define']
    [cs 'constant']
    [rt 'return']
    [p 'the']
    [z 'and']
    [sc 'section']
    [ul 'unless']
    [ut 'until']
    [wh 'while']
    [pd 'procedure']
    [l 'else']
    [rp 'repeat']
    [ex 'exported']
    [nx 'nonexported']
    [tt 'The']
    [pp 'POPLOG']
    [spf 'superfluous']
    [ukgnp 'UNITED KINGDOM GROSS NATIONAL PRODUCT 1980-83']
],
        30,false,true) -> ved_text_abbs;
endsection;
