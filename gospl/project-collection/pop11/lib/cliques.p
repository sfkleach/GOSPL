/* LIB CLIQUES   -- Jon Cunningham  84 (modified slightly by Chris Thornton)

   analyzes clique structure in a network;

   Takes two args: <network> & <level>    eg. cliques(<network>, <level>)

   <network> should be a list containing sublists of the form

   [<node> <list of subordinate nodes>]

   and <level> should be an integer between 1 and 4;

   Higher <level> args obtain more restrained clique-analysis

*/


define telluser();
   if vedediting then vedputmessage() else pr(); pr(newline) endif
enddefine;


;;;telluser('Loading CROSSREF');
;;;uses crossref;


telluser('Loading CLIQUES');


;;; Warshall's algorithm for finding the transitive closure of a
;;; relation represented as a boolean matrix

;;; (from Greiss)
;;; 1. Set a new matrix A = B
;;; 2. Set i := 1
;;; 3. For all j, if A[j,i] = 1 then for k = 1,...,n, set A[j,k] :=
;;;         A[j,k] + A[i,k].
;;; 4. Add 1 to i.
;;; 5. If i <= n then go to step 3; otherwise stop.

define warsh(mat) -> mat;
vars n k j i;
    copy(mat) -> mat;
    boundslist(mat)(2) -> n;
    for i from 1 to n do
        for j from 1 to n do
            if mat(j,i) then
                for k from 1 to n do
                    mat(j,k) or mat(i,k) -> mat(j,k)
                endfor
            endif
        endfor
    endfor
enddefine;

define matsetid(mat);
vars n i;
    boundslist(mat)(2) -> n;
    for i from 1 to n do
        true -> mat(i,i)
    endfor
enddefine;

define warning(str,culp);
    sysprmishap(str,culp)
enddefine;

vars chatty; true -> chatty;

define findcliques(mat) -> database;
vars i n j m aj ai zj zi;
        define i_lt_j(j); i < j enddefine;
    if chatty then
        telluser('CLIQUES: looking for cliques');
    endif;
    [] -> database;
    boundslist(mat)(2) -> n;
    for i from 1 to n do
        add([row % i,
            for j from 1 to n do
                mat(i,j)
            endfor %]);
        add([clique ^i])
    endfor;
    rev(database) -> database;  ;;; heuristic, to speed up allpresent nx line
    while allpresent([[row ?i ??n][row ?j:i_lt_j ??n]]) do
        remove([row ^j ^^n]);
        lookup([clique ??aj ^j ??zj]);
        remove(it);
        lookup([clique ??ai ^i ??zi]);
        remove(it);
        add([clique ^^ai ^i ^^zi ^^aj ^j ^^zj])
    endwhile;
    if chatty then
        telluser('CLIQUES: phew - done the hard part');
    endif;
    flush([row ==])
enddefine;

/*
define conv_cref_data() -> database;
vars procs varname u callsit database;
    [% appproperty(cref,
             procedure varname database;
                 if present([defined ==]) then
                     varname
                 endif
             endprocedure) %] -> procs;
    [] -> database;
    for varname in procs do
        foreach [?u == ?callsit =] in cref(varname) do
            if u > 0 then
                add([^callsit calls ^varname])
            endif
        endforeach
    endfor
enddefine;
*/

vars idmat transpose;
define triples_to_mat(triples) -> mat -> pname -> pnumber;
lvars mat n procs i p;
vars callsit called;

    ;;; extract procnames
    [] -> procs;
    foreach [?callsit calls ?called] in triples do
        unless lmember(callsit,procs) then
            callsit :: procs -> procs
        endunless;
        unless lmember(called,procs) then
            called :: procs -> procs
        endunless
    endforeach;
    sort(procs) -> procs;

    ;;; produce mappings between names and numbers
    length(procs) -> n;
    if n == 0 then mishap('cliqueing on an empty network', [cliques]) endif;
    if chatty then
        telluser('CLIQUES: analysing '><n><' procedures');
    endif;
    newproperty([],n,false,true) -> pname;
    newproperty([],n,false,true) -> pnumber;
    1 -> i;
    until procs == nil do
        destpair(procs) -> procs -> p;
        i -> pnumber(p);
        p -> pname(i);
        1 + i -> i
    enduntil;

    ;;; now create matrix
    newarray([1 ^n 1 ^n],false) -> mat;
    foreach [?callsit calls ?called] in triples do
        if transpose then
            callsit, called -> callsit -> called
        endif;
        true -> mat(pnumber(callsit),pnumber(called))
    endforeach;
    if idmat then
        matsetid(mat)
    endif
