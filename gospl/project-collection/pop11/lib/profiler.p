;;; Summary: 			Jon Meyer's alpha release of a code profiler
;;; Contributor: 		Jonathan Meyer, 1992
;;; Acknowledgements:   Based on work by John Williams

section;

uses showtree; ;;; not compiled with compile_mode +strict...

compile_mode :pop11 +strict;

/* Tree, Present and Active time profiling */

applist([
	sysPROFILER sysENDPROFILER
	profiler endprofiler
	profiler_start
	profiler_end
	profiler_apply
	profiler_counters
	profiler_interrupt
	p_profile
    a_profile
	t_profile
  ], sysunprotect);

global vars
    profiler_exclude                =   [^null],
    profiler_interval     			=   1,
    profiler_counters               =   [],
  ;

/* Each profile has the following data localised to it: */
lconstant
  macro (
	PF_USERNAME		= 1,  /* name of profile */
	PF_FREQ 		= 2,  /* how many times the profile was sampled */
	PF_TIME 		= 3,  /* length of time the profile has run for */
	PF_PRESENT		= 4,  /* present profile */
	PF_ACTIVE		= 5,  /* active profile */
	PF_TREE			= 6,  /* tree profile */
	PF_CSTACKLEN 	= 7,  /* what point in the callstack the profile started */
	PF_NPROPS		= 7,  /* number of profiler properties */
  ),
;

;;; optional sys_system_procedure_name procedure
weak constant procedure (sys_system_procedure_name);
define :inline lconstant SYS_PROC_NAME(p);
	(testdef sys_system_procedure_name and
		weakref sys_system_procedure_name(p))
enddefine;

define lconstant Check_display_attribs(list) -> list;
	lvars list, item;
	if list = [all] then [tree, present, active] -> list;
	else
		for item in list do
			unless fast_lmember(item, [, tree present active]) do
				mishap(item,1,'INVALID PROFILER ATTRIBUTE');
			endunless;
		endfor;
	endif;
enddefine;

;;; default definition for profiler_include
define global vars procedure profiler_include(p);
	lvars p, props = pdprops(p);
	(props or SYS_PROC_NAME(p)) and not(fast_lmember(p, profiler_exclude) or
			fast_lmember(props, profiler_exclude));
enddefine;

