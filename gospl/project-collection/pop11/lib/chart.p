;;; LIB CHART by Steve Isard - May 1983
/* A chart parser can be thought of as a program which builds up a set of
   assertions about a string of words.  There are two kinds of assertions:
   (1) COMPLETE ASSERTIONS take the form "the substring from (say) the 3rd
   word to (say) the 5th word can serve as an NP"
   (2) PARTIAL ASSERTIONS take the form "the substring from the 3rd word
   to the 5th word could be the beginning of an NP, if we could find (say)
   a PP starting at the 6th word with which to complete the NP"

   New assertions are formed by a sort of deduction: Given a partial
   assertion saying that words 3 to 5 could be the beginning of an NP, if
   there were a PP starting at word 6, and a complete assertion
   saying that words 6 through 9 can constitute a PP, then we "deduce" a
   new assertion saying that words 3 through 9 can be an NP.

   The goal, of course, is to arrive at an assertion that the entire
   string can constitute a sentence.

   It is common to visualize this process of assertion-making as one of
   drawing lines from one word to another.  An assertion that words 3 to 5
   make an NP is represented by a line labelled NP spanning words 3 to 5.

                      __ NP __
                     /        \
                    /          \
        I   saw   the   fat   cat  on  the   mat

   The whole assortment of labelled lines is known as a chart, hence the
   name chart parser.  The individual lines are known as edges.

   To represent the process of building a chart in POP11, we need a way
   of representing edges.  So we decree a new kind of POP11 object called an
   "edge". These edges are to have several components (or slots or subparts),
   namely:
        edge_label, a symbol like NP
        edge_leftend, the number of the word where the edge begins
        edge_rightend, the number of the word where the edge ends
        subedges, a list of edges corresponding to the the subparts of the
            syntactic constituent spanned by this edge.  E.g., an edge
            labelled S stretching from from word 1 to word 6 might have
            a subedge labelled NP stretching from word 1 to word 3, and one
            labelled VP stretching from word 4 to word 6
        edges_sought, a list of the subedges needed to complete a partial
            edge.  For instance, a partial S edge might already have an NP
            subedge, but still need a VP to be complete

        The following line says "let there be such edges".  (See HELP
        RECORDCLASS for a more technical explanation.) A procedure
        CONSEDGE is also brought into being for constructing instances of
        edges.
*/
recordclass edge edge_label edge_leftend edge_rightend subedges edges_sought;

/*  A syntax rule has a left-hand side (the symbol before the arrow) and
    a right-hand side (the string of symbols after the arrow).
*/
recordclass rule rule_lhs rule_rhs;

/* Test for whether an edge is partial or complete.  If there is anything in
   its set of edges_sought, then it is partial.
*/
define partial(edge);
    edges_sought(edge) /== []
enddefine;

/*  The "deduction" procedure which constructs a new edge incorporating a
   partial edge and a neighbouring complete edge of the type that it is
   "seeking".
*/
define extendedge(e1,e2)->newedge;
    consedge(edge_label(e1),edge_leftend(e1),edge_rightend(e2),
                [%dl(subedges(e1)),e2%],tl(edges_sought(e1)))->newedge;
enddefine;

define emptyedge(rule,starting)->newedge;
    consedge(rule_lhs(rule),starting,starting,[],rule_rhs(rule))->newedge;
enddefine;

/* This procedure builds an edge spanning a single word, after the syntactic
   category of the word has been looked up in the dictionary.
*/
define lexicaledge(category,word,position)->newedge;
    consedge(category,position,position+1,word,[])->newedge;
enddefine;

