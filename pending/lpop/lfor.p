/*
This library adds the Pop11 "lfor" syntax.  It also extends the
normal "for" syntax if the next word is "lvars".  The basic
usage is as follows :-

    lfor <varlist> [ <index> ] in <rangelist> do <statements> endlfor
    for lvars <idlist> [ <index> ] in <rangelist> do <statements> endfor

    <varlist>     ::= <vars>, ...
    <vars>        ::= <id> | ( <id>, ... )
    <index>       ::= with_index <id>
    <rangelist>   ::= <modifier> <expression> [ , <rangelist> ]
    <modifier>    ::= [ fast ] <collection>
    <collection>  ::= list | vector | string | ...

For example,

    lfor i, j with_index n in vector v, string s do ... endlfor

It is an attempt to bring the for-loop syntax up to date in 3 ways.

(1) It exposes the underlying regularity of the for-loop
    concepts that have been clouded by inconsistent implementations.

(2) The lfor loop has its own implicit lexical scope which
    prevents variables declared within the loop being visible
    outside.  Furthermore the loop variables are restricted
    to this scope.

    This scope is exited and re-entered each time round the loop.
    This means the loop variables are (in principle) distinct
    on each time round.  This makes an important difference
    in constructions such as

        lfor i in L do procedure(); i endprocedure endlfor

    The above constructs a difference procedure for each
    time round the loop, unlike the old-style loop syntax.

(3) New loop modifiers can be written without having to
    know the details of the Poplog virtual machine.  Furthermore,
    this is acceptably efficient.

    Loop modifiers:
        -> id [ arg ... ] [ arg ... ]
    where
        arg can be _ for erasure

*/

compile_mode :pop11 +strict;

;;; N.B. Part of the name space is reserved for autoloading!  In
;;; particular, "lfor_modifier_" is a reserved prefix.  When such
;;; a file is autoloaded it is *not* expected to define any identifier
;;; but to add to the -lfor_modifiers_table- via -add_lfor_modifier-.

section $-better_syntax =>
    lfor endlfor
    add_lfor_modifier
    lfor_modifiers_table
;

uses isvector:typespec
uses isprocedure:typespec
uses isword:typespec
uses flag:typespec

defclass constant Rule {
    ruleIsNegated       : flag,
    ruleFilters         : isvector,
    ruleCode            : isvector,
    ruleNext            /* false | Rule */
};

define newRule( v );
    consRule( false, nullvector, v, false )
enddefine;

defclass constant Qualifier {
    qualifierChecked    : flag,
    qualifierAccess     : isword
};

define qualifierMustWrite( q );
    q.qualifierAccess /== "ReadOnly"
enddefine;

define qualifierMustRead( q );
    q.qualifierAccess /== "WriteOnly"
enddefine;

;;; One of these is contructed for each modifier in an -lfor-
;;; statement.  The modifier and qualifier fields are more-or-less
;;; obvious.  The vars-vector field is used to store the
;;; set of temporary variables relevant to the use of that
;;; modifier.  This is indexed by position and the mapping into
;;; position is defined below.  (This is infelicitous, as
;;; it has turned out.  Probably not worth the effort to make
;;; beautiful.)
;;;
defclass constant LforState {
    lforStateModifier       : full,     ;;; LforModifier
    lforStateQualifier      : full,     ;;; Qualifier
    lforStateVarsVector     : isvector
};


;;; Every -lfor- modifier is recorded using one of these in
;;; the -lfor_modifiers_table-.
;;;
defclass constant LforModifier {
    lforModifierTitle           : isword,
    lforModifierQualifiers      : isvector,
    lforModifierNeedsIndex      : flag,
    lforModifierNeedsMinLen     : flag,
    lforModifierNumLoopVars     : 8,
    lforModifierNumExtras       : 8,
    lforModifierEnsure          : full,         ;;; false | Rule
    lforModifierInit            : full,         ;;; false | Rule
    lforModifierTest            : full,         ;;; false | Rule
    lforModifierStep            : full,         ;;; false | Rule
    lforModifierQuit            : full,         ;;; false | Rule
};