;;; procedure to perform collection of profile statistics
define profiler_interrupt();
    lvars p_pos, p_index, p, met = [], met_p, do_p, cstacklen, table, time,
			child, do_child, prop, node, start_index, done_active = false;
	/*
		-p- is the procedure that we are currently profiling.
		-child- is the procedure that -p- is currently doing.
		-p_pos- is the position of -p- on the callstack (1=top).
		-p_index- is the position of -p- on the callstack (1=bottom).
	*/
    returnif(profiler_counters == []); ;;; nothing to profile!

	;;; we record how long each interrupt takes and subtract that from
	;;; runtime for the profile
	systime() -> time;

	;;; start collecting data at the 4th caller of the interrupt routine
	;;; (this skips all of the signal handler routines that are part of me)
    4 ->> cstacklen -> p_pos;

	;;; this is the only surefire way to calculate the callstack length
	while caller(cstacklen) do cstacklen fi_+1 -> cstacklen endwhile;

	false ->> child -> do_child;

    while (caller(p_pos) ->> p) do
		;;; we only call profiler_include once for each procedure on the
		;;; callstack. We cache this information in -do_p-, which gets
		;;; assigned to -do_child- at the end of each iteration.

		profiler_include(p) -> do_p;

		if do_p then
			;;; find the absolute position of p on the callstack
			cstacklen fi_- p_pos -> p_index;
			fast_lmember(p, met) -> met_p;

			;;; a special case: we don't want to treet things that
			;;; dlocal this identifier (ie. the profiler command) as part of
			;;; the profile.
			not(isdlocal(ident profiler_counters, p)) -> do_p;

			fast_for prop in profiler_counters do
				;;; test if we are beyond starting point in the callstack
				fast_subscrv(PF_CSTACKLEN, prop) -> start_index;
				nextif(p_index fi_< start_index);

				;;; update present table
				if do_p and not(met_p) and (fast_subscrv(PF_PRESENT, prop)
									->> table) then
					table(p) fi_+1 -> table(p);
				endif;
		
				;;; update active table
				if do_p and not(done_active) and (fast_subscrv(PF_ACTIVE, prop)
									->> table) then
					table(p) fi_+1 -> table(p);
				endif;

				if fast_subscrv(PF_TREE, prop) ->> node then
					;;; calculate whether this is a tree root or a tree node
					lvars nodename = (p_index == start_index and "root" or p);
					node(nodename) -> table;

					;;; we save ourselves the expense of creating a table
					;;; for every procedure that appears at the start of
					;;; the callstack. Instead, we only make a table
					;;; if a procedure appears as a parent of something
					;;; on the callstack. When a new procedure appear
					;;; at the start of a callstack, we use an integer
					;;; entry in the -node- table to record how long it
					;;; stays there.
					if child and not(table.isproperty) then
						;;; this is a new parent node. Use the existing
						;;; value as the pdprops (ie. frequency) of the new
						;;; node
						table,
						newproperty([],4,0,"perm") ->> table -> node(nodename);
						-> pdprops(table);
					endif;

					if do_child then
						table(child) fi_+1 -> table(child)
					elseif child then
						table("other") fi_+1 -> table("other")
					endif;

					if table.isinteger then
						;;; this is a leaf
						node(nodename) fi_+1 -> node(nodename);
					else
						;;; this is a joint
						pdprops(table) fi_+1 -> pdprops(table);
					endif;
				endif;
			endfor;
			unless met_p then conspair(p, met) -> met endunless;
			true -> done_active;
		endif;

		;;; if this is the first iteration, we always record the
		;;; procedure
		if do_p or not(child) then
			p -> child; do_p -> do_child;
		endif;

		;;; move to the next item on the call stack
		p_pos fi_+1 -> p_pos;
	endwhile;
    sys_grbg_list(met);

	;;; adjust the profiler tables to reflect that we have done this interrupt
	systime() - time -> time;
    fast_for prop in profiler_counters do
		;;; remove time to do these statistics from the total time
        fast_subscrv(PF_TIME, prop) fi_+ time -> fast_subscrv(PF_TIME, prop);
		;;; increment the sample count of each profile
        fast_subscrv(PF_FREQ, prop) fi_+ 1 -> fast_subscrv(PF_FREQ, prop);
    endfor;

	;;; reset the timer (2:1 = the virtual timer)
    profiler_interval -> sys_timer(profiler_interrupt, 2:1);
enddefine;

/* Procedures to start and end profiling */


define lconstant Start_profiling(name, display_attribs, do_all);
    lvars name, display_attribs, do_all, name, prop, n,
			present = false, activ = false, tree = false, tree_nodes = false;

	if display_attribs then
		lmember("tree", display_attribs) -> tree;
		lmember("present", display_attribs) -> present;
		lmember("active", display_attribs) -> activ;
	else
		true -> tree; ;;; default display style is a tree
	endif;

	if tree then
		newproperty([], 32, 0, "perm") -> tree; ;;; nodes of the tree
	endif;
	if present then
		;;; present profile information
		newproperty([], 32, 0, "perm") -> present;
	endif;
	if activ then
		;;; present profile information
		newproperty([], 32, 0, "perm") -> activ;
	endif;

	unless do_all then
		1 -> n;
		while caller(n) do n fi_+1 -> n endwhile;
		n -1 -> n;
	else
		1 -> n;
	endunless;

    {% name, 0, systime(), present, activ, tree, n %} -> prop;
    conspair(prop, profiler_counters) -> profiler_counters;
enddefine;

define lconstant End_profiling();
    lvars prop;
    destpair(profiler_counters) -> profiler_counters -> prop;
    systime() - subscrv(PF_TIME, prop) -> subscrv(PF_TIME, prop);
	if subscrv(PF_PRESENT, prop) then
		subscrv(PF_FREQ, prop) -> pdprops(subscrv(PF_PRESENT, prop));
	endif;
	if subscrv(PF_ACTIVE, prop) then
		subscrv(PF_FREQ, prop) -> pdprops(subscrv(PF_ACTIVE, prop));
	endif;
	prop;
