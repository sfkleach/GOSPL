;;; Summary: library supporting the EPSON FX 1000 printer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  LIB EPSON_FX_1000 created by merging lib prgraph and lib gprint   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/* LIB PRGRAPH - defining graphics characters for an EPSON FX-100 printer

   R.Evans March 1984

   The procedure PRGRAPH takes one or two arguments:

        prgraph(procedure,boolean)  or prgraph(procedure)

   The boolean dictates whether to set up the graphics characters or not (true
   means do set them up). The printer is then initialised for graphics
   printing (download char set, unidirectional, line spacing = 7) and then the
   procedure is called. The procedure graph_charout is a character consumer
   which does graphics printing and may be used by the user procedure.
   The printer is then reset (rom char set, bidirectional
   line spacing = 12).

   prgraph(proc) is the same as prgraph(proc,true)

   See EPSON manual for details. The line-drawing chars are loaded into gaps
   in the control codes

   Ammended by tomk, to use 4.2 12/9/84

*/

section $-prgraph => prgraph graph_charout prgraph_linespacing prgraph_elite
                     prgraph_textspacing;

vars printcharout;

/* printer problems: print filter knocks out nulls and print driver knocks
   off top bit of char, so can't send chars over 127. CAN send nulls, however,
   by sending 128 - filter lets it through, then top bit gets knocked off */

constant ctrltab;

{1 2 3 5 6 21 128 128 128 128 128 128 22 23 25 26 128 128 128 28}
        -> ctrltab;

define translate_&_print(x); lvars x;
    if x > 223 and x < 244 then ctrltab(x-223) else x endif;
    printcharout();
enddefine;

define global graph_charout(x); lvars x;
    if isinteger(x) then
        translate_&_print(x)
    elseif x == termin then
        printcharout(12);
    else
        appdata(x, translate_&_print);
    endif;
enddefine;


define prgraphsetup();
    graph_charout({27 `:` 128 128 128});
    graph_charout({
27 `&` 128 1 3
    139 16 128 16 128  16   128 16 128 16 128 16
    139 128  128 128  128  255  128 128  128 128  128 128
    139 16 128 16 128  255  128 16 128 16 128 16
27 `&` 128 5 6
    139 16 128 16 128  112  128 16 128 16 128 16
    139 16 128 16 128  31   128 16 128 16 128 16
27 `&` 128 21 23
    139 128  128 128  128  112  128 16 128 16 128 16
    139 16 128 16 128  31   128 128  128 128  128 128
    139 16 128 16 128  112  128 128  128 128  128 128
27 `&` 128 25 26
    139 128  128 128  128  255 128 16 128 16 128 16
    139 16 128 16 128  255 128 128  128 128  128 128
27 `&` 128 28 28
    139 128  128 128  128  31  128 16 128 16 128 16});
enddefine;

global vars prgraph_linespacing; 7 -> prgraph_linespacing;
global vars prgraph_elite; false -> prgraph_elite;

define prgraphstart();
    dlocal prgraph_linespacing;
    unless isinteger(prgraph_linespacing) then
        7 -> prgraph_linespacing
    endunless;
    graph_charout({27 `U` 1 27 `A` %prgraph_linespacing%
                   27 `P` 27 `%` 1 128 27 `I` 1 13 10});
enddefine;

global vars prgraph_textspacing;   12 -> prgraph_textspacing;
define prgraphstop();
    graph_charout({27 `U` 128 27 `A` %prgraph_textspacing%
                   %if prgraph_elite then 27; `M` endif%
                   27 `%` 128 128 27 `I` 128 13 10});
enddefine;


define global prgraph(flag); lvars flag;
   lvars proc pipein pipeout;
   if isboolean(flag) then
         -> proc;
   else
      flag -> proc;
      true -> flag;
   endif;
   unless isprocedure(proc) then
      mishap('Non-procedure given to PRGRAPH',[^proc]);
   endunless;
   syspipe(false) -> pipein -> pipeout;
   unless sysfork() then
      sysclose(pipeout);
      pipein -> popdevin;
      sysexecute('/usr/ucb/lpr',['lpr' '-l' '-J' 'gprint'],false);
   endunless;
   sysclose(pipein);
   discout(pipeout) -> printcharout;
   if flag then prgraphsetup() endif;
   prgraphstart();
   proc();
   prgraphstop();
   printcharout(termin);
enddefine;

endsection;


/*  GPRINT                                                  R.Evans March 1984

    GPRINT is a macro which is used like LOAD, but which prints the file
    specified on the EPSON printer using prgraph (see LIB PRGRAPH)
*/

uses prgraph

section $-prgraph => gprint;

define graph_echo(file); lvars file;
    lvars char;
    repeat;
        graph_charout(file() ->> char);
        quitif(char == termin);
    endrepeat;
enddefine;


define global macro gprint;
    lvars file;
    dlocal popnewline;

    true -> popnewline;
    discin(sysfileok(rdstringto([; ^termin ^newline]))) -> file;
    false -> popnewline;
    dl([prgraph( ^(graph_echo(%file%)), true);]);

enddefine;


endsection;

;;; -------------------------------------------------------------------------
;;; modified, sfk -- Fri Oct 18 10:04:51 BST 1991
;;;     *   Changed vars -> dlocal & lvars declarations.
;;; -------------------------------------------------------------------------
