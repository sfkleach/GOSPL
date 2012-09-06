
/* LIB ATNPARSE - atn parser                     Allan Ramsay, 10 January  1984
 * To see how to use it and what it does, see HELP ATNPARSE.
 * If anything goes wrong with it, see Allan */

'Please be patient - this will take some time'.spr; 1.nl;
uses context; uses atndraw;

registers Arc_trace Case_trace Text Cat Tree Child Parent Skip Retry
          Next Actions Hold ;

vars state_stack old_arcs old_cases old_network text ;

define constant macro skip ;
"true", "->", "Skip", ";", termin;
enddefine;

define constant 1 show_stack ;
vars state ;
spr(Cat); Parent -> state;
while isstate(state) do spr(state @ Cat); state @ Parent -> state; endwhile;
enddefine;

define constant show_text (all_text, remainder) ;
jumpto(0,23); spr('Text:');
mode(false);
until   null(all_text) or all_text == remainder
do      spr((dest(all_text)->all_text) @ root)
enduntil;
mode(true);
until   null(all_text)
do      spr((dest(all_text)->all_text) @ root)
enduntil;
nl(1); spr('Tree:'); spr(Tree); clear_eol;
nl(1); spr('Doing:'); show_stack;
enddefine;

define constant show_history (new_arcs, new_cases, old_arcs, old_cases) ;
vars arc case ;
mode(false);
until   null(old_arcs)
do      dest(old_arcs) -> old_arcs -> arc;
        unless  member(arc,new_arcs) or member(arc, old_arcs)
        then    show_arc(arc)
        endunless
enduntil;
until   null(old_cases)
do      dest(old_cases) -> old_cases -> case;
        unless member(case, new_cases) then show_case(case) endunless;
enduntil;
until   null(new_arcs)
do      dest(new_arcs) -> new_arcs -> arc;
        unless  member(arc, new_arcs)
        then    mode(true); show_arc(arc);
                mode(false); applist(arc_cases(arc), show_case);
        endunless;
enduntil;
mode(true); applist(new_cases,show_case);
enddefine;

define constant show_state (net, arc_trace, case_trace) ;
mode(false);
if      net == old_network
then    show_history(arc_trace,case_trace,old_arcs,old_cases);
else    show_net(net);
        net -> old_network;
        show_history(arc_trace,case_trace,nil,nil);
endif;
show_text(text,Text);
arc_trace -> old_arcs; case_trace -> old_cases;
mode(true);
enddefine;

define constant 1 reshow ;
nil -> old_network;
show_state(net, Arc_trace, Case_trace);
jumpto(0,3); clear_eos;
enddefine;

vars display_rec;

define do_display ();
vars case arc net ;
dl(display_rec) -> net -> arc -> case;
unless  Skip
then    show_state(net, arc :: Arc_trace, case :: Case_trace);
        jumpto(0,3); clear_eos; compile(charin);
endunless;
enddefine;

/* NOW we get the routines for actually parsing ATNs */

vars check_actions ;

define constant action_test (tval);
unless tval then false; exitfrom(check_actions); endunless;
enddefine;

define constant check_actions (actions) ;
vars test ;
action_test -> test; actions(); true;
enddefine;

vars fail ;

define constant fail_fn ();
unless  null(state_stack)
then    restart(dest(state_stack)->state_stack);
        if displaying then !Skip -> Skip endif; chain(Retry);
endunless;
enddefine;

conscase(false, false, false, fail_fn, false, false) -> fail;

define add_traces ();
vars arc case net ;
dl(display_rec) -> net -> arc -> case;
unless member(arc,Arc_trace) then arc :: Arc_trace -> Arc_trace endunless;
unless member(case,Case_trace) then case :: Case_trace -> Case_trace endunless;
enddefine;

define constant set_failure (failure);
unless  failure == fail_fn
then    failure -> Retry; split :: state_stack -> state_stack;
endunless;
enddefine;

vars user_fun ; identfn -> user_fun;

define constant jump (failure, success, actions, display_rec) ;
do_display();
if      check_actions(actions)
then    set_failure(failure); add_traces(); user_fun();           
        chain(success);
else    chain(failure);
endif;
enddefine;

define constant branch(failure, success, actions, display_rec);
do_display();
if      check_actions(actions)
then    if      displaying
        then    nil -> Arc_trace; nil -> Case_trace;
        endif;
        set_failure(failure);
        copy(success) -> success; fail_fn -> frozval(1,success);
        user_fun(); chain(success);
else    chain(failure)
endif;
enddefine;

