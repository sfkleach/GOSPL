/*--- Copyright Integral Solutions Ltd 1993. All rights reserved. ----------
 > File:            $poplocal/local/lib/vedpsprint.p
 > Purpose:         PostScript Printing
 > Author:          Jonathan Meyer, Apr 1 1993 (see revisions)
 > Documentation:	REF * PSPRINT
 > Related Files:
 */
compile_mode :pop11 +strict;

section;

uses postscript_line_consumer;

/* ==== VED_PRINT INTERFACE ============================================ */

;;; writes a range of a ved buffer to a file, converting it to PostScript
define lconstant PS_write_range(device, lo, hi);
	lvars device, lo, hi, file, descr;
	
	device_open_name(device) -> file;	

	;;; write all the lines from lo to hi
	if lo <= vedline and vedline <= hi then vedtrimline() endif;
	min(vedusedsize(vedbuffer), hi) -> hi;

	if hi == 0 then
		;;; buffer is empty
		if file then
			file sys_>< '(EMPTY)' -> descr;
			vedputmessage(descr)
		endif;
		return;
	else
		if lo > hi then
			mishap(lo, hi, 2, 'IMPOSSIBLE RANGE TO WRITE')
		endif;
		if file then
			file sys_>< ', ' sys_>< (hi - lo + 1) sys_>< ' LINES' -> descr;
			vedputmessage('WRITING ' sys_>< descr)
		endif
	endif;

	lvars procedure consume = postscript_line_consumer(device);

	while lo <= hi do
		;;; write next line
		consume(subscrv(lo, vedbuffer));
		lo + 1 -> lo
	endwhile;
	
	consume(termin); ;;; this doesn't close the device

	if file then
		vedputmessage(descr sys_>< ' WRITTEN')
	endif;
enddefine;

;;; writes contents of file to a device, converting it to PostScript
define lconstant PS_write_file(device, file);
	lvars device, file,
		procedure rep = vedfile_line_repeater(file),
		procedure consume = postscript_line_consumer(device),
		procedure filter = rep <> dup <> consume,
	  ;
	until filter() == termin do enduntil;
enddefine;


lvars
	command,	;;; print command to use: lpr(1) or lp(1)
	using_lpr,	;;; <true> if -command- is lpr
	files,		;;; list of files to print
	printer,	;;; printer to use
	filters,	;;; list of pre-filters
	copies,		;;; number of copies to print
	flags,		;;; other flags to pass
	devtype,    ;;; "ps" or false
;

	;;; choose which print command to use
define lconstant setup();
	returnunless(isundef(command));
	if sys_search_unix_path('lpr', '/usr/ucb') ->> command then
		;;; standard Berkeley LPR
		true -> using_lpr;
	elseif sys_search_unix_path('lp', systranslate('$PATH')) ->> command then
		;;; standard System V LP
		false -> using_lpr;
	elseif sys_search_unix_path('lpr', systranslate('$PATH')) ->> command then
		;;; Hmm ... has LPR, but may not be standard -- e.g. on HP-UX
		true -> using_lpr;
	else
		vederror('print: can\'t find print command (lpr/lp)');
	endif;
enddefine;

	;;; convert ved command flags into corresponding lpr/lp options
