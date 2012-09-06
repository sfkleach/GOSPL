;;; Summary: displays networks using VED

/*

   LIB SHOWNET             Chris Thornton  ---   August 84

   Displays networks using VED.
   Needs streamlining/re-working/re-thinking etc.
   Extra optimizations can be slotted in easily (though mine never seem to
   make any difference! see bottom of file)
*/


;;; Edited by Steve Knight, Sept 93.  Have to get rid of graphcharsetup.
;;; Also, modernise code.

compile_mode :pop11 +strict;
uses drawline;
uses gensym;

module $-shownet
  publish:
    nodelinks             nodeslist
    shownetname           watch
    arrow                 sideways_arrow
    vgap                  hgap
    tallnodes             inverse
    report                backwards
    shownetdefaults       shownetinit
    nodeface              fullnode
    root                  relatives
;

/* user-definable vars & default assignments */
global vars
    nodelinks,
    nodeslist,
    shownetname,
    watch = false,
    arrow = `V`,
    sideways_arrow = `>`,
    vgap = 0,
    hgap = 0,
    tallnodes = false,
    inverse = false,
    report = false,
    backwards = false,
    shownetdefaults,
    shownetinit,
    nodeface = identfn,
    fullnode = identfn,
    root = hd,
    relatives = tl
;

endmodule;



module $-shownet_implementation
  export:
    ved_printable shownet       ved_tallnodes  ved_backwards
    ved_again     ved_sideways  ved_report     ved_inverse
    ved_savenet   ved_watch     netbuffer
  subscribe:
    $-shownet
;

;;; This is a quick compatibility fix. (Steve Knight)
lconstant
    graph_topleft   = `\Gtl`,
    graph_horz      = `\G-`,
    graph_topright  = `\Gtr`,
    graph_vert      = `\G|`,
    graph_botright  = `\Gbr`,
    graph_botleft   = `\Gbl`,
    graph_teeup     = `\Gtt`,
    graph_teeleft   = `\Glt`,
    graph_teedown   = `\Gbt`,
    graph_teeright  = `\Grt`
;



/* vars and properties */

vars
    waveslist
    arrows
    extra_info
    length_waveslist
    chwidth
    chshift
    first_channel
    curr_offset
    curr_channel
    doing_negoffset
    registry
    channel
    CALLS
    left
    right
    bypass
    callees_of
    callers_of
    Nodeface_map
    Fullnode
;



/* default assignments */
1 -> gensym( "net" );



/* general utilities */

define len( struc ); lvars struc;
    if struc and ( islist( struc ) or isvector( struc ) ) then
        length( struc )
    else
        0
    endif
enddefine;


define vgapd( n ); lvars n;
    intof( n fi_+ vgap)
enddefine;


define hgapd( n ); lvars n;
    intof( n fi_+ hgap)
enddefine;


/* define our version of Nodeface */
define Nodeface(key); lvars key;
   lvars face = Nodeface_map( key );
   face or key
enddefine;


define updaterof Nodeface( face, key ); lvars face, key;
   face -> Nodeface_map( key )
enddefine;


define process(key) -> key;
   lvars key face i;
   /* get user definitions */
   nodeface(key); fullnode(key);
   /* make sure we haven't got any strings */
   if isstring(key) then consword(key) -> key endif;
   -> Fullnode(key) -> face;
   if islist(face) or isvector(face) then
      for i from 1 to length(face) do
         consword(''><face(i)) -> face(i)
      endfor;
   else
      consword(''><face) -> face
   endif;
   face -> Nodeface(key);
enddefine;


define add_to_list( item, list ); lvars item, list;
    if member( item, list ) then list else item :: list endif
enddefine;


define addup( list ); lvars list;
    if not( list ) or null( list ) then
        0
    else
        fast_front( list ) fi_+ addup( fast_back( list ) )
    endif
enddefine;