enddefine;

define lconstant Cancel_profiler_timer();
    false -> sys_timer(profiler_interrupt, 1);
enddefine;

/* Procedural interface */

define global profiler_start(name, display_attribs);
    lvars name, display_attribs;
	if display_attribs then
		Check_display_attribs(display_attribs) -> display_attribs;
	endif;
    Cancel_profiler_timer();
    Start_profiling(name, display_attribs, true);
    profiler_interrupt();
enddefine;

define global profiler_end();
    Cancel_profiler_timer();
    End_profiling();
    profiler_interrupt();
enddefine;

define global profiler_apply(name, display_attribs, pdr);
    lvars name, procedure pdr, display_attribs;
    dlocal profiler_counters;
	if display_attribs then
		Check_display_attribs(display_attribs) -> display_attribs;
	endif;
    Cancel_profiler_timer();
    Start_profiling(name, display_attribs, false);
    profiler_interrupt();
    pdr();
    profiler_end();
enddefine;

/* VM interface */

lconstant Special_pdprops = 'top-level-profiler-temp-pdr';

define global sysPROFILER(name, display_attribs);
	lvars name, display_attribs;
    if pop_vm_compiling_list == [] then
        sysPROCEDURE(Special_pdprops, 0);
    endif;
	if display_attribs then
		Check_display_attribs(display_attribs) -> display_attribs;
	endif;
	sysunprotect("profiler_counters");
	sysLOCAL("profiler_counters");
    sysCALLQ(Cancel_profiler_timer);
	sysPUSHQ(name);
	sysPUSHQ(display_attribs);
	sysPUSHQ(false);
    sysCALLQ(Start_profiling);
    sysCALL("profiler_interrupt");
	sysunprotect("profiler_counters");
enddefine;

define global sysENDPROFILER();
    sysCALLQ(Cancel_profiler_timer);
    sysCALLQ(End_profiling);
    sysCALL("profiler_interrupt");
    if length(pop_vm_compiling_list) == 1
    and pdprops(hd(pop_vm_compiling_list)) == Special_pdprops then
        sysENDPROCEDURE();
        sysCALLQ()
    endif
enddefine;

/* Pop-11 syntax */

global constant syntax endprofiler;

"profiler" :: vedopeners -> vedopeners;
"endprofiler" :: vedclosers -> vedclosers;