;;; Constructs the variable vector mapping from the relevant info.
;;;
define makeMap( lvs, idx, min_len, coll, extras ) -> map;
    lvars map = newassoc( [] );
    lvars count = 0;
    lvars v;
    for v in lvs do
        count + 1 -> count;
        count -> map( v );
    endfor;
    count + 1 -> count;
    if idx then
        count -> map( idx )
    endif;
    count + 1 -> count;
    if idx then
        count -> map( min_len )
    endif;
    count + 1 ->> count -> map( coll );
    lvars v;
    for v in extras do
        count + 1 ->> count -> map( v )
    endfor;
enddefine;

;;; Rules are chained on their last field rather than being kept
;;; in a list or vector.  This is for compactness - given that almost
;;; all rules are 0 or 1 in length.
;;;
define packRules( L );
    if L.null then
        false
    else
        lvars ( r, rest ) = L.dest;
        packRules( rest ) -> r.ruleNext;
        r
    endif
enddefine;

;;; These 3 variables are dlocalised during compilation to the
;;; -lfor- statement.
lvars variable_vector;          ;;; the variable vector
lvars min_len_seen_before;      ;;; used to share the min. length info
lvars quit_rule;                ;;; used to implement sharing

define POPMINLEN( n );
    dlocal pop_new_lvar_list;
    lvars min_len = variable_vector( 3 );
    if min_len_seen_before then
        lvars carry_on = sysNEW_LABEL();
        lvars t = sysNEW_LVAR();
        sysPOP( t );
        sysPUSH( t );
        sysPUSH( min_len );
        sysCALL( "fi_<" );
        sysIFNOT( carry_on );
        sysPUSH( t );
        sysPOP( min_len );
        sysLABEL( carry_on );
    else
        sysPOP( min_len )
    endif;
    true -> min_len_seen_before;
enddefine;

define TESTMINLEN( n );
    if min_len_seen_before then
        true -> quit_rule
    else
        true -> min_len_seen_before;
        lvars idx = variable_vector( 2 );
        lvars min_len = variable_vector( 3 );
        sysPUSH( min_len );
        sysPUSH( idx );
        sysCALL( "fi_<" );
    endif
enddefine;

define PUSHV( n );
    sysPUSH( variable_vector( n ) )
enddefine;

define POPV( n );
    sysPOP( variable_vector( n ) );
enddefine;

define CALLV( n );
    sysCALL( variable_vector( n ) )
enddefine;

define UCALLV( n );
    sysUCALL( variable_vector( n ) )
enddefine;

define applyRule( variable_vector, rule );
    dlocal variable_vector;
    lvars i, code = rule.ruleCode;
    for i from 1 by 2 to datalength( code ) do
        code( i )( code( i + 1 ) );
    endfor;
enddefine;

define applyFilters( qualifier, filterv );
    lvars f;
    for f in_vector filterv do
        returnunless( f( qualifier ) )( false )
    endfor;
    return( true )
enddefine;

define applyRuleChain( qualifier, varv, rules, procedure p );
    dlocal quit_rule;
    while rules do
        false -> quit_rule;
        if applyFilters( qualifier, rules.ruleFilters ) then
            applyRule( varv, rules );
            unless quit_rule do
                p( rules )
            endunless
        endif;
        rules.ruleNext -> rules
    endwhile
enddefine;

;;; C = checked
;;; U = unchecked
;;; R = read-only + read-write
;;; W = write-only + read-write
;;; RO = read-only
;;; WO = write-only
;;; RW = read-write
;;;
lconstant flag_keywords = [ C U R W RO WO RW ];

define parseFlags( L ) -> ( keyword, filters, L );
    nullvector -> filters;
    while lmember( L.hd, flag_keywords ) do
        lvars f = L.dest -> L;
        {%
            filters.explode,
            if f == "C" then
                qualifierChecked
            elseif f == "U" then
                procedure( q ); q.qualifierChecked.not endprocedure
            elseif f == "RO" then
                procedure( q ); q.qualifierAccess == "ReadOnly" endprocedure
            elseif f == "R" then
                qualifierMustRead
            elseif f == "WO" then
                procedure( q ); q.qualifierAccess == "WriteOnly" endprocedure
            elseif f == "W" then
                qualifierMustWrite
            elseif f == "RW" then
                procedure( q ); q.qualifierAccess == "ReadWrite" endprocedure
            endif;
        %} -> filters;
    endwhile;
    L.dest -> L -> keyword
enddefine;

