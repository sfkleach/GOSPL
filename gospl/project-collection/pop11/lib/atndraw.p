
/* LIB DRAWATN                                   Allan Ramsay, 14 December 1983
 *
 * Used for reading in an ATN, working out how to lay it out on the terminal,
 * and actually displaying it. Used by LIB ATNPARSE
 *
 */

if      identprops("alistval") == "undef"
then    define constant alistval (key,alist) -> val ;
        vars x ;
        false -> val;
        for x in tl(alist)
        do   if front(x) == key then x -> val exit;
        endfor;
        enddefine;

        define updaterof alistval (val,key,alist) ;
        vars x ;
        if      alistval(key,alist) ->> x
        then    val -> back(x)
        else    conspair(key,val) :: tl(alist) -> tl(alist)
        endif;
        enddefine;
endif;

uses context;

define constant 1 child register_value reg ;
vars x ;
if      isstate(child)
then    child value_in reg
else    islist(child) and (alistval(reg,hd(child))->>x) and back(x)
endif;
enddefine;

define constant macro # (reg) ;
applist([Child register_value " ^reg " ],identfn);
enddefine;

define constant macro ! (reg) ;
applist([Parent register_value " ^reg "],identfn) ;
enddefine;

define constant macro @ (reg);
applist([ register_value " %reg% "], identfn);
enddefine;

vars pre_analyse build ;
/* pre_analyse should convert a list of words to a form suitable for parsing
 * (see LIB ENDINGS). build is called whenever a "pop" arc is taken -
 * its default definition simply constructs a parse tree (held in the
 * register Tree). It is run AFTER the actions associated with the arc have
 * been performed.
 */

if isundef(pre_analyse) then identfn -> pre_analyse endif;

/* This program is designed to run on a VISUAL-200 terminal, and makes use of
 * a number of character sequences which control output on these terminals.
 * LIB GRAPHCHARS is supposed to make it easy to transfer programs that rely
 * on the interpretation of <ESC> sequences for graphical output, but you will
 * almost certainly have to redefine the procedures which clear parts of the
 * screen, and which set the terminal so that some output is in dim and some
 * is bright.
 */

uses graphchars ; graphcharsetup();
vars displaying ;   /* global flag to switch display on/off */
if isundef(displaying) then true -> displaying endif;

/* Defines whether V-200 is going to interpret graphics characters or not */
define constant graphics (flag);
cucharout(27); cucharout(if flag then `F else `G endif);
enddefine;

define constant graphcharout (c);
graphics(true); cucharout(c); graphics(false);
enddefine;

/* Draws a horizontal line n positions long */
define constant h_line (n);
graphics(true);
repeat n times cucharout(graph_horz) endrepeat;
graphics(false);
enddefine;

/* Draw a single vertical bar */
define constant 1 v_bar ;
graphcharout(graph_vert);
enddefine;

/* Moves cursor to x, y */
define constant jumpto (x,y);
cucharout(27); cucharout(`Y); cucharout(55-y); cucharout(x+32);
enddefine;

/* Sets screen bright or dim for succeeding output */
define constant mode(foreground);
cucharout(27); cucharout(if foreground then `3 else `4 endif);
enddefine;

/* Clears screen, resets standard modes */
define constant 1 clear ;
cucharout(27); cucharout(`v);
enddefine;

/* Clears screen from cursor position to end of current line */
define constant 1 clear_eol ;
cucharout(27); cucharout(`K);
enddefine;

/* Clears screen from cursor position to end of screen */
define constant 1 clear_eos ;
cucharout(27); cucharout(`J);
enddefine;

define constant mostest (list,proc) -> best;
vars x ;
dest(list) -> list -> best;
for x in list
do  if proc(x,best) then x -> best endif;
endfor;
enddefine;

/* The following section of the program reads in a grammar, and calculates the
 * layout for the various networks
 */

vars lines hash_net ; newproperty(nil, 20, nil, false) -> hash_net;

recordclass node node_name node_xpos node_ypos node_inarcs node_outarcs ;

