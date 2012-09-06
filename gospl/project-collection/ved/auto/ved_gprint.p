;;; Summary: EPSON FX-100 printing

/*  VED_GPRINT: gprint current file                         R.Evans March 1984

    See *GPRINT,*PRGRAPH

   Ammended by tomk for 4.2
   and by christ to provide condense-mode printing (ved_gcprint)
*/

uses prgraph

section $-prgraph=> vedgprint ved_gprint ved_gcprint;

define isgraphic(c); c > 223 and c < 244; enddefine;

define global vedgprint(condense);
   lvars condense;
   vars n m graphic ingraphics line pipein pipeout;
   syspipe(false) -> pipein -> pipeout;
   unless sysfork() then
      sysclose(pipeout);
      pipein -> popdevin;
      /* sysexecute assumes standard input i.e. popdevin */
      sysexecute('/usr/ucb/lpr',['lpr' '-l' '-J' 'gprint'],false);
   endunless;
   sysclose(pipein);
   discout(pipeout) -> printcharout;
   prgraphsetup();
   prgraphstop();
   if condense then printcharout(15) endif;
   false -> ingraphics;
   for n from 1 to vvedbuffersize do
      vedbuffer(n) -> line;
      false -> graphic;
      for m from 1 to length(line) do
         if isgraphic(line(m)) then
            true -> graphic;
            quitloop
         endif;
      endfor;
      if graphic then
         unless ingraphics then
            prgraphstart();
            true -> ingraphics;
         endunless;
         appdata(line><'\n\r',graph_charout);
      else
         if ingraphics then
            prgraphstop();
            false -> ingraphics;
         endif;
         appdata(line><'\n\r',printcharout);
      endif;
   endfor;
   prgraph_textspacing;
   12 -> prgraph_textspacing;
   prgraphstop();
      -> prgraph_textspacing;
   if condense then printcharout(18) endif;
   graph_charout(termin);
   printcharout(termin);
enddefine;


define ved_gprint();
   vedgprint(false)
enddefine;


define ved_gcprint();
   vedgprint(true)
enddefine;

endsection;