enddefine;

define namecliques(triples);
vars pname mat database i r pnumber j k n;
    triples_to_mat(triples) -> mat -> pname -> pnumber;

    ;;; next section
    if chatty then
        telluser('CLIQUES: created call matrix');
    endif;
    warsh(mat) -> mat;
    if chatty then
        telluser('CLIQUES: transitively closed call matrix');
    endif;

    1 -> gensym("clique");
    findcliques(mat) -> database;
    foreach [clique ?i ??r] do
        if r == [] then
            pname(i) -> it(2)
        else
            [% gensym("clique") %] -> back(it);
            add([NODESIN % it(2),
                     for i in i::r do pname(i) endfor %])
        endif
    endforeach;
    ;;; next produce a new calling matrix for clique
    if chatty then
        telluser('CLIQUES: producing a call graph for cliques');
    endif;
    foreach [clique ?r] do
        if present([NODESIN ^r ??i]) then
            front(i) -> i
        else
            r -> i
        endif;
        foreach [clique ?j] do
            if present([NODESIN ^j ??k]) then
                for n in k do
                    if mat(pnumber(i),pnumber(n)) then
                        add([^r calls ^j]);
                        quitloop
                    endif
                endfor
            else
                j -> k;
                if mat(pnumber(i),pnumber(k)) then
                    add([^r calls ^j])
                endif
            endif;
        endforeach
    endforeach;
    ;;; find the anti-transitive reduction of the "calls"
    if chatty then
        telluser('CLIQUES: finding anti-transitive reduction');
    endif;
    [% for r in database do
            if r(2) == "calls" and r(1) == r(3) then
                add([recursive %r(1)%])
            else
                r
            endif
       endfor %] -> database;
    forevery [[?i calls ?r][?r calls ?j]] do
        if present([^i calls ^j]) then
            remove(it)
        endif;
    endforevery;
    return(database)
enddefine;

define Cliques(triples,idmat,transpose);
   vars database cq s isolates node nodes; [CLIQUES ISOLATED] -> isolates;
   namecliques(triples) -> database;
   if chatty then
      telluser('CLIQUES: tidying up callgraph');
   endif;
   [% for s in database do
          if s matches [clique ?cq] then
             unless present([= calls ^cq]) or present([^cq calls =]) do
                cq :: isolates -> isolates;
             endunless;
          elseif transpose and front(s) /== "NODESIN" then
             rev(s)
          else
             s
          endif
       endfor; if not(null(tl(tl(isolates)))) then rev(isolates) endif%]
enddefine;



define ntuples_to_triples(ntuples);
   lvars ntuples pattern item tag;
   [% for pattern in ntuples do
         if islist(pattern) and not(null(pattern)) then
            fast_front(pattern) -> tag;
            for item in fast_back(pattern) do
               [% tag, "calls", item %]
            endfor
         endif
      endfor %]
enddefine;


define triples_to_ntuples(triples);
   lvars triples pattern item x;
   [% for pattern in triples do
         if length(pattern) == 3 and pattern(2) = "calls" then
            [% pattern(1), pattern(3) %]
         else
            pattern
         endif
      endfor %]
enddefine;


define cliques(net, level);
   lvars net level;
   ntuples_to_triples(net);
   if level == 1 then false,false
   elseif level == 2 then false,true
   elseif level == 3 then true,false
   elseif level == 4 then true, true
   else mishap('argument for CLIQUES out of range',[])
   endif;
   triples_to_ntuples(Cliques())
enddefine;
