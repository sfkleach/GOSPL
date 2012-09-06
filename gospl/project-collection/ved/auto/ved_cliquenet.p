;;; Summary: visualise call structure of a program

/* VED_CLIQUENET        --  Chris Thornton  Aug 84
   uses SHOWNET, CALLSLIST and CLIQUES
   to visualize 'call' structure of a program
*/

uses shownet;

telluser('Loading CLIQUES');
uses cliques;

telluser('Loading CALLSLIST');
uses callslist;


define ved_cliquenet();
   vars curr_clique database clq level node item;
   vedargnum(vedargument) -> level;
   if null(callslist() ->> database) then
      vedputmessage('INVALID POP CODE')
   else
      cliques(database, level) -> clq;
      [%  for item in clq do
             if item matches [ISOLATED ==] then
                ''; ''><item
             elseif item matches [NODESIN ?curr_clique ==] then
               explode(netbuffer([[% netbuffer([% curr_clique,
                                       for node in item do
                                          if present([^node ==]) then it endif
                                       endfor %]) %]]));
               '';
            else
               item
            endif
         endfor %] -> clq;
      shownet([%'CLIQUENET '><level><' on '><vedcurrent, explode(clq) %]);
   endif
enddefine;