define constant send (failure, actions, display_rec);
vars child ;
do_display();
if      check_actions(actions)
then    set_failure(failure); add_traces(); user_fun();
        unless Parent then exit; /* Send to original state */
        split -> child; restart(Parent); child -> Child;
        if      displaying
        then    !Skip -> Skip; nil ->> old_arcs -> old_cases;
        endif;
        #Hold -> Hold; #Text -> Text;
        Tree <> [% [% #Cat, #Tree %] %] -> Tree;
        if      check_actions(Actions)
        then    user_fun(); chain(Next)
        else    restart(child); chain(failure);
        endif;
else    chain(failure)
endif;
enddefine;

define constant push (failure, success, new_net, type, actions, display_rec) ;
do_display();
set_failure(failure); add_traces();
actions -> Actions; success -> Next; split -> Parent; type -> Cat;
nil -> Case_trace; nil -> Arc_trace; nil -> Tree; chain(new_net);
enddefine;

define constant check_entry (entry, word, self) -> res;
until   null(word)
do      if      member(entry, hd(word)) ->> res
        then    unless  null(tl(word))
                then    tl(word) :: tl(Text) -> Text; set_failure(self);
                endunless;
                word :: tl(Text) -> Text; return; /* !!! */
        endif;
        tl(word) -> word;
enduntil;
enddefine;

define constant check_feature (failure, success, entry, actions, display_rec);
do_display(); set_failure(failure);
if      not(null(Text))
        and check_entry(entry, hd(Text), hd(display_rec))
        and (dest(Text)->Text->Child, check_actions(actions))
then    add_traces(); Tree <> [% [% #root, #cat %] %] -> Tree;
        user_fun(); chain(success);
else    chain(fail_fn)
endif;
enddefine;

define constant parse (text, cat) ;
vars poplinewidth state_stack add_traces do_display ;
define vars macro ; termin; enddefine; /* Locally use <esc> for <termin> */
unless displaying then identfn ->> add_traces -> do_display endunless;
1000000 -> poplinewidth;
new_states;
pre_analyse(text) -> text;
fail_fn -> Retry; text -> Text; false -> Parent; false -> Tree;nil -> Hold;
false -> Skip; cat -> Cat; nil -> Arc_trace; nil -> Case_trace;
nil -> old_arcs; nil -> old_cases; false -> old_network;
[% split %] -> state_stack; nil -> Tree;
apply(case_fn(hd(arc_cases(hd(node_outarcs(hd(net_roots(hd(hash_net(cat))))))))));
until   (null(Text) and not(!Parent)) or null(state_stack)
do      fail_fn()
enduntil;
Tree;
enddefine;

/* The next section "compiles" the grammar */

define constant set_success (arc) ;
vars arcs ;
if      null((node_outarcs(arc_end(arc)) ->> arcs))
then    fail
else    hd(arc_cases(hd(arcs)))
endif;
enddefine;

define constant set_fail (cases, arcs, networks);
if      not(null(cases))
then    hd(cases)
elseif  not(null(arcs))
then    hd(arc_cases(hd(arcs)))
elseif  not(null(networks))
then    hd(arc_cases(hd(node_outarcs(hd(net_roots(hd(networks)))))))
else    fail                     
endif;
enddefine;

vars set_fn ;

define constant compile_next (arcs, nets, initial);
vars success arc cases case ;
until   null(arcs)
do      dest(arcs) -> arcs -> arc; arc_cases(arc) -> cases;
        if      initial or not(case_fn(hd(cases))) /* Check not done already */
        then    set_success(arc) -> success;
                until   null(cases)
                then    dest(cases) -> cases -> case;
                        set_fn(case,arc,net,success,set_fail(cases,arcs,nets));
                enduntil;
        endif;
enduntil;
enddefine;

define constant set_branch_success (nets, entry_point) -> success;
vars node ;
if      null(nets)
then    mishap('Cannot set up branch', [% case %])
elseif  find_node(entry_point, net_nodes(dest(nets)->nets)) ->> node
then    hd(arc_cases(hd(node_outarcs(node)))) -> success
else    set_branch_success(nets, entry_point) -> success
endif;
enddefine;

define constant set_fn (case, arc, net, success, failure);
vars type actions hnet display_rec ;
case_type(case) -> type; [% case, arc, net %] -> display_rec;
if      null((case_actions(case)->>actions))
then    identfn
else    popval([ procedure (); ^^actions endprocedure ])
endif   -> actions;
if      isstring(type)
then    check_feature(% failure, success, conspair("root",consword(type)),
                        actions,display_rec %)
elseif  type == "j"
then    jump(% failure, success, actions, display_rec %)
elseif  type == "branch"
then    branch(%failure,set_branch_success(hash_net(node_name(arc_start(arc))),
                                           node_name(arc_end(arc))),
                actions, display_rec %)
elseif  type == "pop"
then    send(% failure, actions, display_rec %)
elseif  (hash_net(type) ->> hnet) == nil
then    check_feature(% failure, success, conspair("cat", type),
                        actions, display_rec %)
else    push(% failure, success,
               hd(arc_cases(hd(node_outarcs(hd(net_roots(hd(hnet))))))),
               type, actions, display_rec %)
endif   -> case_fn(case);
compile_next(node_outarcs(arc_end(arc)), nil, false);
enddefine;

define constant compile_cat (cat);
vars root net nets arcs ;
hash_net(cat) -> nets;
until   null(nets)
then    dest(nets) -> nets -> net; nil -> arcs;
        for root in net_roots(net) do arcs <> node_outarcs(root) -> arcs endfor;
        compile_next(arcs, nets, true);
enduntil;
enddefine;

define constant plant_calls (cat);
vars net arc case fv n ;
for net in hash_net(cat)
do  for arc in net_arcs(net)
    do  for case in arc_cases(arc)
        do  case_fn(case) -> case; 1 -> n;
            while iscase(frozval(n,case) ->> fv)
            do    case_fn(fv) -> frozval(n, case); n+1 -> n;
            endwhile;
        endfor;
    endfor;
endfor;
enddefine;

define constant 1 set_grammar ;
applist(networks, compile_cat); applist(networks, plant_calls);
enddefine;
