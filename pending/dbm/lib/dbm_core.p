/* --- Copyright Integral Solutions Ltd 1993. All rights reserved. --------
 > File:            $poplocal/local/dbm/lib/dbm_core.p
 > Purpose:         Interface to the GNU GDBM library
 > Author:          Jonathan Meyer, Nov 10 1992
 > Documentation:   REF *DBM, MAN * DBM
 */
section;
compile_mode :pop11 +strict;

include sysdefs.ph;

;;; ---- DBM INTERFACE ---------------------------------------------------

l_typespec
	dbm_datum {
		dptr: exptr,
		dsize: int,
	},
	datum :dbm_datum,
  ;

lvars
	datums = pdtolist(procedure; EXPTRINITSTR(:dbm_datum); endprocedure)
  ;

lvars
        extn = (DEF HPUX and '.sl') or ((DEF SUN or DEF IRIS) and DEF SYSTEM_V and '.so') or '.a';

lconstant DBMFILE = popdbm dir_>< 'bin/libgdbm_'
			sys_>< sys_machine_type.hd sys_>< '_'
			sys_>< sys_processor_type.hd
			sys_>< extn;

exload 'dbm_core' [^DBMFILE]
lvars
	free(1),
	pop_mishap,
	gdbm_open(5):exptr,
	gdbm_close(1),
	gdbm_errno:int,
	gdbm_reorganize(1):int,
	pop_gdbm_firstkey(2):int,
	pop_gdbm_nextkey(2):int,
	pop_gdbm_fetch(4):int,
	pop_gdbm_store(5):int,
	pop_gdbm_delete(3):int,
endexload;

lconstant gdbm_errors = {
		'gdbm - CANNOT PERFORM MALLOC'
		'gdbm - BLOCK SIZE ERROR'
		'gdbm - FILE OPEN ERROR'
		'gdbm - FILE WRITE ERROR'
		'gdbm - FILE SEEK ERROR'
		'gdbm - FILE READ ERROR'
		'gdbm - BAD MAGIC NUMBER'
		'gdbm - EMPTY DATABASE'
		'gdbm - CANT BE READER'
		'gdbm - CANT BE WRITER'
		'gdbm - READER CANT DELETE'
		'gdbm - READER CANT STORE'
		'gdbm - READER CANT REORGANIZE'
		'gdbm - UNKNOWN UPDATE'
		'gdbm - ITEM NOT FOUND'
		'gdbm - REORGANIZE FAILED'
		'gdbm - CANNOT REPLACE'
		'gdbm - ILLEGAL DATA'
};

;;; -----------------------------------------------------------------------

;;; tests for (open) DBM databases.
define global isdbm(item);
	lvars item, props;
	item.isexternal_ptr_class
	and (external_ptr_props(item) ->> props).ispair
	and fast_back(props) == "DBM"
	and (is_null_external_ptr(item) and 0 or true);
enddefine;



;;; closes a DBM database.
define global dbm_close(dbmfile);
	lvars dbmfile, ok;
	unless (isdbm(dbmfile) ->> ok) then
		mishap(dbmfile, 1, 'DBM DATABASE NEEDED');
	endunless;
	;;; only close it if it has not already been closed.
	if ok == true then
		exacc gdbm_close(dbmfile);
		;;; set it to NULL
		0 -> exacc ^int dbmfile;
	endif;
enddefine;

define global vars dbm_garbage;
	fast_appproperty(sys_destroy_action, procedure(item); lvars item;
		if item.isdbm == true then
			dbm_close(item);
		endif;
	endprocedure);
enddefine;

;;; opens a DBM database.
define lconstant Dbm_open(file, write, is_retry) -> dbmfile;
	lvars file, write, is_retry, dbmfile;
	exacc gdbm_open(sysfileok(file), 0, write and 2 or 0, pop_file_mode,
		pop_mishap) -> dbmfile;
	if is_null_external_ptr(dbmfile) then
		exacc gdbm_errno -> dbmfile;
		if dbmfile == 3 and not(is_retry) then
			dbm_garbage();
			return(Dbm_open(file, write, true) -> dbmfile);
		elseif dbmfile > 0 and dbmfile <= datalength(gdbm_errors) then
			warning(file, 1, gdbm_errors(dbmfile));
		endif;
		false -> dbmfile;
	endif;
enddefine;

define global dbm_open(file, write) -> dbmfile;
	lvars file, write, dbmfile;
	check_string(file);
	Dbm_open(file, write, false) -> dbmfile;
	if dbmfile then
		conspair(conspair(file, write and true), "DBM")
			-> external_ptr_props(dbmfile);
		dbm_close -> sys_destroy_action(dbmfile);
	endif;
enddefine;

define global dbm_reopen(dbm) -> dbm; lvars dbm;
	if dbm.isdbm == 0 then ;;; its a closed dbm file
		lvars dbmfile = Dbm_open(explode(external_ptr_props(dbm).front),false);
		if dbmfile then
			exacc ^ulong dbmfile -> exacc ^ulong dbm;
		else
			mishap(dbm,1, 'CANNOT REOPEN DBM FILE (file deleted?)');
		endif;
	endif;