recordclass arc arc_start arc_end arc_cases arc_x1 arc_x2 arc_y1 arc_y2
            arc_offset ;

recordclass case case_name case_type case_actions case_fn case_xpos case_ypos;

recordclass net net_roots net_arcs net_nodes ;

recordclass line l_xpos l_ypos l_length ;

define constant find_node n nodes -> node ;
vars x ;
false -> node;
for x in nodes
do    if node_name(x) == n then x -> node exit;
endfor;
enddefine;

define constant find_arc (n1, n2, arcs) -> arc ;
vars x ;
false -> arc;
for x in arcs
do    if arc_start(x)==n1 and arc_end(x)==n2 then x -> arc exit;
endfor;
enddefine;

define constant set_arc (arc_spec,case_number) ;
vars n1 n2 x arc cname actions ;
dest(arc_spec) -> arc_spec -> n1;
dest(arc_spec) -> arc_spec -> n2;
if      find_node(n1,nodes)->>x
then    x -> n1
else    consnode(n1,false,false,nil,nil) -> n1;
        nodes <> [% n1 %] -> nodes;
endif;
if      find_node(n2,nodes) ->> x
then    x -> n2
else    consnode(n2,false,false,nil,nil) -> n2;
        nodes <> [% n2 %] -> nodes
endif;
dest(arc_spec) -> arc_spec -> cname;
unless  find_arc(n1,n2,arcs) ->> arc
then    consarc(n1,n2,nil,false,false,false,false,false) -> arc;
        arcs <> [% arc %] -> arcs;
endunless;
unless  member(arc,node_outarcs(n1))
then    node_outarcs(n1) <> [% arc %] -> node_outarcs(n1)
endunless;
unless  member(arc,node_inarcs(n2))
then    node_inarcs(n2) <> [% arc %] -> node_inarcs(n2)
endunless;
conscase(cname><':'><case_number,cname,hd(arc_spec),false,false,false) -> x;
arc_cases(arc) <> [% x %] -> arc_cases(arc);
enddefine;

define constant find_paths (path,plist) -> plist;
vars x options ;
if      node_outarcs(hd(path))==nil
then    rev(path) :: plist -> plist
else    maplist(node_outarcs(hd(path)),arc_end) -> options;
        for x in options
        do    if      member(x,path)
              then    rev(path) :: plist
              else    find_paths(x :: path,plist)
              endif   -> plist;
        endfor;
endif;
enddefine;

define constant split_path (path) -> paths;
vars tpath ;
until   null(path) or not(node_ypos(fast_front(path)))
do      fast_back(path) -> path
enduntil;
[%  until   null(path) or node_ypos(fast_front(path))
    do      fast_destpair(path) -> path
    enduntil%] -> tpath;
if path == nil then nil else split_path(path) endif -> paths;
unless tpath == nil then tpath :: paths -> paths endunless;
enddefine;

define constant split_paths (old_paths) -> new_paths;
vars path ;
nil -> new_paths;
for path in old_paths do split_path(path) <> new_paths -> new_paths endfor;
enddefine;

define constant arc_length (arc) -> n ;
vars clist x ;
0 -> n; arc_cases(arc) -> clist;
until   null(clist)
do      length(case_name(fast_destpair(clist)->clist)) -> x;
        unless  null(clist)
        then    x + length(case_name(fast_destpair(clist)->clist)) -> x
        endunless;
        if x > n then x -> n endif;
enduntil;
enddefine;

define constant set_xposns (path) ;
vars xpos arc x node ;
1 -> xpos;
for arc in node_inarcs(hd(path))
do  arc_start(arc) -> node;
    node_xpos(node) + length(node_name(node)) + 4 + arc_length(arc)-> x;
    if x > xpos then x -> xpos endif;
endfor;
until   null(path)
do      fast_destpair(path) -> path -> node;
        unless node_xpos(node) then xpos -> node_xpos(node) endunless;
        unless  path == nil
        then    xpos + length(node_name(node)) + 4
                + arc_length(find_arc(node,hd(path),node_outarcs(node))) -> xpos;
        endunless;