define parse( L ) -> ( u, id, inputs, outputs, L );
    if ( L.hd == "->" ) ->> u then
        L.tl -> L;
    endif;
    L.dest -> L -> id;
    L.dest -> L -> inputs;
    L.dest -> L -> outputs;
enddefine;

define makeRules( L, map );
    lvars r;
    for r in L do
        lvars ( keyword, filters ) = r.parseFlags -> r;
        consRule(
            keyword == "until",
            filters,
            {%
                until null( r ) do
                    lvars ( u, id, inputs, outputs ) = r.parse -> r;
                    lvars i;
                    for i in inputs do
                        if i.isword then
                            lvars v = i.map;
                            if v then PUSHV, v else sysPUSH, i endif
                        else
                            sysPUSHQ, i
                        endif
                    endfor;

                    lvars ( callv, call, callq ) =
                        if u then
                            UCALLV, sysUCALL, sysUCALLQ
                        else
                            CALLV, sysCALL, sysCALLQ
                        endif;

                    if id.isword then
                        lvars v = id.map;
                        if v then callv, v else call, id endif
                    else
                        callq, id
                    endif;

                    lvars i;
                    for i in outputs.rev do
                        if i == "_" then
                            sysERASE, i
                        elseif i.isword then
                            lvars v = i.map;
                            if v then POPV, v else sysPOP, i endif
                        else
                            mishap( 'Word needed', [ ^i ] )
                        endif
                    endfor;
                enduntil
            %},
            false
        )
    endfor
enddefine;

define makeLforModifier( keyword, data );
    lvars quals = nullvector;
    lvars lvs = [], coll = false, idx = false, extras = [];
    lvars elist = [], ilist = [], dlist = [], tlist = [], slist = [], qlist = [];
    lvars i;
    for i in data do
        lvars j = i;
        while lmember( j.hd, flag_keywords ) do j.tl -> j endwhile;
        lvars ( k, rest ) = j.dest;
        if k == "loop_lvars" then rest -> lvs
        elseif k == "collection" then rest.hd -> coll
        elseif k == "index" then rest.hd -> idx
        elseif k == "extra_lvars" then rest -> extras
        elseif k == "ensure" then [ ^^elist ^i ] -> elist
        elseif k == "init" then [ ^^ilist ^i ] -> ilist
        elseif k == "while" or k == "until" then [ ^^tlist ^i ] -> tlist
        elseif k == "step" then [ ^^slist ^i ] -> slist
        elseif k == "quit" then [ ^^qlist ^i ] -> qlist
        elseif k == "qualifiers" then rest.destlist.consvector -> quals
        else mishap( 'Unknown keyword', [ ^k ] )
        endif
    endfor;
    lvars map = makeMap( lvs, idx, false, coll, extras );
    consLforModifier((
        keyword,        ;;; type
        quals,          ;;; accepted qualifiers
        idx,            ;;; needs index
        false,          ;;; needs length (no way of user getting this)
        lvs.length,     ;;; # loop vars
        extras.length,  ;;; # extras
        lvars L;
        for L in [ ^elist ^ilist ^tlist ^slist ^qlist ] do
            packRules( [% makeRules( L, map ) %] )
        endfor;
    ));
enddefine;

define lfor_modifiers_table =
    newassoc( [] )
enddefine;

define add_lfor_modifier( defn );
    lvars ( keyword, data ) = defn.dest;
    makeLforModifier( keyword, data ) -> lfor_modifiers_table( keyword )
enddefine;

define need_index_var( modifiers );
    exists( modifiers, lforModifierNeedsIndex )
enddefine;

define doRules( state, procedure p, procedure q );
    applyRuleChain(
        state.lforStateQualifier,
        state.lforStateVarsVector,
        state.lforStateModifier.p,
        q
    )
enddefine;

define collectionVar( s );
    lvars n = s.lforStateModifier.lforModifierNumLoopVars;
    subscrv( n + 3, s.lforStateVarsVector )
enddefine;

define lforAssertionViolation( collection, type );
    mishap( collection, 1, 'Unsuitable argment for ' >< type <> ' iteration' )
enddefine;