define global syntax profiler;
	lvars name = false, display_attribs = false, item;
	nextreaditem() -> item;
	if item == "[" then
		readitem()->;
		pop11_exec_compile(nonsyntax [, false) -> display_attribs;
	elseif islist(item) then
		readitem() -> display_attribs;
	endif;
	unless pop11_try_nextreaditem(";") then
		readitem() -> name;
		pop11_need_nextreaditem(";")->;
	endunless;
    sysPROFILER(name, display_attribs);
    pop11_comp_stmnt_seq_to("endprofiler") ->;
    sysENDPROFILER();
enddefine;


;;; procedure for displaying a profile using -showtree-
;;; profiler_display(DATA);
;;; profiler_display(DATA, OPTIONS);


define global profiler_display(data);
	lvars data, attribs, met = [], name, p, nodes,
			display_attribs = false,
			show_self = false, show_other = true, show_ratios = false,
			root = false, detail_cutoff = 2, depth = 1, max_depth = false,
			show_cumulative = false, activedata;
	dlocal profiler_counters, profiler_include, profiler_exclude;

	define lconstant Parse_options(list);
		lvars list, name, item;
		dlocal proglist_state = proglist_new_state(list),  poplastitem;
		lconstant macro READLITERAL = [
			pop11_try_nextreaditem("=")->;
			readitem() -> item;
		];
		lconstant macro READVAL = [
			READLITERAL;
			if item.isword then valof(item) -> item; endif;
		];
		until proglist == [] or (readitem() ->>name) == termin do
			if name == "show_self" then
				READVAL; item -> show_self;
			elseif name == "show_other" then
				READVAL; item -> show_other;
			elseif name == "show_ratios" then
				READVAL; item -> show_ratios;
			elseif name == "show_cumulative" then
				READVAL; item -> show_cumulative;
			elseif name == "cutoff" then
				READLITERAL; fi_check(item, 0, 100) -> detail_cutoff;
			elseif name == "profiler_exclude" then
				READLITERAL;
				unless item.islist then
					mishap(item,1,'LIST NEEDED');
				endunless;
				item -> profiler_exclude;
			elseif name == "include" then
				READVAL;
				unless item.isprocedure then
					mishap(item,1,'PROCEDURE NEEDED');
				endunless;
				item -> profiler_include;
			elseif name == "display" then
				READLITERAL;
				Check_display_attribs(item) -> display_attribs;
			elseif name == "root" then
				READVAL;
				unless item.isprocedure and data(PF_TREE) and
									isproperty(data(PF_TREE)(item)) then
					mishap(item,1,'NO SUCH ROOT NODE');
				endunless;
				item -> root;
			elseif name == "depth" then
				READLITERAL;
				if item and (not(item.isinteger) or item <= 0) then
					mishap(item,1,'POSITIVE INTEGER or -false- NEEDED');
				endif;
				item -> max_depth;
			elseif name == "," then
			else
				mishap(name,1, 'UNKNOWN PROFILER_DISPLAY OPTION');
			endif;
		enduntil;
	enddefine;

	if data.islist then
		data -> (data, p); Parse_options(p);
	endif;

	unless data.isvector and datalength(data) == PF_NPROPS then
		mishap(data,1,'PROFILER OUTPUT NEEDED');
	endunless;

	define lconstant Make_name(proc, score, div_factor, activedata, cum);
		lvars proc, score, div_factor, name, activedata, cum;
		dlocal pop_pr_places;
		if proc.isword then
			proc -> name;
		else
			profiler_include(proc) -> name;
			if name then
				if pdprops(proc) ->> name then
					if name.ispair then name.hd -> name endif;
				elseif SYS_PROC_NAME(proc) ->> name then
					'(' sys_>< name sys_>< ')' -> name;
				else
					sprintf('<%x>', [^proc]) -> name;
				endif;
			endif;
		endif;
        if name then
			if show_ratios then
				0 -> pop_pr_places;
				sprintf(div_factor, score, name, '%p %P/%P');
        	else
				2 -> pop_pr_places;
				sprintf(score * 100.0 / div_factor, name, '%p %P%%');
			endif;
			if activedata and activedata(proc) ->> score then
				pdprops(activedata) -> div_factor;
				if show_ratios then
					0 -> pop_pr_places;
					sys_>< sprintf(div_factor, score, ' a=%P/%P%')
				else
					2 -> pop_pr_places;
					sys_>< sprintf(score * 100.0 / div_factor, ' a=%P%%');
				endif;
			endif;
			if show_cumulative and cum then
				2 -> pop_pr_places;
				sys_>< sprintf(cum * 1.0, ' c=%P%%');
			endif;
		else
			false
		endif;
	enddefine;

	define lconstant Make_tree(prop, cum);
		lvars prop, div_factor, list, item, name, proc, score, moredata,
				add_to_other = 0, total_score = 0, cum, itemcum;

		;;; limit the tree to a certain depth
		returnif(max_depth and depth fi_> max_depth);
		depth fi_+1 -> depth;

		syssort([% prop.explode %], procedure(i1, i2); lvars i1, i2;
			;;; priorities "other" last, and others in order of their size
		   	i1.hd /== "other" and i1.tl.hd > i2.tl.hd
		endprocedure) -> list;

		pdprops(prop) -> div_factor;

		for item in list do
			item.hd -> proc;
			item.tl.hd -> score;
			score fi_+ total_score -> total_score;
			nextif(proc == "other");
			;;; things less than detail_cutoff percent get amalgamated with
			;;; "other", and their trees are not explored.
			(score / div_factor) * cum -> itemcum;
			if (score * 100) div div_factor < detail_cutoff or
			itemcum < detail_cutoff then
				score fi_+ add_to_other -> add_to_other;
				nextloop;
			endif;
			Make_name(proc, score, div_factor, activedata, itemcum) -> name;
			nodes(proc) -> moredata;
			if name and moredata.isproperty and not(fast_lmember(proc, met))
					and (length(moredata) > 1 or moredata("other") == 0) then
				conspair(proc, met) -> met;
				;;; there is more tree to show
				[%name, Make_tree(moredata, itemcum)%]
			elseif name then
				name
			else
				score fi_+ add_to_other -> add_to_other;
			endif;
		endfor;

		;;; next we display the "self" node
		div_factor - total_score -> score;
		if show_self and (score * 100) div div_factor >= detail_cutoff then
			Make_name("self", score, div_factor, false, cum);
		endif;

		;;; "other" always appears at the end of the list
		if show_other and ((prop("other") ->> score) /== 0
							or add_to_other /== 0) then
			score fi_+ add_to_other -> score;
			(score / div_factor) * cum -> itemcum;
			Make_name("other", score, div_factor, false, itemcum);
		endif;
	enddefine;

	define lconstant Make_linear(prop);
		lvars prop, div_factor, list, name;
		syssort([% prop.explode %], procedure(i1, i2); lvars i1, i2;
		   	i1.tl.hd > i2.tl.hd
		endprocedure) -> list;
		pdprops(prop) -> div_factor;
		define lconstant recurse(list);
			lvars list, item;
			if list /== [] then
				list.hd -> item;
				if (item.tl.hd * 100) div div_factor < detail_cutoff or
				not(Make_name(item.hd, item.tl.hd, div_factor,false,false)
						->>name) then
					;;; not to be included
					recurse(list.tl);
				else
					[% name, recurse(list.tl) %];
				endif;
			endif;
		enddefine;
		recurse(list);
	enddefine;

	unless subscrv(PF_USERNAME, data) ->> name then
		'PROFILE' -> name;
	endunless;

	sprintf(name sys_>< ': %P seconds, %P interrupts\n', [%
				subscrv(PF_TIME, data) / 100.0,
				subscrv(PF_FREQ, data)
		%]) -> name;

	[%name,
    	if (not(display_attribs) or lmember("present", display_attribs)) and
					subscrv(PF_PRESENT, data) ->> p then
			[%'PRESENT-PROFILE:', Make_linear(p)%]
		endif;
    	if (not(display_attribs) or lmember("active", display_attribs)) and
    				subscrv(PF_ACTIVE, data) ->> activedata then
			[%'ACTIVE-PROFILE:', Make_linear(activedata)%]
		endif;
    	if (not(display_attribs) or lmember("tree", display_attribs)) and
					subscrv(PF_TREE, data) ->> p then
			p -> nodes;
			[%'TREE-PROFILE:', Make_tree(p(root or "root"), 100)%]
		endif;
	%].showtree;
enddefine;


define lconstant Profile_command(type);
	lvars action = [], type;
	dlocal popnewline = true;

	;;; read in command
	unless poplastchar == `\n` or poplastchar == `;`
	or null([%until dup(readitem()) == newline do enduntil ->; %] ->> action)
	then
		popval([procedure;  ^^action endprocedure]) -> action;
	endunless;

	unless isprocedure(action) then
		mishap(0, 'NO COMMAND GIVEN TO BE PROFILED')
	endunless;
	chain(false, type, action, profiler_apply)
enddefine;

define global macro p_profile;
	Profile_command([present]).profiler_display
enddefine;
define global macro a_profile;
	Profile_command([active]).profiler_display
enddefine;
define global macro t_profile;
	Profile_command([tree]).profiler_display
enddefine;

applist([
	sysPROFILER sysENDPROFILER
	profiler endprofiler
	profiler_start
	profiler_end
	profiler_apply
	profiler_counters
	profiler_interrupt
	p_profile
	a_profile
	t_profile
  ], sysprotect);

endsection;