define average(list) -> result; lvars list, result;
   lvars result;
   erase( addup(list) fi_// len(list) -> result )
enddefine;


define tail( list ); lvars list;
    if null( list ) then [] else fast_back( list ) endif
enddefine;


define longest( x ) -> n; lvars x, n;
   lvars structure len face l n i; 0 -> n; false -> len;
   if isprocedure(x) then x -> len else x endif -> structure;
   for i from 1 to length(structure) do
      Nodeface(structure(i)) -> face;
      if
         (if len then
               len(face)
            else
               face;
               if islist(dup()) or isvector(dup()) then
                  longest()
               else
                  datalength()
               endif
            endif ->> l) fi_> n then
         l -> n
      endif
   endfor
enddefine;


define entries( item, list ) -> n; lvars item, list, n;
    lvars item n x; 0 -> n;
    for x in list do if x == item then n fi_+ 1 -> n endif endfor
enddefine;


/*
define frequentest(list) -> item;
   lvars x e item n;
   for x in list do if (entries(x, list)->> e) fi_> n then x -> item; e -> n endif endfor
enddefine;
*/


define difference( n1, n2 ); lvars n1, n2;
    abs( n1 fi_- n2 )
enddefine;


define nearest(num, list) -> result;
    lvars x d diff result num list;
    fast_front(list) -> result;
    difference(num, result) -> diff;
    for x in list do
        if (difference(num, x) ->> d) fi_< diff then
            x -> result;
            d -> diff;
        endif
    endfor
enddefine;


define concat(list);
   lvars list;
   [% applist(list, explode) %]
enddefine;


/* box drawing */


define box( line, col, length_, width ); lvars line, col, length_, width;
    dlocal vedstatic = true;
    vedjumpto(line  fi_+ width  fi_-1,col  fi_+ length_  fi_-1);
    vedcheck();
    vedjumpto(line,col);
    vedcharinsert(graph_topleft);
    repeat length_  fi_- 2 times vedcharinsert(graph_horz) endrepeat;
    vedcharinsert(graph_topright);
    vedchardownleft();
    repeat width  fi_-2 times
        vedcharinsert(graph_vert);
        vedchardownleft()
    endrepeat;
    vedcharinsert(graph_botright);
    vedjumpto(line fi_+width fi_-1,col);
    vedcharinsert(graph_botleft);
    repeat length_  fi_- 2 times vedcharinsert(graph_horz) endrepeat;
    vedjumpto(line fi_+1,col);
    repeat width  fi_-2 times
        vedcharinsert(graph_vert);
        vedchardownleft()
    endrepeat
enddefine;


vars graph_translate;


define vedcharinsertdown(c1);
   lvars c1 c2;
   if (graph_translate(c1) ->> c2) then c2 else c1 endif;
   vedcharinsert();
   vedchardownleft();
enddefine;


define vedboxstring( key, row, col, length_, width ); lvars key, row, col, length_, width;
   dlocal vedstatic = true;
   lvars insert move_pointer;
   lvars i j key face facei length_ width;
   if Fullnode(key) then box(row, col, length_, width) endif;
   if tallnodes then
      vedcharinsertdown -> insert;
      procedure; col fi_+ 1 -> col endprocedure -> move_pointer;
   else
      vedcharinsert -> insert;
      procedure; row fi_+ 1 -> row endprocedure -> move_pointer;
   endif;
   row fi_+ 1 -> row; col fi_+ 1 -> col;
   Nodeface(key) -> face;
   if islist(face) or isvector(face) then
      for i from 1 to length(face) do
         vedjumpto(row, col);
         face(i) -> facei;
         for j from 1 to datalength(facei) do
            insert(facei(j))
         endfor;
         move_pointer();
      endfor
   else
      vedjumpto(row, col);
      for i from 1 to datalength(face) do
         insert(face(i))
      endfor
   endif
enddefine;



/* call-structure functions */
/* - make the 2d association table CALLS more accesible */
/* - facilitate BACKWARDS mode etc. */

define call(callr, calld);
   lvars callr calld;
   CALLS(callr) and CALLS(callr)(calld) and callr /= calld
enddefine;


define updaterof call(val, callr, calld);
   lvars val callr calld;
   if not(isproperty(CALLS(callr))) then
      newassoc([]) -> CALLS(callr)
   endif;
   val -> CALLS(callr)(calld)
enddefine;


vars calls = call;


define called_by(calld, callr);
   lvars calld callr;
   call(callr, calld)
enddefine;


define updaterof called_by(calld, callr);
   lvars calld callr;
   -> call(callr, calld)
enddefine;


define stack( x ); lvars x;
   if x then x endif
enddefine;


define stop();
   exitfrom( caller( 1 ) )
enddefine;


define find_node_in( wave, test, func ); lvars wave, test, func;
   lvars x;
   for x in wave do
      if test( x ) then func( x ) endif
   endfor;
   func( false )
enddefine;


define caller_in(node, wave);
   lvars node wave;
   find_node_in(wave, calls(%node%), stop)
enddefine;


define callers_in(node, wave);
   lvars node wave;
   [%  find_node_in(wave, calls(%node%), stack) %]
enddefine;


define callee_in(node, wave);
   lvars node wave;
   find_node_in(wave, called_by(%node%), stop)
enddefine;


define callees_in(node, wave);
   lvars node wave;
   [% find_node_in(wave, called_by(%node%), stack) %]
enddefine;


define callers(wave);
   lvars node wave;
   [% find_node_in(wave, callee_in(%wave%), stack) %]
enddefine;


define non_callers(wave); lvars wave;
   [% find_node_in(wave, callee_in(%wave%) pdcomp not, stack) %]
enddefine;


define callees(wave); lvars wave;
   [% find_node_in(wave, caller_in(%wave%), stack) %]
enddefine;


define non_callees(wave); lvars wave;
   [% find_node_in(wave, caller_in(%wave%) pdcomp not, stack) %]
enddefine;


/*
SET_CALLS

take the user's data-list and reform it into a 2d association table (CALLS)
and a list of nodes (NODESLIST).
*/

define set_calls();
   lvars node;
   [] -> extra_info;
   if not(islist(nodelinks)) then
      mishap('Argument to SHOWNET must be a list',[]);
   else
      applist(nodelinks,
         procedure(element);
            lvars element callr calld;
            if islist(element) and not(null(element)) then
               process(root(element)) -> callr;
               add_to_list(callr, nodeslist) -> nodeslist;
               for calld in relatives(element) do
                  process(calld) -> calld;
                  if callr /= calld then
                     true -> calls(if inverse then calld,callr else callr,calld endif);
                     add_to_list(calld, nodeslist) -> nodeslist;
                  endif
               endfor;
            else
               element :: extra_info -> extra_info
            endif
         endprocedure);
   endif
enddefine;



/*
SET_WAVESLIST

Using functions which access the CALLS table (CALLERS, NON_CALLERS, CALLEES,
NON_CALLEES) try to reform the NODESLIST into WAVES of nodes, such that
node-node links are only made within waves, or from right to left First factor
out waves of NON_CALLEES then factor out waves of NON_CALLERS.
*/

vars factor_out;

define set_waveslist();
   if null(nodeslist) then mishap('Empty argument for SHOWNET',[]) endif;
   /* NB. second call to factor_out pulls last factor off stack */
   rev([%   factor_out(nodeslist, non_callees, callees),
            factor_out(callers, non_callers) %]) -> waveslist;
   length(waveslist) -> length_waveslist;
enddefine;


/* factor out wave into left and right components, then recurse on factors */
define factor_out(wave, left, right);
   lvars lf rf wave left right;
   if null(wave) then return endif;
   left(wave) -> lf;
   right(wave) -> rf;
   if lf == nil or rf == nil then
      wave
   else
      factor_out(lf, left, right);
      factor_out(rf, left, right);
   endif
enddefine;



/* build channel structure */

define init_channels();
   lvars l;
   longest(nodeslist, unless tallnodes then len endunless) -> l;
   max(l fi_+ 2, 3) -> chwidth;
   (chwidth fi_// 2) fi_+ 1 -> chshift; ->;
   0 ->> curr_channel -> curr_offset;
   false -> doing_negoffset;
   true -> first_channel;
enddefine;


/* NEXT_CHANNEL is a modulated channel repeater */

define next_channel(offset);
   lvars offset;
   if first_channel then
      false -> first_channel
   else
      curr_offset  fi_+ offset -> curr_offset
   endif;
   if (not(doing_negoffset) ->> doing_negoffset) then
      curr_channel  fi_+ curr_offset
   else
      curr_channel  fi_- curr_offset
   endif ->> curr_channel;
enddefine;


/*
SET_BYPASSES

Fix WAVESLIST such that calls are only made between adjacent waves. Insert
pseudo-nodes (BYPASS nodes) into WAVES and re-route links made between
non-adjacent nodes so as to go via these new BYPASS nodes.
*/

define set_bypasses();
   lvars waves node newbp callr callers;
   1 -> gensym("bp");
   /* go through all the waves building cross-wave bypasses where necessary */
   for waves on waveslist do
      for node in waves(1) do
         unless bypass(node) do
            callers_in(node, concat(tail(tail(waves)))) -> callers;
            if not(null(callers)) then
               /* we are going to need a bypass here */
               gensym("bp") -> newbp;
               newbp :: waves(2) -> waves(2);
               newbp :: nodeslist -> nodeslist;
               true -> bypass(newbp);
               /* assign the next free channel to the bypass */
               next_channel(vgapd(2)) -> channel(newbp);
               /* re-route all the calls via the new bypass */
               for callr in callers do
                  true -> calls(callr,newbp);
                  false -> calls(callr,node);
               endfor;
               true -> calls(newbp, node);
            endif
         endunless
      endfor;
   endfor
enddefine;


/* SET_CALLEES_OF & SET_CALLERS_OF

Set up callees_of and callers_of lists for all nodes.
*/

define set_callees_of();
   lvars node;
   for node in nodeslist do
      callees_in(node, nodeslist) -> callees_of(node)
   endfor
enddefine;



define set_callers_of();
   lvars node;
   for node in nodeslist do
      callers_in(node, nodeslist) -> callers_of(node)
   endfor
enddefine;


constant procedure (
    cast_vote,
    select_channel,
    requested_channel,
    preferred_channel
);


define node_priority(nd1, nd2);
   lvars nd1 nd2;
   len(registry(nd1)) fi_>= len(registry(nd2))
enddefine;


define leaf_priority(nd1, nd2);
   lvars nd1 nd2;
   if null(callees_of(nd1)) then
      true
   elseif null(callees_of(nd2)) then
      false
   else
      len(registry(nd1)) fi_>= len(registry(nd2))
   endif
enddefine;


/*
SET_NODECHANNELS

Build up logitudinal structure. Assign an arbitrary channel (a horizontal
offset) to each node in the leftmost wave and then propogate a 'vote' to use
this specific channel to all CALLERS of that node. When assigning channels to
nodes in successive waves -- i.e. to nodes which (probably) already have some
'channel-registry' (VOTES), try to make the assignment 'optimal', given the
state of the asssignees's VOTES list.
*/

vars oldwave, channels;

define set_nodechannels();
    dlocal oldwave, channels;
    lvars allchannels;
    ;;; set up a list of available channels -- make it long.
    [%
        repeat longest( waveslist, len ) fi_* 2 times
            next_channel( vgapd( chwidth fi_+ 1 ) )
        endrepeat
    %] -> allchannels;
    [] -> oldwave;
    lvars waves;
    for waves on waveslist do
        allchannels -> channels;
        ;;; Give highly-interlinked nodes priority except when at the
        ;;; bottom of the tree */
        syssort(
            hd( waves ),
            if null(tail(waves)) then
                leaf_priority
            else
                node_priority
            endif
        ) -> hd( waves );
        lvars node;
        for node in hd(waves) do
            unless bypass(node) do
                select_channel(node) -> channel(node);
                delete(channel(node), channels) -> channels;
                cast_vote(
                    node,
                    channel(node),
                    tail(waves),
                    concat(tail(waves))
                );
            endunless
        endfor;
        hd(waves) -> oldwave;
   endfor
enddefine;


/* a node can occupy a channel ONLY if it calls any brother-node */
/* occupying the same channel in the adjacent wave */
define channel_OK(ch, node);
   lvars ch node co_node;
   for co_node in oldwave do
      if channel(co_node) = ch and not(calls(node, co_node)) then return(false) endif
   endfor;
   return(true)
enddefine;


define requested_channel( node ); lvars node;
    lvars channel;
    ;;; sort out the list of channel registry into rank order.
    syssort(
        registry(node),
        procedure( x, y ); lvars x, y;
            entries(x, registry(node)) fi_>= entries(y, registry(node))
        endprocedure
    ) -> registry(node);
    lvars channel;
    for channel in registry(node) do
        if lmember(channel, channels) and channel_OK(channel, node) then
            return(channel)
        endif
    endfor;
    return(false)
enddefine;


define preferred_channel(node); lvars node;
    dlocal channels;
    lvars ch vote;
    average(registry(node)) -> vote;
    repeat
        if channel_OK((nearest(vote, channels)->> ch),node) then
           return(ch)
        else
           delete(ch, channels) -> channels
        endif;
        if null(channels) then mishap('FUNNY STRUCTURE for SHOWNET',[]) endif;
    endrepeat;
enddefine;


define select_channel(node); lvars node;
    lvars channel;
    if registry(node) then
        if (requested_channel(node) ->> channel) then
            channel
        else
            preferred_channel(node)
        endif
    else
        [0] -> registry(node);
        preferred_channel(node)
    endif;
enddefine;


/* register binding of channel/node, with callers of node */
define cast_vote(node, chv, next_waves, next_nodes);
   lvars callr node chv next_waves next_nodes;
   for callr in callers_of(node) do
      chv :: (unless dup(registry(callr)) do ->; [] endunless) -> registry(callr);
      if member(callr, next_nodes) then
         cast_vote(callr,
            unless dup(channel(callr)) do ->; chv endunless,
               tail(next_waves), concat(tail(next_waves)))
      endif;
   endfor
enddefine;

vars calls, called_by;

define set_channelstructure();
   dlocal calls, called_by;
   init_channels();
   set_bypasses();
   set_callees_of();
   set_callers_of();
   if backwards then
      /* switch the symmetrical call functions and and reverse the waveslist */
      calls; called_by; -> calls; -> called_by;
      rev(waveslist) -> waveslist;
   endif;
   set_nodechannels();
   if backwards then /* switch it back */ rev(waveslist) -> waveslist endif;
enddefine;



/*
DRAW_WAVES

Draw out nodes in the VED buffer in accordance with their WAVE membership, and
their CHANNEL allocation. Space WAVES out laterally, in accordance with the
number of cross-channel links which have to made (i.e. in accordance with the
number of CORRIDORS which are needed).
*/

vars callr calld;

define draw_waves();
    dlocal callr calld;
    lvars curr_corridor;
    lvars curr_left curr_right wave node channel_offset ch;
    0 -> curr_corridor;
    abs(next_channel(chshift)) fi_+ 10 -> channel_offset;
    for wave from 1 to length_waveslist do
        /* establiish a unique corridor for each incoming call */
        for callr in waveslist(wave) do
            applist(
                callees_of(callr),
                procedure(calld); dlocal calld;
                    if channel(calld) = channel(callr) then
                        curr_corridor
                    else
                        (curr_corridor  fi_+  hgapd(1) ->> curr_corridor)
                    endif -> calls(callr, calld);
                endprocedure
            );
        endfor;
        /* establish the right and left edges of the current wave */
        curr_corridor fi_+ hgapd(1) -> curr_left;
        if tallnodes then
            max(2, longest(waveslist(wave), len)  fi_+1)
        else
            longest(waveslist(wave))  fi_+1
        endif fi_+ curr_left -> curr_right;
        ;;; Draw the nodes in the wave.
        for node in waveslist(wave) do
            channel(node) fi_+ channel_offset ->> channel(node) -> ch;
            wave -> registry(node);
            curr_left -> left(node);
            curr_right -> right(node);
            if bypass(node) then
                drawline(curr_left, ch, curr_right, ch);
            else
                vedboxstring(
                    node,
                    (ch fi_- chshift) fi_+1,
                    curr_left,
                    (curr_right fi_- curr_left) fi_+1,
                    chwidth
                );
            endif;
        endfor;
        curr_right  fi_+ hgapd(1)  -> curr_corridor;
    endfor
enddefine;


define drawlines(n);
   lvars x2 y2 x1 y1 n;
   repeat n times
      /* take a 4-tuple off the stack */
      -> y1 -> x1 -> y2 -> x2;
      drawline(x1,y1,x2,y2); x2,y2;
   endrepeat;
   erase(); erase()
enddefine;


/*
DRAW_LINKS

Draw lines connecting the left edges of all CALLER nodes with the right edges
of their respective CALLEE nodes. This has to be done in different ways
depending whether the nodes occupy the same channel, are in adjacent waves
etc.
*/

define draw_links();
    /* draw a link for every call & set up arrows where needed */
    appproperty(
        CALLS,
        procedure( callr, prop ); lvars callr, prop;
            appproperty(
                prop,
                procedure( calld, link_corridor ); lvars calld, link_corridor;

                    define lconstant log_an_arrow_?( offset ); lvars offset;
                       if channel(calld) fi_> channel(callr) then
                          {%
                              (channel(calld) fi_- offset) fi_- 1,
                              link_corridor
                          %} :: arrows -> arrows
                       endif
                    enddefine;

                    if registry(callr) == registry(calld) then
                        ;;; Nodes are in the same wave, must be a foldback link.
                        drawlines(
                            right(calld),        channel(calld),
                            right(calld) fi_+ 1, channel(calld),
                            right(calld) fi_+ 1, channel(calld) fi_- chshift,
                            link_corridor,       channel(calld) fi_- chshift,
                            link_corridor,       channel(callr),
                            left(callr),         channel(callr), 5
                        );
                        log_an_arrow_?(chshift);
                    elseif channel(callr) = channel(calld) then
                        ;;; Must be an adjacent link.
                        drawline(
                            right(calld),
                            channel(calld),
                            left(callr),
                            channel(callr)
                        );
                    else
                        ;;; Must be an ordinary link with a corridor.
                        drawlines(
                            right(calld),  channel(calld),
                            link_corridor, channel(calld),
                            link_corridor, channel(callr),
                            left(callr),   channel(callr), 3
                        );
                        log_an_arrow_?(0);
                    endif;
                endprocedure
            )
        endprocedure
    )
enddefine;


/* draw in disambiguating "arrows" in buffer */
define draw_arrows();
    applist(
        arrows,
        procedure;
            vedjumpto();
            vedcharinsert(arrow);
        endprocedure
    )
enddefine;


define insert_extra_info();
    unless null(extra_info) do
        vedtopfile();
        vedlineabove();
        vedlineabove();
        lvars element;
        for element in rev(extra_info) do
            vedinsertstring( nullstring >< element );
            vedlinebelow();
        endfor
    endunless
enddefine;




/* main procedure */

vars procedure (
    setup_graphmap,
    rm_blanklines,
    mode,
    quitnet,
    shownetdefaults = vedhelpdefaults,
    shownetinit = identfn
);

define macro display_mode;
    lvars toggle = readitem();
    [ ( "^toggle" sys_>< ' mode:' sys_>< mode( ^toggle ) ) ].dl
enddefine;

define macro flip;
   lvars toggle = readitem();
   [
       not( ^toggle ) -> ^toggle;
       display_mode ^toggle
   ].dl
enddefine;


/* SHOWNET: locally redefines vedinitfile so as to do all the work */
/* NB. oldversion of vedinitfile gets executed & re-established in process */
define shownet( arg ); lvars arg;
    arg -> nodelinks;  /* we want it global for re-execute */
    dlocal vedstartwindow;
    dlocal vedautowrite = false;
    dlocal vedstatic = true;
    dlocal vedinitfile;
    dlocal database;

    lvars oldwindow = vedstartwindow;
    lvars _oldchanged = vedchanged;

    setup_graphmap();
    vedsetup();
    24 -> vedstartwindow;

    procedure (oldvedini,flag); lvars flag, oldvedini;
        dlocal vedediting;
        oldvedini -> vedinitfile;
        if vedcurrent = shownetname then
            vedscreenclear();
            shownetinit();
            newassoc([]) -> bypass;
            newassoc([]) -> channel;
            newassoc([]) -> registry;
            newassoc([]) -> CALLS;
            newassoc([]) -> callees_of;
            newassoc([]) -> callers_of;
            newassoc([]) -> left;
            newassoc([]) -> right;
            newproperty([], 16, true, false) -> Fullnode;
            newproperty([], 16, false, false) -> Nodeface_map;
            [] -> arrows;
            [] -> nodeslist;
            vedputmessage('SHOWNET: building call structure');
            set_calls();
            vedputmessage(
                'SHOWNET: building wave structure; ' sys_><
                display_mode inverse
            );
            set_waveslist();
            vedputmessage(
                'SHOWNET: building channel structure; ' sys_><
                display_mode backwards
            );
            set_channelstructure();
            vedputmessage('SHOWNET: planning the layout');
            oldwindow -> vedstartwindow;
            true -> vedstatic;
            false -> vedchanged;
            watch -> vedediting;
            ved_clear();
            draw_waves();
            draw_links();
            draw_arrows();
            rm_blanklines();
            insert_extra_info();
            if report then
               vedendfile(); vedlinebelow(); vedlinebelow();
               vedinsertstring(
                   'SHOWNETNAME:' sys_>< shownetname sys_><
                   '  VGAP:' sys_>< vgap >< '  HGAP:'>< hgap >< '  ' ><
                   display_mode inverse sys_>< '  ' sys_><
                   display_mode backwards
                );
            endif;
            vedjumpto(1,1);
            true -> vedediting;
            if flag then vedrefresh(); endif;
        endif;
        vedinitfile();
    endprocedure(% vedinitfile, vedediting and vedcurrent = shownetname %) -> vedinitfile;

    if vedediting then
        vedsaveglobals(vedcurrentfile)
    endif;
    quitnet();
    vededitor( shownetdefaults, shownetname );
    if isinteger( _oldchanged ) then
        _oldchanged fi_+ 1
    else
        _oldchanged
    endif -> vedchanged;
enddefine;


/* netbuffer returns the vedbuffer SHOWNET generates for the network */
define netbuffer(network); lvars network;
   vedobey(
        shownetname,
        procedure;
            lvars i nw a;
            shownet(network);
            /* trim off any blank lines at top of buffer */
            for i from 1 to vedusedsize(vedbuffer) do
               unless vedbuffer(i) = nullstring do
                   i -> a;
                   quitloop
               endunless;
            endfor;
            {%
                lvars i;
                for i from a to vedusedsize(vedbuffer) do
                    vedbuffer(i)
                endfor
            %};
        endprocedure
    ) ->> it
enddefine;


/* special VED routines */


define mode() with_nargs 1;
   if then 'ON' else 'OFF' endif
enddefine;


define macro display_mode;
   lvars toggle = readitem();
   [ ( "^toggle" sys_>< ' mode:' sys_>< mode( ^toggle ) ) ].dl
enddefine;


define rm_blanklines();
   vedtopfile();
   repeat vedusedsize( vedbuffer ) times
      if vedthisline() = '' then
         vedlinedelete()
      else
         vednextline()
      endif
   endrepeat
enddefine;


define quitnet();
    [%
        lvars file;
        for file in vedbufferlist do
            unless file( 1 ) = shownetname do file endunless
        endfor
    %] -> vedbufferlist
enddefine;


define ved_savenet();
    consstring( destword( gensym( "net" ) ) ) -> shownetname;
    vedputmessage( 'NEW shownetname: ' sys_>< shownetname );
enddefine;

/* make initial assignment */
ved_savenet();


define ved_again();
    shownet( nodelinks )
enddefine;



define ved_backwards();
   flip backwards
enddefine;


define ved_inverse();
   flip inverse
enddefine;


define ved_report();
   flip report
enddefine;


define ved_tallnodes();
   flip tallnodes
enddefine;


define ved_watch;
   flip watch
enddefine;


define trimall();
   vedtopfile();
   repeat vvedbuffersize times vednextline() endrepeat;
enddefine;


define printable( max_width ) -> result; lvars max_width, result;
    lvars l, i, line;
    true -> result;
    vedendfile();
    lvars mw1 = max_width - 1;
    vedinsertstring(
       repeat mw1 times `-` endrepeat,
       consstring( max_width - 1 )
    );
    vedtrimline();
    {%
        for i from 1 to vedusedsize( vedbuffer ) do
            vedbuffer( i )
        endfor;
        for line from 1 to vedusedsize(vedbuffer) do
            vedjumpto(line,1);
            vedtrimline();
            if ( datalength( vedbuffer( line ) ) ->> l ) fi_> max_width then
                substring( max_width, l fi_- mw1, vedbuffer( line ) );
                vedjumpto( line, max_width );
                vedcleartail();
                vedtrimline();
                false -> result;
            endif
        endfor
    %} -> vedbuffer;
    vedusedsize( vedbuffer ) -> vvedbuffersize;
    vedtopfile();
    trimall();
    vedrefresh()
enddefine;


define ved_printable();
   lvars w;
   if vedargument = '' then 133 else vedargnum(vedargument) endif -> w;
   until ( printable( w ) ) do enduntil
enddefine;



/* Jon's  VED_SIDEWAYS  (augmented to cope with arrows ) */

vars graph_map = false;

define setup_graphmap;
    unless graph_map do
        newproperty(
            [
                [^graph_horz ^graph_vert]
                [^graph_vert ^graph_horz]
                [^graph_topright ^graph_botleft]
                [^graph_botleft ^graph_topright]
                [^graph_teeup ^graph_teeleft]
                [^graph_teeleft ^graph_teeup]
                [^graph_teedown ^graph_teeright]
                [^graph_teeright ^graph_teedown]
                [^arrow ^sideways_arrow]
                [^sideways_arrow ^arrow]
            ],
            10, false, true
        ) -> graph_map;
    endunless
enddefine;


define graph_translate(c1); lvars c1;
   lvars c2;
   if (graph_map(c1) ->> c2) then
      c2
   elseif c1 == arrow then
      sideways_arrow
   elseif c1 == sideways_arrow then
      arrow
   else
      c1
   endif
enddefine;


define ved_sideways();
   ;;; interchange rows and columns of a ved buffer
   lvars xmax, x, y, ymax, c1, c2;
   vedusedsize(vedbuffer) -> xmax;
   0 -> ymax;
   vedtopfile();
   for x from 1 to xmax do
      vedtextright();
      max(ymax,vedcolumn fi_-1) -> ymax;
      vednextline();
   endfor;
   {%
       for y from 1 to ymax do
          cons_with consstring {%
              for x from 1 to xmax do
                 if length(vedbuffer(x)) fi_< y then
                    ` `
                 else
                    vedbuffer(x)(y) -> c1;
                    if graph_translate(c1) ->> c2 then
                       c2
                    else
                       c1
                    endif
                 endif
              endfor
           %}
       endfor
   %} -> vedbuffer;
   vedbufferextend();
   vedtopfile();
   for y from 1 to ymax do
      vednextline()       ;;; run over all the lines to get them trimmed
   endfor;
   vedtopfile();
   vedrefresh()
enddefine;

endmodule;