define performEnsure( states );
    dlocal min_len_seen_before = false;
    lvars test = undef, n = undef;

    define plant_and( r );
        if r.ruleIsNegated then
            sysCALL( "not" )
        endif;
        n + 1 -> n;
        if n >= 2 then
            sysAND( test )
        endif
    enddefine;

    lvars s;
    for s in states do
        sysNEW_LABEL() -> test;
        0 -> n;
        doRules( s, lforModifierEnsure, plant_and );
        if n > 0 then
            sysLABEL( test );
            lvars continue = sysNEW_LABEL();
            sysIFSO( continue );
            sysPUSH( s.collectionVar );
            sysPUSHQ( s.lforStateModifier.lforModifierTitle );
            sysCALLQ( lforAssertionViolation );
            sysLABEL( continue );
        endif;
    endfor;

enddefine;

define performSkeleton( states, procedure p );
    dlocal min_len_seen_before = false;
    lvars s;
    for s in states do
        doRules( s, p, erase )
    endfor
enddefine;

define performInit =
    performSkeleton(% lforModifierInit %)
enddefine;

define performTest( states, exit_lab );
    dlocal min_len_seen_before = false;
    ;;; check for termination
    lvars s;
    for s in states do
        doRules(
            s, lforModifierTest,
            procedure( r );
                if r.ruleIsNegated then
                    sysIFSO
                else
                    sysIFNOT
                endif( exit_lab )
            endprocedure
        )
    endfor;
enddefine;

define performStep =
    performSkeleton(% lforModifierStep %)
enddefine;

define performQuit =
    performSkeleton(% lforModifierQuit %)
enddefine;

define increment( hidden_index_var, index_var );
    if hidden_index_var then
        sysPUSH( hidden_index_var );
        sysPUSHQ( 1 );
        sysCALL( "fi_+" );
        sysPOP( hidden_index_var );
        if index_var then
            sysPUSH( hidden_index_var );
            sysPOP( index_var )
        endif
    endif;
enddefine;

define check_var( w ) -> w;
    if w.isprotected then
        mishap( 'Loop variable is protected', [ ^w ] )
    endif;
    lvars id = w.identprops;
    unless id == "undef" or id.isinteger then
        mishap( 'Loop variable is pre-existing syntax or macro', [ ^w ] )
    endunless;
enddefine;

define grab_loop_vars();

    define grab();
        [%
            lvars t = readitem();
            if t == "(" then
                readitem().check_var;
                while pop11_try_nextreaditem( "," ) do
                    readitem().check_var
                endwhile;
                pop11_need_nextreaditem( ")" ).erase
            else
                t.check_var
            endif;
        %]
    enddefine;

    [%
        grab();
        repeat
            lvars tok = pop11_try_nextreaditem( [ , in with_index ] );
            unless tok == "," do
                tok :: proglist -> proglist;
                quitloop
            endunless;
            grab()
        endrepeat
    %]
enddefine;

define grab_index_var();
    pop11_try_nextitem( "with_index" ) and readitem().check_var
enddefine;

define lconstant insertQualifier( r, q ) -> r;
    {% r.ruleFilters.explode, q %} -> r.ruleFilters
enddefine;

define lconstant setChecked =
    insertQualifier(% qualifierChecked %)
enddefine;

define lconstant setNegated( r ) -> r;
    true -> ruleIsNegated( r )
enddefine;

define lconstant setWrite =
    insertQualifier(% qualifierMustWrite %)
enddefine;

define lconstant setRead =
    insertQualifier(% qualifierMustRead %)
enddefine;

define newVectorclassModifier( key );

    ;;; variable map
    ;;;     1.  loop variable, bound to each element in turn
    ;;;     2.  the hidden index variable
    ;;;     3.  the shared minimum length variable
    ;;;     4.  the collection variable
    ;;;     5.  an extra variable initialised to the length
    lconstant
        lv = 1,                 ;;; i
        idx = 2,                ;;; n
        len = 3,                ;;; min len
        coll = 4;               ;;; v

    lconstant accepted_qs = { fast update update_only };

    consLforModifier(
        key.class_dataword,     ;;; type
        accepted_qs,            ;;; accepts all qualifiers
        true,                   ;;; needs index
        true,                   ;;; shares length
        1,                      ;;; num loop vars
        1,                      ;;; num extras
        newRule( {%                         ;;; -- ENSURE --
            PUSHV, coll,
            sysCALLQ, class_recognise( key )
        %} ).setChecked,
        newRule( {%                         ;;; -- INIT --
            PUSHV, coll,
            sysCALL, "datalength",
            POPMINLEN, len
        %} ),
        newRule( {%                         ;;; -- TEST --
            TESTMINLEN, len
        %} ).setNegated,
        newRule( {%                         ;;; -- STEP --
            PUSHV, idx,
            PUSHV, coll,
            sysCALLQ, class_fast_subscr( key ),
            POPV, lv
        %} ).setRead,
        newRule( {%                         ;;; -- QUIT --
            PUSHV, lv,
            PUSHV, idx,
            PUSHV, coll,
            sysUCALL, "fast_subscrv"
        %} ).setWrite
    )
