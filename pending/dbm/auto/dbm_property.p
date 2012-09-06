/* --- Copyright Integral Solutions Ltd 1993. All rights reserved. ----------
 > File:            $poplocal/local/dbm/auto/dbm_property.p
 > Purpose:         Interface to the GNU GDBM library
 > Author:          Jonathan Meyer, Nov 10 1992
 > Documentation:   REF *DBM
 */
section;
compile_mode :pop11 +strict;

uses popdbm;
uses dbm_core;
uses datainout;

;;; uses facilities found in datainout to convert arbritrary item into a string
define lconstant Encode_to_string(arg);
	lvars arg;
	consstring( sys_write_data(identfn, arg, 2:1) )
enddefine;

/*
For speed, we make a user-device which reads from a string rather than
using stringin. This lets datainout get multiple characters at a time.
*/

lvars dev_bytes, dev_bsub, dev_num_bytes_available;

define lconstant Read(dev, bsub, bytes, nbytes) -> nbytes;
	lvars i, bsub, bytes, nbytes, dev;

	returnif((fi_min(nbytes, dev_num_bytes_available) ->> nbytes) == 0);

	if bytes.isstring then
		move_bytes(dev_bsub, dev_bytes, bsub, bytes, nbytes);
		dev_bsub fi_+ nbytes -> dev_bsub;
	else
		if nbytes fi_< 0 then
			mishap(nbytes, 1, 'INTEGER >= 0 NEEDED');
		endif;
		fast_repeat nbytes times
			fast_subscrs(dev_bsub, dev_bytes) -> fast_subscrs(bsub, bytes);
			bsub fi_+ 1 -> bsub;
			dev_bsub fi_+ 1 -> dev_bsub;
		endfast_repeat;
	endif;
	dev_num_bytes_available fi_- nbytes -> dev_num_bytes_available;
enddefine;

;;; turn Read into a device
lconstant Read_dev =
	consdevice('str_dev', 'str_dev', undef, 0,
		{% {% Read, erase <> identfn(%0%), erase %}, false, false, false %});

;;; performs reverse of the above (takes an encoded string, returns pop item)
define lconstant Decode_from_string(arg);
	lvars arg;

	dlocal
		dev_bytes = arg,
		dev_bsub = 1,
		dev_num_bytes_available = datalength(arg);
	
	unless sys_read_data(Read_dev, 0) then
		mishap(0, 'CANNOT DECODE DATA STRING');
	endunless;
enddefine;

;;; wrapper on dbm_value which encodes/decodes arg/val.
define lconstant Dbm_value(arg, dbmfile, defvalue, active_default) -> val;
	lvars dbmfile, arg, val, defvalue, active_default;
	dbm_value(dbmfile, Encode_to_string(arg)) -> val;
	if val.isstring then
		Decode_from_string(val) -> val;
	else
		if active_default then
			fast_apply(arg, active_default) -> val;
		else
			defvalue -> val;
		endif;
	endif;
enddefine;

;;; wrapper on dbm_value which encodes/decodes arg/val.
define updaterof Dbm_value(val, arg, dbmfile, defvalue, active_default);
	lvars dbmfile, arg, val, defvalue, active_default;
	if val == defvalue then
		false
	else
		Encode_to_string(val)
	endif -> val;
	val -> dbm_value(dbmfile, Encode_to_string(arg));
enddefine;

;;; procedure for constructing a closure on Dbm_value.
define global dbm_property(dbmfile, defvalue, active_default) -> p;
	lvars dbmfile, p, defvalue, active_default;
	unless isdbm(dbmfile) == true then
		mishap(dbmfile, 1, '(OPEN) DBM FILE NEEDED');
	endunless;
	Dbm_value(%dbmfile, defvalue, false%) -> p;
	if active_default then
		unless active_default.isprocedure then
			mishap(active_default, 1, 'PROCEDURE NEEDED');
		endunless;
		active_default(%p%) -> frozval(3, p);
	endif;
	dbmfile -> pdprops(p);
	;;; if the file was not opened for write, cancel the updater
	unless dbm_writeable(dbmfile) then false -> updater(p); endunless;
enddefine;


;;; recogniser for DBM properties.
define global isdbmproperty(i);
	lvars i;
	i.isclosure and pdpart(i) == Dbm_value and frozval(1, i);
enddefine;

;;; returns -true- if -args- is in the property.
define is_dbm_property_arg(dbm, arg) -> val; lvars dbm, arg, val;
	lvars dbmfile = isdbmproperty(dbm);
	unless dbmfile then
		mishap(dbm, 1, 'DBM PROPERTY NEEDED');
	endunless;
	dbm_value(dbmfile, Encode_to_string(arg), false) -> val;
enddefine;

;;; applies procedure to each key/value pair in a DBM database.
define global appdbmproperty(d, p);
	lvars d, dbmfile, p;
	unless d.isdbmproperty ->> dbmfile then
		mishap(d, 1, 'DBM PROPERTY NEEDED');
	endunless;
	unless p.isprocedure then
		mishap(p, 1, 'PROCEDURE NEEDED');
	endunless;
	fast_appdbmkeys(dbmfile,
		procedure(key); lvars key;
			lvars val = dbm_value(dbmfile, key);
			if key.isstring and val.isstring then
				fast_apply(
					Decode_from_string(key), Decode_from_string(val), p);
			endif;
		endprocedure);
enddefine;

endsection;


/*
JM, 18/2/94
	Changed Encode_to_string so that it uses a flags argument of 2:1.
	Added the Read_dev user device to speed up reads.
JM, 18/5/93
	--- Added test for dbm_writeable in dbm_property
JM, 17/5/93
	--- Added is_dbm_property_arg
*/