define lconstant translate_flags();
	consstring(#|
		if strmember(`m`, flags) then explode('-m ') endif;
		if using_lpr then
			if strmember(`f`, flags) then explode('-h ') endif;
			if strmember(`h`, flags) then explode('-p ') endif;
			if strmember(`l`, flags) then explode('-l ') endif;
		else
			if strmember(`f`, flags) or strmember(`l`, flags) then
				vederror('print: lp(1) doesn\'t support flags -f & -l');
			endif;
			if strmember(`h`, flags) then [^^filters 'pr '] -> filters endif;
			;;; always add '-s' to suppress messages
			explode('-s ');
		endif;
	|#) -> flags;
enddefine;

	;;; construct a shell command to do the printing
define lconstant gen_print_command(file, title);
	lvars file, title;
	consstring(#|
		unless filters == [] then
			lvars filter;
			if file then
				explode('cat '), explode(file), explode(' | ');
				unless title then file -> title endunless;
				false -> file;
			endif;
			for filter in filters do
				explode(filter), explode('| ');
			endfor;
		endunless;
		explode(command), ` `;
		explode(flags);
		if copies > 1 then
			explode(if using_lpr then '-#' else '-n' endif);
			dest_characters(copies), ` `;
		endif;
		unless printer = nullstring then
			explode(if using_lpr then '-P' else '-d' endif);
			explode(printer), ` `;
		endunless;
		if file then
			explode(file);
		elseif title then
			if using_lpr then
				explode('-J '), explode(title);
				explode(' -T '), explode(title);
			else
				explode('-t'), explode(title);
			endif;
		endif;
	|#);
enddefine;

	;;; split -vedargument- into flags, filters and files
define lconstant parseargument();
	lconstant SPECIALS = '-#.$~/:', FLAGS = 'fhlmd';
	lvars item, procedure items = incharitem(stringin(vedargument));

	;;; modify the itemiser to treat SPECIAL characters as alphabetic
	appdata(
		SPECIALS,
		procedure(c);
			lvars c;
			1 -> item_chartype(c, items);
		endprocedure);

	until (items() ->> item) == termin do
		if isinteger(item) then
			item -> copies;
		elseif isstring(item) then
			;;; quoted file name
			[^^files ^item] -> files;
		elseif isword(item) and isstartstring('-', item) then
			;;; parse flags
			lvars i, c, n = 0;
			for i from 2 to datalength(item) do
				subscrw(i, item) -> c;
				if c == `p` then
					if (items() ->> printer) == termin then
						vederror('print: printer name expected after -p flag');
					endif;
				elseif c == `d` then
					if (items() ->> devtype) == termin then
						vederror('print: device type name expected after -d flag');
					endif;
					unless devtype == "ps" then
						vederror('print: ps expected after -d');
					endunless;
				elseif c == `#` then
					;;; ignore
				elseif isnumbercode(c) then
					;;; number of copies
					n * 10 + c - `0` -> n;
				elseif strmember(c, FLAGS) then
					flags <> consstring(c,1) -> flags;
				else
					vederror('print: unrecognized flag - ' <> consstring(c,1));
				endif;
			endfor;
			unless n == 0 then n -> copies endunless;
		elseif item == "(" then
			;;; read a filter
			consstring(#|
				until (items() ->> item) == ")" do
					if item == termin then
						vederror('print: closing ) not found');
					else
						dest_characters(item), ` `;
					endif;
				enduntil;
			|#) -> item;
			[^^filters ^item] -> filters;
		else
			[^^files ^(item sys_>< nullstring)] -> files;
		endif;
	enduntil;
	translate_flags();
enddefine;

	;;; print a range of the current buffer
define lconstant vedprintmr(lo, hi);
	lvars hi, lo;
	dlocal vednotabs = true;	;;; to give correct spacing
	unless hi >= lo then vederror('print: nothing to print') endunless;
	pipeout(
		if devtype == "ps" then
			consref(PS_write_range(% lo, hi %)),
		else
			consref(vedwriterange(% lo, hi %)),
		endif,
		'/bin/sh',
		['sh' '-c' ^(gen_print_command(false, sys_fname_name(vedcurrent)))],
		true);
enddefine;

define lconstant vedprint(marked_range);
	lvars marked_range;
	dlocal
		devtype = false,
		files	= [],
		printer	= systranslate('popprinter') or nullstring,
		filters	= [],
		copies	= 1,
		flags	= nullstring;
	setup();
	parseargument();

	if marked_range == "ps" then
		if files == [] then
			mishap(0, 'PSPRINT - no files specified');
		endif;
		"ps" -> devtype;
		false -> marked_range;
	endif;

	if files == [] then
		vedprintmr(
			if marked_range then
				vedputmessage('printing marked range ...');
				vvedmarklo, vvedmarkhi
			else
				vedputmessage('printing whole file ...');
				1, vvedbuffersize
			endif);
	elseif marked_range then
		vederror('printmr: only works on current file');
	else
		vedputmessage('printing named file(s) ...');
		lvars file;
		for file in files do
			if devtype == "ps" then
				pipeout(
					consref(PS_write_file(% file %)),
					'/bin/sh',
					['sh' '-c' ^(gen_print_command(false, sys_fname_name(file)))],
					true);
			else
				sysobey(gen_print_command(file, false));
			endif;
		endfor;
	endif;
	vedputmessage('print command queued');
enddefine;

define global vars ved_print =
	vedprint(% true %)
enddefine;

define global vars ved_psprint =
	vedprint(% false %)
enddefine;

define global vars vedpsprint;
	dlocal vedargument;

	;;; convert poparglist into a string
	consstring(#| procedure;
		dlocal cucharout = identfn;
		applist(poparglist, spr)
	endprocedure() |#) -> vedargument;
	vedprint("ps");
enddefine;

define global vars ved_psprint();
    dlocal
        devtype = false,
        files   = [],
        printer = systranslate('popprinter') or nullstring,
        filters = [],
        copies  = 1,
        flags   = nullstring;

    setup();
    parseargument();
    "ps" -> devtype;

    vedputmessage('printing whole file ...');
    vedprintmr( 1, vvedbuffersize);
    vedputmessage('print command queued');
enddefine;

endsection;