enddefine;

define fetch_modifier( keyword ) -> m;
    keyword.lfor_modifiers_table -> m;
    if not( m ) and keyword.isword then
        lvars key = key_of_dataword( keyword );
        if key.isvectorclasskey then
            key.newVectorclassModifier -> m
        else
            if sys_autoload( "lfor_modifier_" <> keyword ) then
                keyword.lfor_modifiers_table -> m
            endif;
            unless m do
                mishap( 'Invalid lfor modifier', [ ^keyword ] )
            endunless
        endif
    endif
enddefine;

define checkCompatibility( w, m );
    unless lmember( w, m.lforModifierQualifiers ) do
        mishap( 'Invalid qualifier', [% w, m.lforModifierTitle %] )
    endunless
enddefine;

define grab_ranges();
    pop11_need_nextreaditem( "in" ).erase;
    lvars mods = [], tmps = [], quals = [];
    repeat
        lvars q = consQualifier( true, "ReadOnly" );
        lvars tokens =
            [%
                repeat
                    lvars tok = pop11_try_nextreaditem( [ fast update update_only ] );
                    quitunless( tok );
                    if tok == "fast" then false -> q.qualifierChecked
                    elseif tok == "update" then "ReadWrite" -> q.qualifierAccess
                    elseif tok == "update_only" then "WriteOnly" -> q.qualifierAccess
                    else mishap( 'Internal error: no such qualifier', [ ^tok ] )
                    endif;
                endrepeat;
            %];
        lvars m = readitem().fetch_modifier;
        lblock
            lvars i;
            for i in tokens do
                checkCompatibility( i, m )
            endfor
        endlblock;
        lvars t = sysNEW_LVAR();
        lvars tok = pop11_comp_expr_to( [ , do ] );
        sysPOP( t );
        conspair( q, quals ) -> quals;
        conspair( m, mods ) -> mods;
        conspair( t, tmps ) -> tmps;
        quitif( tok == "do" );
    endrepeat;
    return( quals.ncrev, mods.ncrev, tmps.ncrev );
enddefine;

define compileLfor( closing_keyword );
    dlocal pop_new_lvar_list;
    lvars loop_vars = grab_loop_vars();
    lvars index_var = grab_index_var();
    lvars hidden_index_var = false;
    lvars min_len = false;
    lvars ( qualifiers, modifiers, coll_vars ) = grab_ranges();

    ;;; Create the invisible index variable when either
    ;;; there's an explicit index variable or a modifier
    ;;; requires one.
    if index_var or modifiers.need_index_var then
        sysNEW_LVAR() -> hidden_index_var
    endif;

    ;;; Create the invisible min length variable if
    ;;; any modifier is a vectorclass modifier.
    if exists( modifiers, lforModifierNeedsMinLen ) then
        sysNEW_LVAR() -> min_len
    endif;

    lvars real_start_lab = sysNEW_LABEL();
    lvars start_lab = sysNEW_LABEL().dup.pop11_loop_start;
    lvars exit_lab = sysNEW_LABEL().dup.pop11_loop_end;

    lvars lfor_states =
        [%
            lvars q, m, cv, lv;
            for lv, q, m, cv in loop_vars, qualifiers, modifiers, coll_vars do
                unless length( lv ) == m.lforModifierNumLoopVars do
                    mishap( 'Mismatched number of loop variables', [] )
                endunless;
                consLforState(
                    m,
                    q,
                    {%
                        lv.dl,
                        hidden_index_var,
                        min_len,
                        cv,
                        repeat m.lforModifierNumExtras times
                            sysNEW_LVAR()
                        endrepeat
                    %}
                )
            endfor;
        %];


    performEnsure( lfor_states );
    performInit( lfor_states );

    ;;; Initialise the hidden index.
    if hidden_index_var then sysPUSHQ( 0 ); sysPOP( hidden_index_var ) endif;

    sysLABEL( real_start_lab );
    sysLBLOCK( popexecute );

    ;;; The position of the following declarations means they
    ;;; are rebound each loop trip.
    ;;; First, declare the loop variables ...
    lvars v;
    for v in loop_vars.flatten do sysLVARS( v, 0 ) endfor;
    ;;; ... and the index variable.
    if index_var then sysLVARS( index_var, 0 ) endif;

    ;;; Increment the hidden index and copy to the index.
    increment( hidden_index_var, index_var );

    performTest( lfor_states, exit_lab );
    performStep( lfor_states );

    closing_keyword.pop11_comp_stmnt_seq_to.erase;

    sysLABEL( start_lab );
    performQuit( lfor_states );
    sysGOTO( real_start_lab );
    sysENDLBLOCK();
    sysLABEL( exit_lab );