enddefine;

;;; checks that dbmfile is a DBM database.
define lconstant Checkr_dbm(dbmfile) -> dbmfile; lvars dbmfile;
	lvars d = isdbm(dbmfile);
	if d == 0 then
		dbm_reopen(dbmfile);
		isdbm(dbmfile) -> d;
	endif;
	unless d == true then
		mishap(dbmfile, 1, '(OPEN) DBM DATABASE NEEDED');
	endunless;
enddefine;

;;; returns -true- if dbm_open was passed -true- for -write-
define global dbm_writeable(dbmfile); lvars dbmfile;
	external_ptr_props(Checkr_dbm(dbmfile)).fast_front.fast_back;
enddefine;

;;; returns the contents of datum as a string
define lconstant Get_datum_string(datum, deref, ptr) -> str;
	lvars datum, str, size, ptr, i, deref;
	;;; can't use exacc_ntstring because it may not be null terminated.
	if deref then
		exacc [fast] datum.dsize -> size;
		inits(size) -> str;
		fast_for i from 1 to size do
			exacc [fast] :byte[] ptr[i] -> fast_subscrs(i, str);
		endfast_for;
	else
		false -> str;
	endif;
enddefine;

;;; returns an entry keyed on arg in a DBM database.
define global dbm_value(dbmfile, arg) -> val;
	lvars datum, dbmfile, arg, val, deref = true, ptr;
	if arg.isboolean then (dbmfile, arg) -> (dbmfile, arg, deref); endif;
	Checkr_dbm(dbmfile)->;
	check_string(arg);
	lvars orig_datums = datums;
	dest(datums) -> datums -> datum;
	if exacc [fast] pop_gdbm_fetch(dbmfile, arg, datalength(arg), datum) == 0
	then
		lvars ptr = exacc [fast] datum.dptr;
		Get_datum_string(datum, deref, ptr) or true -> val;
		exacc [fast] free(ptr);
	else
		false -> val;
	endif;
	orig_datums -> datums;
enddefine;

;;; set an entry keyed on arg to val in a DBM database.
define updaterof dbm_value(val, dbmfile, arg);
	lvars dbmfile, arg, val, size = false;

	if val.isinteger then
		val -> (val, size);
		check_string(val);
		fi_check(size, 0, datalength(val)) -> size;
	elseif val then
		check_string(val);
	endif;

	check_string(arg);

	Checkr_dbm(dbmfile)->;

	if val then
		;;; setting an entry
		unless exacc [fast] pop_gdbm_store(dbmfile, arg, datalength(arg),
				val, size or datalength(val)) == 0 then
			mishap(dbmfile, 1,
					'CANNOT WRITE DATA TO DBM FILE (READ ONLY?)');
		endunless;
	else
		;;; deleting an entry
		unless exacc [fast] pop_gdbm_delete(dbmfile, arg, datalength(arg))
									== 0 then
				mishap(dbmfile, 1,
					'CANNOT DELETE DATA FROM DBM FILE (READ ONLY?)');
		endunless;
	endif;
enddefine;

;;; apply a procedure to each arg in a DBM database. This is called 'fast_'
;;; because its not clear what happens if p tries to alter the contents
;;; of the database.

define global fast_appdbmkeys(dbmfile, p);
	lvars dbmfile, p, arg, status, datum;

	unless p.isprocedure then
		mishap(p, 1, 'PROCEDURE NEEDED');
	endunless;

	Checkr_dbm(dbmfile) ->;

	lvars orig_datums = datums;
    dest(datums) -> datums -> datum;
	exacc [fast] pop_gdbm_firstkey(dbmfile, datum) -> status;
	while status == 0 do
		lvars ptr = exacc [fast] datum.dptr;
		Get_datum_string(datum, true, ptr) -> arg;
		fast_apply(arg, p);
		exacc [fast] pop_gdbm_nextkey(dbmfile, datum) -> status;
		exacc [fast] free(ptr);
	endwhile;
	orig_datums -> datums;
enddefine;

define global dbm_compact(dbmfile) -> ok; lvars dbmfile, ok;
	(exacc gdbm_reorganize(Checkr_dbm(dbmfile))) == 0 -> ok;
enddefine;

vars dbm_core = true;

endsection;

/*
--- Julian Clinton, Oct 19 1994
	Changes for IRIX 5 (uses '.so' extn for IRIX).
JM, 18/2/94
	if dbm_open fails because there are no file handles, it closes any
	open dbms and tries again. dbm_value etc. now reopen a dbm even if it
	has been closed.
JM, 4/8/93
	--- added dbm_reopen
JM, 24/6/93
	--- added gdbm_errno messages
JM, 16/6/93
	--- fixed so that free is called on datum ptrs after dbm_nextkey
JM, 15/6/93
	--- rewrote to be completely reentrant
JM, 25/5/93
	--- changed to use gdbm instead of ndbm
	--- simplified fast_appdbmkeys
JM, 18/5/93
	--- Added dbm_writeable
*/
