;;; Summary: load a library and show identifiers loaded

/*
VED_VLIB                                          Jonathan Meyer Nov 1992

		<ENTER> vlib <libname>    - Verbose version of LIB.
	or just:
		vlib <libname> ;

This command is just like <ENTER> lib except that it lists all of the
new top level identifiers that have been created by loading the library,
in a form which is ready for turning into a REF file. For example:

	<ENTER> vlib last
produces (if last has not yet been loaded):

last                                             [global vars procedure]

In addition, VLIB shows all of the variables that have been changed by
loading the library.

This information is useful for:

 o	documenting new libraries.

 o	verifying that a library defines the identifiers it says it does.

 o	spotting bugs in library identifier specifications.

 o	checking for clashes between two libraries.

*/
section;
compile_mode :pop11 +strict;

lconstant prop = newproperty([], 64, false, "perm");

define lconstant saveids;
	appdic(procedure(w);
		lvars w, id, val;
		if sys_current_ident(w) ->> id then
			conspair(id, fast_idval(id)) -> prop(w);
		endif;
	endprocedure);
enddefine;

lconstant ignore = [%
		;;; these things are almost certain to have changed
		ident vedmessage,
		ident vedscreenline,
		ident vedscreencolumn,
		ident popgctime,
		ident popmemused,
	%];

define lconstant showids(name);
	lvars name, changed = [], new = [];

	appdic(procedure(w);
		lvars w, id, oid;
		if (sys_current_ident(w) ->> id) then
			unless (prop(w) ->> oid) then
				conspair(w, id) :: new -> new;
			elseunless fast_front(oid) == id and
						fast_back(oid) == fast_idval(id) then
				unless fast_lmember(id, ignore) then
					conspair(w, id) :: changed -> changed;
				endunless;
			endunless;
		endif;
	endprocedure);

	define lconstant sortp(a,b);
		lvars a,b;
		alphabefore(front(a), front(b));
	enddefine;

	syssort(new, sortp) -> new;
	syssort(changed, sortp) -> changed;

	printf(';;; LIB %p : \n', [^name]);

	applist(new, procedure(pair);
		lvars pair, w, id, idp;
		destpair(pair) -> (w, id);
		full_identprops(id) -> idp;
		if isglobal(id) then "global" :: idp -> idp; endif;
		idp sys_>< nullstring -> idp;
		pr(w);
		repeat 72 - datalength(idp) - datalength(w) times pr('\s') endrepeat;
		pr(idp);
		pr('\n');
	endprocedure);

	applist(changed, procedure(pair);
		lvars pair, w, id, idp;
		destpair(pair) -> (w, id);
		full_identprops(id) -> idp;
		if isglobal(id) then "global" :: idp -> idp; endif;
		printf(';;; CHANGED %p %p\n', [^w ^idp]);
	endprocedure);

	clearproperty(prop);
enddefine;

define lconstant liberror(item);
	lvars item;
	unless isstring(item) then -> item; endunless;
	vederror(item);
enddefine;

lvars vlibtmpfile = false;
define global ved_vlib();
	dlocal prmishap = liberror;
	vedputmessage('LOADING LIB ' sys_>< vedargument);
	saveids();
	loadlib(vedargument);
	unless vlibtmpfile then
		systmpfile(false, 'vlib', nullstring) -> vlibtmpfile;
	endunless;
	procedure;
		dlocal ved_chario_file = vlibtmpfile;
		showids(vedargument);
	endprocedure();
enddefine;

define global syntax vlib;
	lvars file;
	dlocal popnewline = true;
	rdstringto([; ^termin ^newline]) -> file;
	sysPUSHQ(file);
	sysCALL("libwarning");
	sysCALLQ(saveids);
	sysPUSHQ(file);
	sysCALL("loadlib");
	sysPUSHQ(file);
	sysCALLQ(showids);
	";" :: proglist -> proglist
enddefine;

endsection;