enduntil;
enddefine;

define constant clashes (x,y,l,lines) -> t;
vars line ;
false -> t;
for line in lines
do      if      y == l_ypos(line)
        then    if      x <= l_xpos(line)
                then    x+l >= l_xpos(line)
                else    l_xpos(line)+l_length(line) >= x
                endif   -> t;
                if t then exit;
        endif;
endfor;
enddefine;

define constant set_yposns (path) ;
vars node ypos max_y ;
9 -> max_y;
for node in path
do      9 -> ypos;
        while   clashes(node_xpos(node),ypos,length(node_name(node)),lines)
        do      ypos+3 -> ypos
        endwhile;
        consline(node_xpos(node),ypos,length(node_name(node))) :: lines -> lines;
        if ypos > max_y then ypos -> max_y endif;
endfor;
for node in path do max_y -> node_ypos(node) endfor;
enddefine;

define constant set_caseposns cases xpos ypos ;
vars c1 c2 ;
unless  null(cases)
then    fast_destpair(cases) -> cases -> c1;
        xpos -> case_xpos(c1); ypos -> case_ypos(c1);
        unless  null(cases)
        then    fast_destpair(cases) -> cases -> c2;
                xpos + length(case_name(c1)) + 1 -> case_xpos(c2);
                ypos -> case_ypos(c2);
                set_caseposns(cases,xpos,ypos+1)
        endunless;
endunless;
enddefine;

define constant circular (arc);
arc_x1(arc) == arc_x2(arc);
enddefine;

define constant set_arcposns (path);
vars n1 n2 ypos arc x1 l node arcs ;
node_inarcs(hd(path)) -> arcs;
for node in path do arcs <> node_outarcs(node) -> arcs endfor;
[%  for arc in arcs
    do  if not(arc_x1(arc)) and node_xpos(arc_end(arc)) then arc endif
    endfor  %] -> arcs;
for arc in arcs
do  arc_start(arc) -> n1; arc_end(arc) -> n2;
    if      node_xpos(n1) and n1 == n2
    then    node_xpos(n1) ->> arc_x1(arc) -> arc_x2(arc);
    elseif  node_xpos(n1) and node_xpos(n2)
    then    node_xpos(n1) + length(node_name(n1)) + 1 -> arc_x1(arc);
            node_xpos(n2) -1 -> arc_x2(arc);
    else    mishap('Positioning arc when end positions unknown',nil)
    endif;
    node_ypos(arc_start(arc)) ->> ypos -> arc_y1(arc);
    node_ypos(arc_end(arc)) -> arc_y2(arc);
    arc_x1(arc) -> x1; arc_x2(arc) - x1-> l;
    if      l == 0
    then    ypos - 4 -> ypos; x1 - intof(arc_length(arc)/2) - 1 -> x1;
    else    while   clashes(x1,ypos,l,lines)
            do      ypos+3 -> ypos
            endwhile;
    endif;
    ypos -> arc_offset(arc);
    set_caseposns(arc_cases(arc),x1+1,ypos+1);
    consline(x1,ypos,l) :: lines -> lines;
endfor;
enddefine;

define constant place_net (roots,nodes,arcs) ;
vars root paths path lines ;
nil -> paths; nil -> lines;
for root in roots
do  find_paths([% root %] ,paths) -> paths;
endfor;
mostest(paths, procedure (x,y); length(x) > length(y) endprocedure) -> path;
set_xposns(path); set_yposns(path); set_arcposns(path);
applist(paths,set_xposns);
until   (split_paths(delete(path,paths))->>paths) == nil
do      mostest(paths, procedure (x,y);
                       node_xpos(hd(rev(x))) <= node_xpos(hd(rev(y)))
                       endprocedure) -> path;
        set_yposns(path); set_arcposns(path);
enduntil;
enddefine;

