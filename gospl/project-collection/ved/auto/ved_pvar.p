/*  <ENTER> pvar                                        R.Evans February 1984

    A library to make prolog variables easier to type - see help *PVAR

    THIS LIBRARY IS VERY CRUDE and needs rewriting by someone with more time
    to cope with VED special cases!
*/


vars pvars;
newproperty([],10,false,false) -> pvars;

define ved_pvar;
    vars rep item;
    incharitem(stringin(vedargument)) -> rep;
    until (rep() ->> item) == termin do
        not(pvars(item)) -> pvars(item);
    enduntil;
enddefine;

define pvars_processtrap(vedprocesstrap);
    unless vedonstatus or vedline == 1 then
        vedpushkey();
        vedwordleft();
        if pvars(vednextitem()) then
            if vedcurrentchar() == ` ` then vedwordright() endif;
            vedchangecase();
        endif;
        vedpopkey();
        vedsetcursor();
    endunless;
    vedprocesstrap();
enddefine;

unless vedprocesstrap.isclosure and
    pdpart(vedprocesstrap) == pvars_processtrap then
        pvars_processtrap(%vedprocesstrap%) -> vedprocesstrap;
endunless;