/*  This is the main procedure.  It takes a list of words as input and
   returns as output the set of complete edges that it has been able to build.
   It maintains an "agenda" - a list pairs of edges that can be combined to
   form new edges - and it works through this agenda until no more combining
   is possible. New items can get added to the agenda when a new edge that
   has been formed by combination can itself combine with an existing edge.
   The procedure begins by looking up the syntactic categories of the words
   it has been given, and building the corresponding lexical edges.
*/
vars lookupedges, incorporate;
define alledges(wordlist) -> completeedges;
    vars item partialedges agenda newedge;
    lookupedges(wordlist) -> completeedges->partialedges->agenda;

    until agenda == [] then
        dest(agenda) -> agenda -> item;
        extendedge(item(1),item(2)) -> newedge;
        incorporate(newedge)<>agenda -> agenda;
    enduntil;
enddefine;

/*  This procedure finds the syntactic categories of the words it has
   been given, builds corresponding lexical edges, and sets off the combining
   process by building partial edges which begin with these lexical edges.
   For instance, if a word has been classed as a determiner, a partial NP
   edge, seeking, say, a noun, will be constructed.  If these partial
   edges raise possibilities for combination, they are put on the agenda.
*/
vars lex_categories;
define lookupedges(wordlist)->completeedges->partialedges->agenda;
    vars i,c,w,newedge;
    [%repeat length(wordlist) times [] endrepeat%] -> completeedges;
    [%repeat length(wordlist) + 1 times [] endrepeat%] -> partialedges;
    [] -> agenda;

    for i from 1 to length(wordlist) do
        wordlist(i) -> w;
        for c in lex_categories(w) do
            lexicaledge(c,w,i) -> newedge;
            incorporate(newedge) <> agenda -> agenda;
        endfor;
    endfor;
enddefine;

/* Every time a new edge is constructed, it is added to the set of partial
   or complete edges, whichever is appropriate, and any possible combinations
   that it can enter into are put on the agenda.
   The sets of partial and complete edges are represented not as simple
   lists, but as lists of lists.  The complete edges beginning at word 1
   are in sublist 1 of completeedges, the complete edges beginning at word
   2 in sublist 2, and so on.  Partial edges are listed according to the
   place where they end, those finishing at word 1 in sublist 1, etc..
   This system makes it easy to pair up edges that might be able to combine.
*/
vars addpartial,addcomplete;
define incorporate(newedge)->agendaitems;
    if partial(newedge) then
        addpartial(newedge);
    else
        addcomplete(newedge);
    endif;
    ->agendaitems;
enddefine;

/*  What to do if the edge being added is complete. Put it in the appropriate
    list, make partial edges starting with it (e.g. a complete NP
    causes the construction of a partial S, with the NP as subedge and
    seeking a VP), and look to see whether it can combine with any
    existing partial edges. It is the procedure spawnhigheredges which
    postulates the new partial edges, and its presence here is what makes
    the parser bottom-up.
*/
vars spawnhigheredges, pairwithpartials;
define addcomplete(newedge)->agendaitems;
    newedge::completeedges(edge_leftend(newedge))
        ->completeedges(edge_leftend(newedge));
    spawnhigheredges(edge_label(newedge),edge_leftend(newedge))<>
        partialedges(edge_leftend(newedge))
        ->partialedges(edge_leftend(newedge));
    pairwithpartials(newedge)->agendaitems;
enddefine;

/*  What to do if the edge being added is partial.  Add it to a list and
   look for complete edges it might combine with.
*/
vars pairwithcompletes;
define addpartial(newedge)->agendaitems;
    newedge::partialedges(edge_rightend(newedge))
        ->partialedges(edge_rightend(newedge));
    pairwithcompletes(newedge)->agendaitems;
enddefine;

/* Look for partial edges that a new complete edge can combine with */
define pairwithpartials(newedge)->agendaitems;
    vars a;
    [%  for a in partialedges(edge_leftend(newedge)) do
            if edge_label(newedge) == hd(edges_sought(a))
                then [%a,newedge%]
            endif
        endfor
    %] ->agendaitems;
enddefine;