enddefine;

;;; -- Particular modifiers -------------------------------------------

[ repeater
    [ qualifiers fast ]
    [ loop_lvars i ]
    [ collection r ]
    [ C ensure isprocedure [ r ] [] ]
    [ until
        fast_apply [ r ] [ i ]
        == [ ^termin i ] []
    ]
].add_lfor_modifier;

[ list
    [ qualifiers fast update update_only ]
    [ loop_lvars i ]
    [ collection c ]
    [ C until null [ c ] [] ]
    [ U until == [ nil c ] [] ]
    [ RO step fast_destpair [ c ] [ i c ] ]
    [ RW step fast_front [ c ] [ i ] ]
    [ W quit -> fast_front [ i c ] [] fast_back [ c ] [ c ] ]
].add_lfor_modifier;

[ list_tails
    [ qualifiers fast ]
    [ loop_lvars t ]
    [ collection L ]
    [ C until null [ L ] [] ]
    [ U until == [ nil L ] [] ]
    [ step fast_back [ L L ] [ t L ] ]
].add_lfor_modifier;

[ tails
    [ qualifiers fast ]
    [ loop_lvars t ]
    [ collection L ]
    [ until isnull [ L ] [] ]
    [ step allbutfirst [ L 1 L ] [ t L ] ]
].add_lfor_modifier;

;;; Ideally we would like to use sys_grbg_destpair rather than fast_destpair
;;; but we cannot in the presence of process copying!  It would be
;;; plausible to choose sys_grbg_destpair when the U flag is on ... but
;;; it is simply too dangerous, in my view.
[ property
    [ qualifiers fast update ]
    [ loop_lvars k v ]
    [ collection p ]
    [ extra_lvars L ]
    [ C ensure isproperty [ p ] [] ]
    [ init % procedure( p ); [% fast_appproperty( p, conspair ) %] endprocedure % [ p ] [ L ] ]
    [ until == [ nil L ] [] ]
    [ step fast_destpair [ L ] [ L ] fast_destpair [] [ k v ] ]
    [ W quit -> fast_apply [ v k p ] [] ]
].add_lfor_modifier;

newVectorclassModifier( vector_key ) -> "vector".lfor_modifiers_table;
newVectorclassModifier( string_key ) -> "string".lfor_modifiers_table;

/*  Preserved for documentation.
[ vector
    [ loop_lvars i ]
    [ collection v ]
    [ index n ]
    [ extra_lvars len ]
    [ ensure isvector [ v ] [ -> ] ]
    [ init datalength [ v ] [ len ] ]
    [ until fi_< [ len n ] [ -> ] ]
    [ step fast_subscrv [ n v ] [ i ] ]
].add_lfor_modifier;
*/


;;; -- Binding to Syntax ----------------------------------------------

global vars syntax endlfor;

define global syntax lfor;
    compileLfor( "endlfor" )
enddefine;

#_IF DEF ved
    unless lmember( "lfor", vedopeners ) do
        [ lfor ^^vedopeners ] -> vedopeners
    endunless;
    unless lmember( "endlfor", vedclosers ) do
        [ endlfor ^^vedclosers ] -> vedclosers
    endunless;
#_ENDIF

endsection;
