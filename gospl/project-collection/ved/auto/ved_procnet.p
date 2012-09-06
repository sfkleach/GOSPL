;;; Summary: show call structure of a program

/* PROCNET */
/* uses SHOWNET and CALLSLIST to visualize call structure of a program */


uses shownet;

telluser('Loading CALLSLIST');
uses callslist;


define ved_procnet();
   lvars cl;
   if null(callslist() ->> cl) then
      vedputmessage('INVALID POP CODE')
   else
      shownet([%'PROCNET on '><vedcurrent, explode(cl)%]);
   endif
enddefine;