define constant set_spec(cat,roots,arc_specs) ;
vars nodes cat arc net arcs case_count nets ;
nil -> arcs; nil -> nodes; 0 -> case_count;
for arc in arc_specs
do  set_arc(arc,case_count+1->>case_count)
endfor;
maplist(roots,find_node(%nodes%)) -> roots;
consnet(roots,arcs,nodes) -> net;
hash_net(cat) <> [% net %] -> hash_net(cat);
place_net(roots,nodes,arcs);
enddefine;

vars syntax <<< syntax >>> syntax endnetwork ;

define constant read_case () -> case;
vars x y ;
if (itemread()->>x) == "endnetwork" then false -> case exit;
itemread() -> y;
itemread() -> case;
if      case == """
then    itemread() ><'' -> case;
        unless itemread()==""" then mishap('Missing closing "',nil) endunless;
endif;
[% x, y, case, nil %] -> case;
if      (itemread()->>x) == "<<<"
then    impseqread() -> case(4);
        unless  itemread() == ">>>"
        then    mishap('>>> not read when expected', nil)
        endunless;
else    unless x == ";" then mishap('; not read when expected', nil) endunless
endif;
enddefine;

vars networks ; if isundef(networks) then nil -> networks endif;

define syntax network ;
vars x cat roots ;
itemread() -> cat; listread() -> roots;
set_spec(cat,roots,[% while read_case() ->> x do x endwhile %]);
cat :: networks -> networks;
enddefine;

define constant 1 clear_grammar ;
until   null(networks)
do      nil -> hash_net(fast_destpair(networks)->networks)
enduntil;
enddefine;

/* The next section displays things on the terminal */

define constant show_node (node) ;                   
vars x y ;
node_xpos(node) -> x; node_ypos(node) -> y; jumpto(x,y);
pr(node_name(node));
if      member(node, net_roots(net))
then    jumpto(x-1, y+1);
        graphcharout(graph_topleft); graphcharout(graph_horz);
        graphcharout(graph_topright);
        jumpto(x-1,y); graphcharout(graph_vert);
        jumpto(x-1,y-1); graphcharout(graph_botleft); graphcharout(graph_horz);
        graphcharout(graph_botright);
        jumpto(x+1,y); graphcharout(graph_vert);
endif;
enddefine;

define constant show_case (cc) ;                   
jumpto(case_xpos(cc),case_ypos(cc)); pr(case_name(cc));
enddefine;

define constant show_arc (arc) ;
vars x1 x2 y1 y2 n ;
show_node(arc_start(arc));
arc_x1(arc) -> x1; arc_x2(arc) -> x2; arc_y1(arc) -> y1; arc_y2(arc) -> y2;
arc_offset(arc) -> n;
jumpto(x1,y1);
if      x1 == x2
then    x1 - intof(arc_length(arc)/2) -> x2;
        jumpto(x2-1,y1-1); graphcharout(graph_topleft);
        h_line(arc_length(arc)+1); graphcharout(graph_topright);
        y1-1 -> y1;
        repeat 2 times jumpto(x2-1,y1-1->>y1); v_bar; endrepeat;
        jumpto(x2-1,y1-1); graphcharout(graph_botleft);
        h_line(arc_length(arc)+1); graphcharout(graph_botright);
        jumpto(x2+2,y1-1); cucharout(`<);
        repeat 2 times jumpto(x2+arc_length(arc)+1,y1); v_bar; y1+1 -> y1;
        endrepeat;
else    if      y1 == n
        then    jumpto(x1,y1)
        else    while (y1+1->>y1) < n do jumpto(x1,y1); v_bar; endwhile;
                jumpto(x1+1->>x1,y1);
        endif;
        h_line(x2-x1);
        jumpto(x2-3,y1); cucharout(`>);
        if      y2 < n
        then    while (y2+1->>y2) < n do jumpto(x2,y2); v_bar; endwhile;
                jumpto(x2,y2); graphcharout(graph_topright);
        endif;
endif;
applist(arc_cases(arc),show_case);
show_node(arc_end(arc));
enddefine;

define constant show_net (net) ;                   
vars poplinewidth ;
100000000 -> poplinewidth;
clear;
applist(net_arcs(net), show_arc);
jumpto(0,3);
enddefine;