/* Look for complete edges that a new partial edge can combine with */
define pairwithcompletes(newedge)->agendaitems;
    vars i;
    [%
         if edge_rightend(newedge) <= length(wordlist) then
             for i in completeedges(edge_rightend(newedge)) do
                 if edge_label(i) == hd(edges_sought(newedge))
                 then [%newedge,i%]
                 endif
             endfor
         endif;
    %] ->agendaitems;
enddefine;

/* Use the set of syntax rules to find what syntactic groupings can begin
  with an item of a given category (e.g. an S can begin with an NP by virtue
  of the rule S->NP VP), and construct appropriate partial edges.
*/
vars ruleset;
define spawnhigheredges(edgelabel,starting)->edgelist;
    vars newedge r;
    [%  for r in ruleset do
            if hd(rule_rhs(r)) == edgelabel then
                emptyedge(r,starting) -> newedge;
                unless member(newedge,partialedges(starting)) then
                    newedge;
                endunless;
            endif
        endfor
    %] -> edgelist;
enddefine;

/* This is just to make everything pretty.  The user can type in
   --- followed by some words, and we arrange for the words to be put into
  a list and given as input to alledges.  At the end, any complete edges
  labelled S and stretching from the beginning of the words to the end are
  printed out in tree format.
*/
vars readsentence, treepr;
define macro ---;
    vars completeedges words e;
    readsentence() -> words;
    alledges(words)->completeedges;
    for e in completeedges(1) do
        if edge_label(e) == "S" and edge_rightend(e) == length(words) + 1
            then treepr(e)
        endif;
    endfor;
enddefine;

/* Procedures for reading in rules, in the form in which they appear below,
   and constructing a list of "rule" records.  For the time being, features
   are ignored.*/      
vars skipfeatures getridofarrow makerulerecords;
define macro rules;
  vars category rightside features;
  []->ruleset;
  until (dest(readline())->rightside->category,category="thatsall") then
    skipfeatures(rightside)->rightside;
    getridofarrow(rightside)->rightside;
    makerulerecords(category,rightside)<>ruleset -> ruleset;
  close;
end;

function makerulerecords(category,rightside);
    vars first rest;
    [%  while rightside matches [??first | ??rest] then
            consrule(category,first),
            rest -> rightside;
        endwhile,
        consrule(category,rightside);
    %]
end;

function skipfeatures(rightside) -> rightside;
    vars wd skipping;
    false -> skipping;
    [%  for wd in rightside do
            if wd == "(" then true -> skipping;
            elseif wd == ")" then false -> skipping;
            elseif not(skipping) then wd
            endif
        endfor;
    %] -> rightside;
end;

function getridofarrow(rightside)=>rightside;
    if hd(rightside) == "->" then tl(rightside) -> rightside;
    endif;
end;

rules
S (num) -> Np(num case:subj) Vp(num) | S conj S
S (num) -> Np(num case:subj) cop(num) ppart
S(num) -> Np(num case:subj) cop(num) ppart passmarker Np(case:obj)
Np (num case) -> det(num) Nn(num) | det(num) Nn(num) Pp | pn(num case)
Np -> Np conj Np
Nn(num) -> n(num) | adj n(num)
Vp(num)  -> v(num tr:trans) Np(case:obj) | v(num tr:intrans) | cop(num) adj
Vp(num) -> Vp(num) Pp
Pp -> prep Np(case:obj)
thatsall

/* Procedures for reading in dictionary entries.  The form of the dictionary
   is seen below.  A series of entries preceded by a line containing the
   word "lexicon" at the top and followed by a line containing "thatsall"
   at the bottom is turned into a "property list" (See HELP NEWPROPERTY)
   called lex_categories.  Lex_categories acts like a procedure, which,
   given a word as input, returns the list of syntactic categories listed in
   the entry for the word. E.g. lex_categories("cages") returns the list
   [N V] .  Features are ignored for the time being.
*/

define macro lexicon;
    vars word rightside plist;
    [%  until (itemread()->word,word="thatsall") then
            skipfeatures(readline())->rightside;
            [^word
                [%  while rightside matches [?first | ??rest] then first,
                        rest->rightside
                    endwhile;
                    hd(rightside);
                %]
            ]
        enduntil
    %]->plist;
    newproperty(plist,length(plist),"??",true)->lex_categories;
end;

lexicon
a det(num:sing)
and conj
are cop(num:pl)
ball n (num : sing)
big adj
bitten ppart
blue adj
boy n(num:sing)
boys n(num:pl)
by passmarker | prep
cage n(num:sing) | v(num:pl tr:trans)
caged v(tr:trans) | ppart
cages n(num:pl) | v(num:sing tr:trans)
computer n(num:sing)
computers n(num:pl)
enormous adj
fifty det(num:pl)
four det(num:pl)
girl n(num:sing)
girls n(num:pl)
green adj
he pn(num:sing case:subj)
her pn(num:sing case:obj)
him pn(num:sing case:obj)
hit v(tr:trans) | ppart
hits v(tr:trans num:sing)
in prep
is cop(num:sing)
little adj
mic pn(num:sing)
micro n(num:sing)
micros n(num:pl)
on prep
one n(num:sing) | pn(num:sing) | det(num:sing)
ones n(num:pl)
pdp11 n(num:sing)
pdp11s n(num:pl)
pigeon n(num:sing)
pigeons n(num:pl)
program n(num:sing) | v(num:pl tr:trans)
programmed v( tr:trans) | ppart
programs n(num:pl) | v(num:sing tr:trans)
punish v(num:pl tr:trans)
punished v( tr:trans) | ppart               
punishes v(num:sing tr:trans)
ran v(tr:intrans)
rat n(num:sing)
rats n(num:pl)
red adj
reinforce v (num:pl tr:trans)
reinforced v ( tr:trans) | ppart
reinforces v (num:s tr:trans)
room n(num:sing)
rooms n(num:pl)
run v(tr:intrans num:pl)
runs v(tr:intrans num:sing)
she pn(num:sing case:subj)
steve pn(num:sing)
stuart pn(num:sing)
suffer v(num:pl tr:intrans)
suffered v( tr:intrans)
suffers v(num:sing tr:intrans)
that det(num:sing)
the det
them pn(num:pl case:obj)
these det(num:pl)
they pn(num:pl case:subj)
those det (num:pl)
three det(num:pl)
two det(num:pl)
undergraduates n(num:pl)
universities n(num:pl)
university n(num:sing)
was cop(num:sing)
were cop(num:pl)
thatsall

/* Procedures for printing out parse trees */

vars dent;
function treepr(tree);
    dent(tree,0);
    1.nl;
end;

define dent(edge,howfar);
    1.nl;
    sp(howfar*4);
    pr(edge_label(edge));
    if not(islist(subedges(edge))) then sp(4); pr(subedges(edge));
    else
        applist(subedges(edge),dent(%howfar+1%));
    endif;
enddefine;

;;; The procedure readsentence is based on the library procedure readline.
;;; The difference is that it eliminates punctuation marks and converts all
;;; characters to lower case, so that sentences can be typed with or without
;;; punctuation or capitals.

vars Uppertolower; `a - `A -> Uppertolower;

function readsentence();
    vars proglist item char;
    incharitem(
        lambda ();
            cucharin() -> char;
            if  char == `\n
            then    termin
            elseif char == `. or char == `, or char == `; then
                ` ;;; a space character
            elseif `A <= char and char <= `Z then
                Uppertolower + char
            else    char
            close
        end).pdtolist
    -> proglist;
    [%until (readitem() -> item, item == termin) then
        if item == "[" then
            item :: proglist -> proglist;
            listread()
        else
            item
        close
      close%];
    if char == termin then erase(), termin close;
end;

ppr( 'To parse a string of words type\
    ---\
followed by (a space and) the words.\
Examples:\
--- The computers in the university are programmed by the undergraduates.\
--- they reinforce the rats in the cages in the room\
--- the pigeons are punished and they suffer.\n');
