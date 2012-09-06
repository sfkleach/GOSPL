/* --- Copyright Integral Solutions Ltd 1993. All rights reserved. -------
 > File:            $poplocal/local/dbm/auto/datainout.p
 > Purpose:         Data repeaters/consumers
 > Author:          Jonathan Meyer, Sept 9 1992
 > Documentation:   REF *DATAINOUT
 > Related Files:   LIB *ARRAYFILE *DATAFILE
 */
section;
compile_mode :pop11 +strict;

uses popprotolib, objectclass;

/* ARCHITECTURE TEST */

;;; we mishap if the architecture does not fit our expectations

lvars
    ;;; these two are only used at compile time to find out about the
    ;;; architecture
    iv = init_fixed(2, intvec_key),
    i = fill_external_ptr(iv, consexternal_ptr()),
  ;

if [% datasize(1.0d0), datasize(initintvec(1)), datasize(initshortvec(1)),
datasize(1<<31) %] /= [3 3 3 4] then
    mishap(0, 'BAD DATASIZE FOR PACKED NUMBERS');
elseif  datasize(1<<31) /== datasize(1<<32)
or fast_subscrintvec(-1, 16:FF000000) /== 2 then
    mishap(0,'BAD DATASIZE FOR BIG INTEGERS');
elseif (pi -> exacc :ddecimal i; iv(1) + iv(2)) /= 2488094483 then
    mishap(0,'BAD IEEE FLOATING POINT DDECIMAL REPRESENTATION');
elseif (1.0 -> exacc :decimal i; iv(1)) /= 1065353216 then
    mishap(0,'BAD IEEE FLOATING POINT DECIMAL REPRESENTATION');
endif;

#_IF not(DEF null_external_ptr) ;;; pre 14.1 poplog
lconstant null_external_ptr = consexternal_ptr();
#_ENDIF

/* Objectclass methods */

/*
*/

define :method instance_dataout(instance);
	/* do nothing */
enddefine;

define :method instance_datain(data, instance) -> instance;
	/* do nothing */
enddefine;

lconstant
    macro (
		/* BIT FIELDS */
        ;;; a 'type' byte consists of 3 bitfields, as follows:
        SIGN_MASK   = 2:10000000,   ;;; the signflag
        SIZE_MASK   = 2:01100000,   ;;; size info
        TYPE_MASK   = 2:00011111,   ;;; the object type

        /* SIZE CODES */
        SIZE0       = 2:00e5,
        SIZE1       = 2:01e5,
        SIZE2       = 2:10e5,
        SIZE4       = 2:11e5,

        /* TYPE CODES */
        INTEGER     = 0,        ;;; number types
        DECIMAL     = 1,
        BIGINTEGER  = 2,
        COMPLEX     = 3,
        RATIO       = 4,
        QUNDEF      = 5,        ;;; unique 'quoted atoms
        QTRUE       = 6,
        QFALSE      = 7,
        QNIL        = 8,
        QNULLSTRING = 9,
        QNULLVECTOR = 10,
        QNULLEXPTR  = 11,
        STRING      = 12,       ;;; builtin vector types
        DSTRING     = 13,
        SHORTVEC    = 14,
        INTVEC      = 15,
        WORD        = 16,
        VECTOR      = 17,
        REF         = 18,       ;;; builtin record types
        PAIR        = 19,
        ARRAY       = 20,
        PROPERTY    = 21,
        UNDEF       = 22,
        URECORD     = 23,       ;;; user defined record class
        UVECTOR     = 24,       ;;; user defined vector class
        PMARKNEXT   = 25,       ;;; next item defines a mark
        PMARKREFER  = 26,       ;;; refer back to a marked item
		PPROCNAME   = 27,       ;;; refer to a procedure by name
		LIST        = 28,       ;;; a simple list of pairs
            ;;; 29-31 are reserved for future use

        /* FIELD SPECIFIER ENCODING */
        SPEC_FULL = 0,
        SPEC_INT = 1,
        SPEC_UINT = 2,
        SPEC_LONG = 3,
        SPEC_ULONG = 4,
        SPEC_SHORT = 5,
        SPEC_USHORT = 6,
        SPEC_SBYTE = 7,
        SPEC_BYTE = 8,
        SPEC_PINT = 9,
        SPEC_DFLOAT = 10,
        SPEC_SFLOAT = 11,
        SPEC_FLOAT = 12,
        SPEC_DDECIMAL = 13,
        SPEC_DECIMAL = 14,
        SPEC_EXPTR = 15,

        ;;; (spec values between 16-31 are unused)
        SPEC_BITFIELD = 2:1e6,
        SPEC_UBITFIELD = 2:1e7,

        ;;; biginteger specifications
        BIGINT_SPEC = "int",
        BIGINT_SIZE = 31,

        ;;; determine byte/bit ordering
        LSB_ORDERING = (1 -> exacc :long i; exacc :byte[] i[4]) /== 1,

        ;;; write flags
        WRITE_ANY               = 2:1e0,
        MARK_NUMBERS            = 2:1e1,
        MARK_PACKED             = 2:1e2,
        MARK_FULL               = 2:1e3,
        MAX_WRITE_FLAG          = 2:1111,

        ;;; read flags
		READ_EOF				= 2:1e0,
        READ_ANY				= 2:1e1,
        MAX_READ_FLAG           = 2:11,

        ;;; size of the default mark vector
        DEFMARKVECSIZE = 32,

		SINGLETON_CLASS = -1,
		OBJECT_CLASS = -2,
    ),

    atomictypes = conslist(#|
        undef,              QUNDEF,
        true,               QTRUE,
        false,              QFALSE,
        nil,                QNIL,
        nullstring,         QNULLSTRING,
        nullvector,         QNULLVECTOR,
        null_external_ptr,  QNULLEXPTR,
    |#),
  ;

#_IF LSB_ORDERING
/* define NORMALIZE as a macro that expands to its argument */
define :inline lconstant NORMALIZE(expr); expr; enddefine;
#_ELSE
/* define NORMALIZE as a macro that expands to an empty expression */
define :inline lconstant NORMALIZE(expr);  enddefine;
#_ENDIF

/* WORKING DATA */

;;; all this data needs to be saved to cope with re-entrant calls
lvars
    workdata = pdtolist(procedure; {%
                    init_fixed(8, string_key),
                    fill_external_ptr(dup(), consexternal_ptr()),
                    newproperty([],32,false,"perm"),
                    initv(DEFMARKVECSIZE) %} endprocedure),
;

/* MISC PROCEDURES */

define lconstant Check_device(dev, type);
    lvars dev, type;
    unless dev.isdevice or dev.isprocedure then
		mishap(dev,1,'OPEN DEVICE NEEDED');
    endunless;
enddefine;

;;; like fast_sysread but works with a character repeater rather than a device
define lconstant Read_using_repeater(rep, bsub, bstruct, n) -> n;
    lvars rep, bsub, bstruct, n, esub, i, c;
    bsub fi_+ n fi_-1 -> esub;
    fast_for i from bsub to esub do
    	returnif((fast_apply(rep) ->> c) == termin)(i - bsub -> n);
        c -> fast_subscrs(i, bstruct);
    endfast_for;
enddefine;

;;; like fast_syswrite but works with character consumer instead of device
define lconstant Write_using_consumer(consume, bsub, bstruct, n);
	lvars procedure consume, bsub, bstruct, n, esub, i;
	bsub fi_+ n fi_-1 -> esub;
	fast_for i from bsub to esub do
		consume(fast_subscrs(i, bstruct));
	endfast_for;
enddefine;

;;; like fast_syswrite but does nothing
define lconstant Write_using_null;
	-> -> -> ->;
enddefine;

;;; digs out the underlying field spec (stripping off converters)
define lconstant Underlying_spec(spec) -> spec;
    lvars spec;
    while spec.isclosure and datalength(spec) == 2 and
                        fast_frozval(2, spec) == true do
        fast_frozval(1, spec) -> spec;
    endwhile;
enddefine;

;;; returns -true- if -data- contains any full fields
define lconstant Has_full_field(data);
    lvars data, spec;
    define lconstant Examine_spec(list);
        lvars list, spec;
        fast_for spec in list do
            returnif(Underlying_spec(spec) == "full")(true);
        endfast_for;
        false;
    enddefine;
    returnif(issimple(data))(false);
    class_field_spec(datakey(data)) -> spec;
    Underlying_spec(spec) == "full" or (spec.islist and Examine_spec(spec))
enddefine;

;;; Cons_spec(<poplog_field_specifier>) -> BYTE
;;;     converts a Poplog field specifier into an encoded byte
define lconstant Cons_spec(spec);
    lvars spec, s;
    lconstant table = [
        full ^SPEC_FULL
        int ^SPEC_INT
        uint ^SPEC_UINT
        long ^SPEC_LONG
        ulong ^SPEC_ULONG
        short ^SPEC_SHORT
        ushort ^SPEC_USHORT
        sbyte ^SPEC_SBYTE
        byte ^SPEC_BYTE
        pint ^SPEC_PINT
        dfloat ^SPEC_DFLOAT
        sfloat ^SPEC_SFLOAT
        float ^SPEC_FLOAT
        ddecimal ^SPEC_DDECIMAL
        decimal ^SPEC_DECIMAL
        exptr ^SPEC_EXPTR
    ];
    Underlying_spec(spec) -> spec;
    if spec.isinteger then
        if spec fi_< 0 then
            (0 fi_- spec) fi_|| SPEC_BITFIELD
        else
            spec fi_|| SPEC_UBITFIELD
        endif
    else
        unless fast_lmember(spec, table) ->> s then
            mishap(spec, 1, 'UNKNOWN FIELD SPECIFIER');
        endunless;
        fast_front(fast_back(s));
    endif;
enddefine;

;;; Dest_spec(BYTE) -> <poplog_field_specifier>
;;;     decodes an encoded field specifier byte into a Poplog field specifier
define lconstant Dest_spec(spec);
    lvars spec;
    lconstant table = {
        full
        int
        uint
        long
        ulong
        short
        ushort
        sbyte
        byte
        pint
        dfloat
        sfloat
        float
        ddecimal
        decimal
        exptr
    };
    if spec &&/=_0 SPEC_BITFIELD then
        0 fi_- (spec fi_&&~~ SPEC_BITFIELD)
    elseif spec &&/=_0 SPEC_UBITFIELD then
        spec fi_&&~~ SPEC_UBITFIELD
    else
        spec fi_+1 -> spec;
        subscrv(spec, table);
    endif;
enddefine;

;;; takes a record key, returns an instance of the key
define lconstant Init_record_class(key);
    lvars key, speclist = class_field_spec(key), spec;
    fast_for spec in speclist do
        Underlying_spec(spec) -> spec;
        if spec == "full" then
            undef
        elseif spec == "exptr" then
            null_external_ptr
        else
            0
        endif;
    endfast_for;
    fast_apply(class_cons(key));
enddefine;

define lconstant Cons_subscriptor(spec, newspec) -> subscr_p;
	lvars spec, newspec, subscr_p;
	lconstant cache = newproperty([],4, false, "tmpclr");
	lconstant NO_UPDATER = consref(1);
	unless cache(spec) ->> subscr_p then
    	cons_access(NO_UPDATER, conspair(spec, false), false, false)
                        ->> cache(spec) -> subscr_p;
	endunless;
	Cons_spec(spec) -> spec;
	Cons_spec(newspec) -> newspec;
	if (spec fi_>= SPEC_DFLOAT and spec fi_<= SPEC_DECIMAL) and
			(newspec fi_< SPEC_DFLOAT or newspec fi_> SPEC_DECIMAL) then
		;;; coerce from a float to an int
		subscr_p <> intof -> subscr_p;
	endif;
enddefine;

/* READING DATA */

define :inline lconstant VBYTESIZE(vector);
    (datasize(vector) fi_- 2) fi_* 4
enddefine;

;;; byte and bit ordering manipulators

#_IF LSB_ORDERING
;;; LSB_ORDERING only

;;; a lookup table for reversing the bits in a byte
lconstant rev8table = consstring(
		0,
		lblock; lvars i, j, n;
		fast_for i from 1 to 255 do
			0 -> n;
			for j from 0 to 7 do
				if i &&/=_0 (1<<j) then n + 1<<(7-j) -> n endif;
            endfor;
			n;
		endfast_for,
		endlblock,
		256);

;;; LSB_ORDERING only
define lconstant Swap_nbit_fields(n, bitsize, data);
    lvars i, j, src, n, data, bitsize, nfields, nsub1 = n-1;
    datalength(data) * bitsize -> nfields;
	if n == 8 then
		;;; 8 bit wide fields I can handle very quickly
		(nfields + 7) div 8 -> nfields;
		fast_for i from 1 to nfields do
			fast_subscrs(fast_subscrs(i, data) fi_+1, rev8table)
				-> fast_subscrs(i, data);
		endfast_for;
	else
    	fast_for i from 1 by n to nfields do
			;;; stack -n- bits
        	fast_for j from 0 to nsub1 do
            	(i fi_+ j, data),
            	#_< sysFIELD(false, conspair(1, undef), false, 0) >_#
        	endfast_for;
			;;; update n bits (this places them back in the reverse order)
        	fast_for j from 0 to nsub1 do
            	i fi_+ j, data,
            	#_< sysUFIELD(false, conspair(1, undef), false, 0) >_#
        	endfast_for;
    	endfast_for;
	endif;
enddefine;
;;; LSB_ORDERING only
define lconstant Swap_2_vec(data);
    lvars data,j, lj;
    VBYTESIZE(data) -> lj;
    fast_for j from 1 by 2 to lj do
        fast_subscrs(j, data),
        fast_subscrs(j fi_+1, data),
        -> (fast_subscrs(j fi_+1, data), fast_subscrs(j, data));
    endfast_for;
enddefine;
;;; LSB_ORDERING only
define lconstant Swap_4_vec(data);
    lvars data, j, lj;
    VBYTESIZE(data) -> lj;
    fast_for j from 1 by 4 to lj do
        fast_subscrs(j, data),
        fast_subscrs(j fi_+1, data),
        fast_subscrs(j fi_+2, data),
        fast_subscrs(j fi_+3, data),
				-> (	fast_subscrs(j fi_+3, data),
       					fast_subscrs(j fi_+2, data),
        				fast_subscrs(j fi_+1, data),
        				fast_subscrs(j, data)
					)
    endfast_for;
enddefine;
;;; LSB_ORDERING only
define lconstant Swap_8_vec(data);
    lvars data, j, lj;
    VBYTESIZE(data) -> lj;
    fast_for j from 1 by 8 to lj do
        fast_subscrs(j, data),
        fast_subscrs(j fi_+1, data),
        fast_subscrs(j fi_+2, data),
        fast_subscrs(j fi_+3, data),
        fast_subscrs(j fi_+4, data),
        fast_subscrs(j fi_+5, data),
        fast_subscrs(j fi_+6, data),
        fast_subscrs(j fi_+7, data),
				-> (
        				fast_subscrs(j fi_+7, data),
        				fast_subscrs(j fi_+6, data),
        				fast_subscrs(j fi_+5, data),
        				fast_subscrs(j fi_+4, data),
						fast_subscrs(j fi_+3, data),
       					fast_subscrs(j fi_+2, data),
        				fast_subscrs(j fi_+1, data),
        				fast_subscrs(j, data)
					)
    endfast_for;
enddefine;
;;; LSB_ORDERING only
define :inline lconstant SWAP2(buf);
    (fast_subscrs(1, buf), fast_subscrs(2, buf)
        -> (fast_subscrs(2, buf), fast_subscrs(1, buf)))
enddefine;
;;; LSB_ORDERING only
define :inline lconstant SWAP4(buf);
    (fast_subscrs(1, buf), fast_subscrs(2, buf),
    fast_subscrs(3, buf), fast_subscrs(4, buf)
    -> (fast_subscrs(4, buf), fast_subscrs(3, buf),
        fast_subscrs(2, buf), fast_subscrs(1, buf)))
enddefine;
;;; LSB_ORDERING only
define :inline lconstant SWAP8(buf);
    (fast_subscrs(1, buf), fast_subscrs(2, buf),
    fast_subscrs(3, buf), fast_subscrs(4, buf),
    fast_subscrs(5, buf), fast_subscrs(6, buf),
    fast_subscrs(7, buf), fast_subscrs(8, buf)
    -> (fast_subscrs(8, buf), fast_subscrs(7, buf),
        fast_subscrs(6, buf), fast_subscrs(5, buf),
    	fast_subscrs(4, buf), fast_subscrs(3, buf),
        fast_subscrs(2, buf), fast_subscrs(1, buf)))
enddefine;
#_ELSE
/* these are here to stop :inline macros trying to autoload them */
lvars
	Swap_nbit_fields, Swap_2_vec, Swap_4_vec, Swap_8_vec, SWAP2, SWAP4, SWAP8;

#_ENDIF /* LSB_ORDERING */

;;; reading raw data
define :inline lconstant READ_BYTES(buf, n);
    if fast_apply(device, 1, buf, n, read_p) /== n then Do_error(false) endif
enddefine;
define :inline lconstant READ_BYTE(dummy); ;;; argument to keep 14.0 pop happy
    (READ_BYTES(buf, 1), fast_subscrs(1, buf))
enddefine;
define :inline lconstant READ_USHORT(dummy);
    (READ_BYTES(buf, 2),
	NORMALIZE(SWAP2(buf)),
    exacc [fast] :ushort ptr_to_buf)
enddefine;
define :inline lconstant READ_PINT(dummy);
    (READ_BYTES(buf, 4),
	NORMALIZE(SWAP4(buf)),
    exacc [fast] :pint ptr_to_buf)
enddefine;
define :inline lconstant READ_DECIMAL(dummy);
    (READ_BYTES(buf, 4),
	NORMALIZE(SWAP4(buf)),
    exacc [fast] :decimal ptr_to_buf)
enddefine;
define :inline lconstant READ_DDECIMAL(dummy);
    (READ_BYTES(buf, 8),
	NORMALIZE(SWAP8(buf)),
    exacc [fast] :ddecimal ptr_to_buf)
enddefine;

/* THIS IS TO SAVE THE COMPILER FROM AUTOLOADING EACH OF THESE WORDS */
lvars 		Size0, Size1, Size2, Size4,
            Integer, Decimal, Biginteger, Complex, Ratio,
            Qundef, Qtrue, Qfalse, Qnil, Qnullstring, Qnullvector, Qnullexptr,
            String, Dstring, Shortvec, Intvec, Word, Vector,
            Ref, Pair, Array, Property, Undef,
            Urecord, Uvector, Pmarknext, Pmarkrefer, Pprocname, List,
            Reserved;

define global sys_read_data(device, flags);
    lvars
        device,
        flags, noreadeof, noreadany,

        setupdone = false,
        holddata = workdata,

        ;;; 8 byte buffer to read/write data
        buf, ptr_to_buf,

        ;;; for managing marks
        markvector, markvectorsize, marknext = false, mark = 1,

        ;;; saves the stack count so that we can ensure that no bad data is
        ;;; pushed onto the stack
        stacksave,

        ;;; device read procedure
        procedure read_p = fast_sysread,
    ;
	compile_mode :vm -pentch -bjmpch -goonch;

    define lconstant Do_error(msg);
		lvars msg;
        if not(msg) and noreadeof then
            mishap(device,1,'CANNOT READ DATA (PREMATURE EOF?)');
		elseif msg == true and noreadeof then
            mishap(device,1,'ATTEMPT TO READ FROM CLOSED DEVICE');
		elseif msg.isstring and noreadany then
			mishap(msg);
        else
            erasenum(stacklength() - stacksave);
            exitfrom(not(msg) and termin or false, sys_read_data);
        endif;
    enddefine;

	define lconstant Check_vectorclass(dword) -> (type, spec, bitsize);
		lvars dword, type, spec, bitsize;
    	unless (key_of_dataword(dword) ->> type) then
    		Do_error(dword,1,'UNKNOWN DATATYPE');
    	endunless;
    	Underlying_spec(class_field_spec(type)) -> spec;
    	if spec.islist or not(spec) then
			Do_error(type,1,'EXPECTED VECTORCLASS')
		endif;
		field_spec_info(spec) -> (,bitsize);
	enddefine;

    define lconstant Read_varsize_type(size);
        lvars size, n;
        (size fi_>> 5) fi_+1 -> size;
        go_on size to Size0, Size1, Size2, Size4;

    Size0:
        return(0);
    Size1:
        return(READ_BYTE(0));
    Size2:
        return(READ_USHORT(0));
    Size4:
        return(READ_PINT(0));
    enddefine;

    define lconstant Read_word(size);
        lvars size;
        Read_varsize_type(size) -> size;
        ;;; read in chunks of 8
        lvars n = size fi_div 8;
        fast_repeat n times READ_BYTES(buf, 8); explode(buf); endfast_repeat;
        ;;; read remainder
        size fi_mod 8 -> n;
        fast_repeat n times READ_BYTE(0) endfast_repeat;
        return(consword(size));
    enddefine;

    define lconstant Try_define_mark(data);
        lvars data;
        if marknext then
            false -> marknext;
            if mark fi_> markvectorsize then
                Do_error(mark,1,'INVALID MARK');
            endif;
            data -> fast_subscrv(mark, markvector);
            mark fi_+1 -> mark;
        endif;
    enddefine;

    define lconstant Read_data;
        lvars type, signflag, size, data, num;

        READ_BYTE() -> type;

        ;;; divide the type up into its components
        (type &&/=_0 SIGN_MASK, type fi_&& SIZE_MASK, type fi_&& TYPE_MASK)
            -> (signflag, size, type);
        ;;; switch on the type of data
        go_on type fi_+1 to
            Integer, Decimal, Biginteger, Complex, Ratio,
            Qundef, Qtrue, Qfalse, Qnil, Qnullstring, Qnullvector, Qnullexptr,
            String, Dstring, Shortvec, Intvec, Word, Vector,
            Ref, Pair, Array, Property, Undef,
            Urecord, Uvector, Pmarknext, Pmarkrefer, Pprocname, List,
            Reserved, Reserved, Reserved;

		;;; fallthrough
        Do_error(type,1,'UNKNOWN DATA TYPE');

    Integer:
        Read_varsize_type(size) -> data;
		if signflag then fi_negate(data) -> data endif;
		return(data);

    Decimal:
        if size == SIZE1 then
            ;;; single decimal
            READ_DECIMAL(0) -> data;
        else
            dlocal popdprecision = true;
            READ_DDECIMAL(0) -> data;
            Try_define_mark(data);
        endif;
        return(data);

    Biginteger:
        Read_varsize_type(size) -> size;
        ;;; I can just read the bytes
        1 << (size fi_* 31 fi_-1) -> data;
        size fi_* 4 -> size;
        READ_BYTES(data, size);
		NORMALIZE(Swap_4_vec(data));
/* ALTERNATIVE SLOW VERSION ?
        ;;; construct the biginteger using + and *
        lvars scale = 1;
        0 -> data;
        repeat size times
           READ_BYTES(buf, 4);
           NORMALIZE(SWAP4(buf));
			exacc [fast] :int ptr_to_buf -> num;
           if num /== 0 then num * scale + data -> data; endif;
           scale + #_< 2**32 >_# -> scale;
       endrepeat;
*/
        Try_define_mark(data);
        return(data);

    Complex:
        lvars (real, imag) = (Read_data(), Read_data());
        if isddecimal(real) or isddecimal(imag) then
			dlocal popdprecision = true;
		endif;
        real +: imag -> data;
        Try_define_mark(data);
        return(data);

    Ratio:
        lvars (num, den) = (Read_data(), Read_data());
        num / den -> data;
        Try_define_mark(data);
        return(data);

    Qundef:
        ;;; we may have placed a 'definenext' symbol in the stream before
        ;;; a piece of data which could not be written properly, so
        ;;; we clear that using a Try_define_mark here.
        Try_define_mark(undef);
        return(undef);

    Qtrue:
        return(true);

    Qfalse:
        return(false);

    Qnil:
        return(nil);

    Qnullstring:
        return(nullstring);

    Qnullvector:
        return(nullvector);

    Qnullexptr:
        return(null_external_ptr);

    String:
        Read_varsize_type(size) -> size;
        inits(size) -> data;
        READ_BYTES(data, size);
        Try_define_mark(data);
        return(data);

    Dstring:
        lvars n = 1;
#_IF DEF dstring_key ;;; post-14.2 Poplog
        Read_varsize_type(size) -> size;
        initdstring(size) -> data;
        ;;; read the elements of the dstring one at a time since we don't
        ;;; know how they are represented
        fast_repeat size times
            READ_PINT(0) -> fast_subscrdstring(n, data);
            n fi_+1 -> n;
        endfast_repeat;
        Try_define_mark(data);
        return(data);
#_ELSE
		Do_error(0,'DSTRINGS NOT SUPPORTED');
#_ENDIF
    Shortvec:
        Read_varsize_type(size) -> size;
        initshortvec(size) -> data;
        READ_BYTES(data, size fi_* 2);
        NORMALIZE(Swap_2_vec(data));
        Try_define_mark(data);
        return(data);

    Intvec:
        Read_varsize_type(size) -> size;
        initintvec(size) -> data;
        READ_BYTES(data, size fi_* 4);
        NORMALIZE(Swap_4_vec(data));
        Try_define_mark(data);
        return(data);

    Word:
        Read_word(size) -> data;
        Try_define_mark(data);
        return(data);

    Vector:
        Read_varsize_type(size) -> size;
	    initv(size) -> data;
        Try_define_mark(data);
        lvars i;
        fast_for i from 1 to size do
            Read_data() -> fast_subscrv(i, data);
        endfast_for;
        return(data);

    Ref:
        if marknext then
            consref(undef) -> data;
            Try_define_mark(data);
            Read_data() -> fast_cont(data);
        else
            consref(Read_data()) -> data;
        endif;
        return(data);

    Pair:
        if marknext then
            initl(1) -> data;
            Try_define_mark(data);
            Read_data() -> fast_front(data);
            Read_data() -> fast_back(data);
        else
            conspair(Read_data(), Read_data()) -> data;
        endif;
        return(data);

    Array:
		Read_varsize_type(size) -> size;
        lvars bounds = [% fast_repeat size times Read_data() endfast_repeat %];
        lvars byrow = Read_data();
        lvars offset = Read_data(), size = Read_data();
        if Read_data() ->> i then
			;;; There is, perhaps stupidly, no way to make an array without
			;;; the arrayvector specification at the same time. This causes
			;;; us problems because the arrayvector may contain a backreference
			;;; to the array. We get around this by forcing the vector to be
			;;; marked when written
			define lconstant Make_array(bounds, i, n, byrow);
				lvars bounds, i, n, byrow;
				newanyarray(bounds, markvector(i), n, byrow);
			enddefine;
			lvars oldmark = mark;
			;;; we mark the data using a closure on Make_array - this
			;;; procedure will get called if reading the arrayvector generates
			;;; a Pmarkrefer to the array.
			Try_define_mark(Make_array(%bounds, i, offset fi_-1, byrow%));
			Read_data()->; ;;; read the arrayvector
			if (fast_subscrv(oldmark, markvector) ->> data).isclosure then
				;;; if reading the arrayvector didn't build the array
				;;; then do it myself
				fast_apply(fast_subscrv(oldmark, markvector))
					->> data -> markvector(oldmark);
			endif;
		else
            ;;; just read the next vector and wrap it into an array
			Read_data() -> data;
            newanyarray(bounds, data, offset fi_-1, byrow) -> data;
        endif;
        Read_data() -> pdprops(data);
        return(data);

    Property:
        lvars n, arg, val, default, procedure prop, gctype;
        Read_varsize_type(size) -> size;
        Read_data() -> default; ;;; this must not be the property table itself
        Read_data() -> gctype;
        newproperty([], size, default, gctype) -> prop;
        Try_define_mark(prop);
        Read_data() -> n;
        fast_repeat n times
            Read_data() -> arg; Read_data() -> val;
            val -> prop(arg);
        endfast_repeat;
        Read_data() -> pdprops(prop);
        return(prop);

    Undef:
        if marknext then
            consundef(undef) -> data;
            Try_define_mark(data);
            Read_data() -> fast_front(data);
        else
            consundef(Read_data()) -> data;
        endif;
        return(data);

    Urecord:            ;;; user-defined recordclass
        Read_varsize_type(size) -> size;
		if signflag then fi_negate(size) -> size endif;
        ;;; size reflects how many fields were written
		;;; two special sizes, SINGLETON_CLASS (-1)  and OBJECT_CLASS (-2)
		;;; are used to signify objectclass instances.

		lvars oldmark = marknext; false -> marknext;
        lvars dword = Read_data();
		oldmark -> marknext;

		if size == SINGLETON_CLASS then
			sys_autoload(dword) and valof(dword) -> data;
			
			unless data.isinstance  and data.datakey.isclass == "singleton"
			then
				Do_error(dword, 1, 'CANNOT FIND SINGLETON');
			endunless;
			Try_define_mark(data);
			return(data);
		endif;

        key_of_dataword(dword) -> type;
        unless type then
			dword <> "_key" -> dword;
			if sys_autoload(dword) then
				valof(dword) -> type;
			endif;
		endunless;
		unless type.iskey then
			Do_error(dword, 1, 'CANNOT FIND DATATYPE');
		endunless;

        lvars speclist = class_field_spec(type);
        unless speclist.islist then
            Do_error(type,1,'RECORDCLASS EXPECTED');
        endunless;

		if size == OBJECT_CLASS then
			;;; its an objectclass instance
			unless type.isclass then
				Do_error(type, 1, 'CLASS NEEDED');
			endunless;

			apply(type.class_new) -> data;
			Try_define_mark(data);
			instance_datain(Read_data(), data) -> data;
			if oldmark then
				data -> subscrv(mark fi_- 1, markvector);
			endif;
        else
			if datalength(type) == size and not(marknext) then
	            ;;; read -size- items and call the cons procedure
	            fast_repeat size times Read_data() endfast_repeat,
	            fast_apply(class_cons(type)) -> data;
	        else
	            Init_record_class(type) -> data;
	            Try_define_mark(data);
				;;; fill up the datastructure
				fi_min(datalength(type), size) -> n;
	            fast_for i from 1 to n do
	                Read_data() -> fast_apply(data, class_access(i, type));
	            endfast_for;
		        ;;; ignore any extra fields
				size fi_- n -> n;
				fast_repeat n times Read_data()->; endfast_repeat;
	        endif;
        endif;
		return(data);

    Uvector:            ;;; user-defined vectorclass
        Read_varsize_type(size) -> size;
		lvars oldmark = marknext; false -> marknext;
		lvars (type, newspec, newbitsize) = Check_vectorclass(Read_data());
		oldmark -> marknext;
        lvars (spec, bitsize) = (Dest_spec(READ_BYTE(0)),READ_BYTE(0));
        lvars samespec = (spec == newspec and bitsize == newbitsize);
		;;; create the datastructure
	    fast_apply(size, class_init(type)) -> data;
        Try_define_mark(data);
        ;;; read the data
        unless (Read_data() ->> i) then
            ;;; data was written an item at a time
			lvars procedure access_p;
            class_subscr(type) -> access_p;
            fast_for i from 1 to size do
                Read_data() -> access_p(i, data);
            endfast_for;
        else
            lvars nbytes = i, tmpdata;
            if samespec and nbytes fi_<= VBYTESIZE(data) then
				data -> tmpdata;
            else
                ;;; put the data into a temporary string
                inits(nbytes) -> tmpdata;
            endif;
            READ_BYTES(tmpdata, nbytes);
            NORMALIZE(
            	;;; perform byte/bit normalization
                if bitsize == 64 then
                    Swap_8_vec(tmpdata);
				elseif bitsize == 32 then
                    Swap_4_vec(tmpdata);
                elseif bitsize == 16 then
                    Swap_2_vec(tmpdata);
                elseif bitsize /== 8 then
                    ;;; a bitfield
                    Swap_nbit_fields(8, bitsize, tmpdata);
					if bitsize /== 1 then
                    	Swap_nbit_fields(bitsize, bitsize, tmpdata);
					endif;
                endif
            );
            if tmpdata /== data then
                ;;; the data was written on disc using a different spec/bitsize
                if spec == newspec and bitsize /== newbitsize then
                    Do_error(spec,1,'INCORRECT FIELD SPECIFIER BITSIZE');
                endif;
                lvars procedure access_p, procedure tmp_access_p;
				;;; use the slow (checking) access procedure for -data-
                class_subscr(type) -> access_p;
                Cons_subscriptor(spec, newspec) -> tmp_access_p;
                ;;; read the data from tmpdata and copy it into data
                fast_for i from 1 to size do
                    tmp_access_p(i, tmpdata) -> access_p(i, data);
                endfast_for;
            endif;
        endunless;
        return(data);

    Pmarknext:
        Read_varsize_type(size) -> size;
        if size == 0 then
            ;;; the next data object defines a 'mark'
            true -> marknext;
        else
            ;;; this defines the size of the mark table
            if size fi_> DEFMARKVECSIZE then
                initv(size) -> markvector;
            endif;
            size -> markvectorsize;
        endif;
        return(Read_data());

    Pmarkrefer:
        ;;; refering back to a previously marked object
        Read_varsize_type(size) -> size;
        if size fi_> mark then
            ;;; cannot refer to an item before it has been read
            Do_error(size, 1, 'INVALID MARK');
        endif;
		;;; NB. test isclosure == true because properties are protected
		;;; closures which isclosure returns -1- for.
		if (subscrv(size, markvector) ->> data).isclosure == true then
			;;; forward reference (probably for an array)
			fast_apply(data) ->> data -> fast_subscrv(size, markvector);
		endif;
		return(data);

	Pprocname:
        Read_word(size) -> data;
        Try_define_mark(data);
		Read_data() -> size; ;;; next item is the pdnargs of the procedure
		unless sys_autoload(data) and (valof(data) ->> tmpdata).isprocedure
        		and tmpdata.pdnargs == size and pdprops(tmpdata) == data then
			Do_error(data, 1, 'ATTEMPT TO RESTORE NAMED PROCEDURE FAILED');
		endunless;

		return(tmpdata);

	List:
		/* read a flat non-circular list */
        Read_varsize_type(size) -> size;
	    initl(size) -> data;
        Try_define_mark(data);
        lvars i, tmpdata = data;
        fast_for i from 1 to size do
            Read_data() -> fast_front(tmpdata);
			fast_back(tmpdata) -> tmpdata;
        endfast_for;
        return(data);

    Reserved:
        Do_error(type,1,'UNKNOWN (RESERVED) DATA TYPE');

    enddefine;

    fi_check(flags, 0, MAX_READ_FLAG)->;
	flags &&=_0 READ_EOF -> noreadeof;
	flags &&=_0 READ_ANY -> noreadany;
    stacklength() -> stacksave;
    Check_device(device, `R`);
    if device.isprocedure then Read_using_repeater -> read_p;
	elseif isclosed(device) then
		Do_error(true);
	endif;
    explode(dest(workdata) -> workdata) -> (buf, ptr_to_buf, , markvector);
    DEFMARKVECSIZE -> markvectorsize;

    ;;; ensure that our working data gets restored to the freelist
    dlocal 0 %, if dlocal_context fi_< 3 and setupdone then
    				holddata -> workdata;
                endif %;

    Read_data(), true;
enddefine;

/* WRITING DATA */

;;; writing raw data
define :inline lconstant WRITE_BYTES(object, n);
    write_p(device, 1, object, n);
    numbyteswritten fi_+ n -> numbyteswritten
enddefine;
define :inline lconstant WRITE_BYTE(i);
    i -> fast_subscrs(1, buf);
    WRITE_BYTES(buf, 1)
enddefine;
define :inline lconstant WRITE_USHORT(i);
    i -> exacc [fast] :ushort ptr_to_buf;
	NORMALIZE(SWAP2(buf));
    WRITE_BYTES(buf, 2)
enddefine;
define :inline lconstant WRITE_PINT(i);
    i -> exacc [fast] :pint ptr_to_buf;
	NORMALIZE(SWAP4(buf));
    WRITE_BYTES(buf, 4)
enddefine;

;;; writing typed data
define :inline lconstant WRITE_INTEGER(data);
    Write_varsize_type(INTEGER, data)
enddefine;
define :inline lconstant WRITE_DECIMAL(data);
    WRITE_BYTE(DECIMAL fi_|| SIZE1);
    data -> exacc [fast] :decimal ptr_to_buf;
	NORMALIZE(SWAP4(buf));
    WRITE_BYTES(buf, 4);
enddefine;
define :inline lconstant WRITE_DDECIMAL(data);
    WRITE_BYTE(DECIMAL fi_|| SIZE2);
	data -> exacc [fast] :ddecimal ptr_to_buf;
	NORMALIZE(SWAP8(buf));
	WRITE_BYTES(buf, 8);
enddefine;
define :inline lconstant WRITE_BIGINTEGER(data);
    ;;; size in long words not including length/key
    datasize(data) fi_-2 -> size;
    Write_varsize_type(BIGINTEGER, size);
	;;; we can't copy bigintegers - by adding and subtracting 1 to -data-
	;;; we ensure that Swap_4_vec doesn't munge the original biginteger
	NORMALIZE(Swap_4_vec(((data + 1) - 1) ->> data));
    WRITE_BYTES(data, size fi_* 4);
enddefine;
define :inline lconstant WRITE_WORD(type, data);
    fast_word_string(data) -> data;
    datalength(data) -> size;
    Write_varsize_type(type, size);
    WRITE_BYTES(data, size);
enddefine;

define global sys_write_data(device, data, flags) -> numbyteswritten;
    lvars
        device, data,
        flags, writeany, nomarknumbers, nomarkpacked, nomarkfull,

        setupdone = false,
        holddata = workdata,

		instances = [],

        ;;; 8 byte buffer to read/write data
        buf, ptr_to_buf,

        ;;; for managing marks
        marktable, marktotal = 0, markcount = 1,

        procedure write_p = fast_syswrite,
        numbyteswritten = 0,
        errmsg = false, ;;; error message
    ;

    define lconstant Mark_data(data);
        lvars data, type, count, mark, fullfield;
        define lconstant Mark_two with_nargs 2;
            Mark_data(); Mark_data();
        enddefine;
        Has_full_field(data) -> fullfield;
        returnif(issimple(data) or fast_lmember(data, atomictypes)
             or (nomarknumbers and isnumber(data))
             or (nomarkpacked and not(fullfield))
             or  nomarkfull
             or (marktable(data) ->> mark) == true);
		
        unless mark then
            ;;; first appearance - mark with an -undef-
            undef -> marktable(data);
        else
            ;;; second appearance - mark with -true-
            true -> marktable(data);
            marktotal fi_+1 -> marktotal;
			if data.isarray and marktable(arrayvector(data) ->> data) /== true
			then
				;;; if an array is marked, then so is its arrayvector
				true -> marktable(data);
            	marktotal fi_+1 -> marktotal;
			endif;
            return(); ;;; don't explore further
        endunless;

        ;;; recurse down any full fields
        if isvectorclass(data) or isrecordclass(data) then
            ;;; mark the elements of the record/vector
			dataword(data) -> type;
            unless fast_lmember(type, [string dstring shortvec intvec
										vector ref undef pair]) then
				Mark_data(type);
				lvars idata;
				if data.isinstance then
					if data.datakey.isclass == "singleton" then
						#_< [^false] >_#
					else
						[% instance_dataout(data) %]
					endif -> idata;
					if idata /== [] then
						idata :: instances -> instances;
						data :: instances -> instances;
						Mark_data(idata.front);
						false -> fullfield;
					endif;
				endif;
			endunless;
            if fullfield then appdata(data, Mark_data) endif;
        elseif data.isprocedure then
			Mark_data(pdprops(data));
			if isproperty(data) then
            	;;; mark the elements of the property
            	Mark_data(property_default(data));
            	fast_appproperty(data, Mark_two);
	        elseif isarray(data) then
        	    arrayvector(data) -> data;
            	Mark_data(data);
        	endif;
		endif;
    enddefine;

    define lconstant Write_varsize_type(type, pint);
        lvars type, pint;
        if pint == 0 then
            WRITE_BYTE(type fi_|| SIZE0);
        else
			if pint fi_< 0 then
				type fi_|| SIGN_MASK -> type;
				fi_negate(pint) -> pint;
			endif;
            if pint fi_<= 16:FF then
                WRITE_BYTE(type fi_|| SIZE1);
                WRITE_BYTE(pint);
            elseif pint fi_<= 16:FFFF then
                WRITE_BYTE(type fi_|| SIZE2);
                WRITE_USHORT(pint);
            else
                WRITE_BYTE(type fi_|| SIZE4);
                WRITE_PINT(pint);
            endif;
        endif
    enddefine;

    lconstant procedure (Write_data, Write_two); ;;; forward decl
	
	define lconstant Write_dataword(data, mark);
		lvars data, mark, should_unmark, dword = dataword(data);
		mark and marktable(dword) == true -> mark;
		if mark then
			;;; unmark the data
			markcount fi_-1 -> markcount;
		endif;
		;;; write the dataword
        Write_data(dataword(data));
    	if mark then
			;;; mark the dataword again
			markcount -> marktable(data);
	    	markcount fi_+1 -> markcount;
		endif;
	enddefine;

	;;; returns -true- if pair is the start of a flat unshared list
	define lconstant Is_list(pair);
		lvars pair, size = 0, mark;
		repeat;
			if (marktable(pair) ->> mark) == true or mark.isinteger then
				;;; this link is reused - its not a flat list
				return(false);
			endif;
			size fi_+ 1 -> size;
			fast_back(pair) -> pair;
			if pair == [] then ;;; reached the end of a flat list
				return(size);
			elseunless pair.ispair then ;;; not a standard list
				return(false);
			endif;
		endrepeat;
	enddefine;

	define lconstant Is_writeable_procedure(item);
		lvars item, props = pdprops(item);
		props.isword and isdefined(props) and item == valof(props) and
					word_dict_status(props) == true
	enddefine;	


    define lconstant Raw_write_data(data) /* -> success */;
        lvars dev, data, type, mark, size, i, j;

        datakey(data) -> type;

        if data.issimple then
            if type == integer_key then
                WRITE_INTEGER(data);
            elseif type == decimal_key then
                WRITE_DECIMAL(data);
            else
                return(false);
            endif;
        elseif fast_lmember(data, atomictypes) ->> i then
            WRITE_BYTE((i.fast_back.fast_front));
        elseif (marktable(data) ->> mark).isinteger then
            ;;; refering back to a previously marked piece of data
            Write_varsize_type(PMARKREFER, mark);
        else
			mark == true -> mark;
            if mark then
                ;;; define a mark
                markcount -> marktable(data);
                markcount fi_+1 -> markcount;
                Write_varsize_type(PMARKNEXT, 0);
            endif;
            if data.isnumber then
                if type == biginteger_key then
                    WRITE_BIGINTEGER(data);
                elseif type == ddecimal_key then
                    WRITE_DDECIMAL(data);
                elseif type == ratio_key then
                    WRITE_BYTE(RATIO);
                    destratio(data) -> (i,j);
                    if iscompound(i) then
                        WRITE_BIGINTEGER(i);
                    else
                        WRITE_INTEGER(i);
                    endif;
                    if iscompound(j) then
                        WRITE_BIGINTEGER(j);
                    else
                        WRITE_INTEGER(j);
                    endif;
                elseif type == complex_key then
                    WRITE_BYTE(COMPLEX);
                    destcomplex(data) -> (i,j);
                    if iscompound(i) then
                        WRITE_DDECIMAL(i);
                    else
                        WRITE_DECIMAL(i);
                    endif;
                    if iscompound(j) then
                        WRITE_DDECIMAL(j);
                    else
                        WRITE_DECIMAL(j);
                    endif;
                else
                    return(false);
                endif;
            elseif data.isvectorclass then
                datalength(data) -> size;
                if type == string_key then
                    Write_varsize_type(STRING, size);
                    WRITE_BYTES(data, size);
#_IF DEF dstring_key ;;; post 14.2 poplog
                elseif type == dstring_key then
                    Write_varsize_type(DSTRING, size);
                    ;;; write the elements of the string as pop integers
                    fast_for i from 1 to size do
                        WRITE_PINT(fast_subscrdstring(i, data));
                    endfast_for;
#_ENDIF
                elseif type == intvec_key then
                    Write_varsize_type(INTVEC, size);
        			NORMALIZE(Swap_4_vec(copy(data) ->> data));
                    WRITE_BYTES(data, size fi_* 4);
                elseif type == shortvec_key then
                    Write_varsize_type(SHORTVEC, size);
					NORMALIZE(Swap_2_vec(copy(data) ->> data));
                    WRITE_BYTES(data, size fi_* 2);
                elseif type == vector_key then
                    Write_varsize_type(VECTOR, size);
                    appdata(data, Write_data);
                else
                    ;;; user-defined vectorclass
                    lvars cfs = class_field_spec(type);
                    lvars spec = Underlying_spec(cfs);
                    lvars (, bitsize) = field_spec_info(spec);
                    Write_varsize_type(UVECTOR, size);
                    Write_dataword(data, mark);
                    WRITE_BYTE(Cons_spec(spec));
                    WRITE_BYTE(bitsize);
                    if spec == "exptr" and not(writeany) then
                        {'Cannot write "exptr" vectors' [^data]} -> errmsg;
                        return(false);
                    endif;
                    if spec == "exptr" or spec == "full" or cfs /== spec then
                        Write_data(false);
                        appdata(data, Write_data);
                    else
						;;; round the data to the nearest byte boundary
                        (size fi_* bitsize fi_+ 7) fi_div 8 -> size;
                        Write_data(size); ;;; saves us recalculating it later
						NORMALIZE(
				            if bitsize /== 8 then	
								copy(data) -> data;	
				                if bitsize == 64 then	
				                    Swap_8_vec(data);	
								elseif bitsize == 32 then	
				                    Swap_4_vec(data);	
				                elseif bitsize == 16 then	
				                    Swap_2_vec(data);	
				                else	
				                    ;;; a bitfield	
				                    Swap_nbit_fields(8, bitsize, data);	
									if bitsize /== 1 then	
				                    	Swap_nbit_fields(bitsize, bitsize, data);	
									endif;	
				                endif;	
				            endif	
						);
                        WRITE_BYTES(data, size);
                    endif;
                endif;
            elseif type == word_key then
                unless word_dict_status(data) == true then
                    {'CANNOT WRITE -word_identifier- words' [^data]} -> errmsg;
                    return(false);
                endunless;
                WRITE_WORD(WORD, data);
            elseif data.isrecordclass then
                if type == pair_key then
					if (data.Is_list ->> size) then
                    	Write_varsize_type(LIST, size);
                    	fast_for i in data do Write_data(i); endfast_for;
					else
                    	WRITE_BYTE(PAIR);
                    	Write_data(fast_front(data));
						Write_data(fast_back(data));
					endif;
                elseif type == ref_key then
                    WRITE_BYTE(REF);
                    Write_data(fast_cont(data));
                elseif type == undef_key then
                    WRITE_BYTE(UNDEF);
                    Write_data(undefword(data));
                else

                    lvars i;
					if isinstance(data) and
							(fast_lmember(data, instances) ->> i) then
						if type.isclass == "singleton" then
							Write_varsize_type(URECORD, SINGLETON_CLASS);
	        		        Write_dataword(data, mark);
						else
							Write_varsize_type(URECORD, OBJECT_CLASS);
							Write_data(i.back.front.front);
						endif;
					else
	                    ;;; user-defined recordclass
    	                datalength(type) -> size;
        	            Write_varsize_type(URECORD, size);
	        	        Write_dataword(data, mark);
                	    appdata(data, Write_data);
					endif;
                endif;
            elseif type == procedure_key then
                pdprops(data) -> j;
				if isproperty(data) then
                    Write_varsize_type(PROPERTY, property_size(data));
                    Write_data(property_default(data));
                    Write_data(true); ;;; GC TYPE - perm for now
                    Write_data(datalength(data));
                    fast_appproperty(data, Write_two);
                    Write_data(j);
                elseif isarray(data) then
					boundslist(data) -> size;
					Write_varsize_type(ARRAY, listlength(size));
                    applist(size, Write_data);
                    Write_data(isarray_by_row(data));
					arrayvector_bounds(data) -> size ->;
                    Write_data(size);
					Write_data(datalength(arrayvector(data)));
					lvars arrv = arrayvector(data);
					if mark then
						if (marktable(arrv) ->> i).isinteger then
							;;; the arrayvector has already been written
							Write_data(i);
						else
							;;; the arrayvector is next in line
							Write_data(markcount);
						endif;
					else
						Write_data(false);
					endif;
	                Write_data(arrv);
    	            Write_data(j);
                elseif Is_writeable_procedure(data) then
					;;; write the procedure by name
                	WRITE_WORD(PPROCNAME, j);
                    Write_data(pdnargs(data));
                else
					return(false)
				endif;
            else
                return(false);
            endif;
        endif;
        return(true)
    enddefine;

    define lconstant Write_data(data);
        lvars data;
        unless Raw_write_data(data) then
            if writeany then
                if data.isexternal_ptr_class then
                    Raw_write_data(null_external_ptr)->;
                else
                    Raw_write_data(undef)->;
                endif;
            else
                if errmsg then
                    mishap(errmsg.explode);
                else
                    mishap(data,1,'CANNOT WRITE DATA (UNSUPPORTED TYPE?)');
                endif;
            endif
        endunless;
    enddefine;

    define lconstant Write_two(a,b);
		lvars a,b;
        Write_data(a); Write_data(b);
    enddefine;

    explode(dest(workdata) -> workdata) -> (buf, ptr_to_buf, marktable, );
    true -> setupdone;

    ;;; ensure that the working data gets restored to the freelist
    dlocal 0 %, if dlocal_context fi_< 3 and setupdone then
                    clearproperty(marktable);
                    holddata -> workdata;
                endif %;

    fi_check(flags, 0, MAX_WRITE_FLAG)->;
    Check_device(device, `W`);
    if device.isprocedure then Write_using_consumer -> write_p;
	else
		if testdef pop_null_device and device == weakref pop_null_device then
			Write_using_null -> write_p;
		elseif isclosed(device) then
			mishap(device,1,'ATTEMPT TO WRITE TO CLOSED DEVICE');
		endif;
	endif;

    flags &&/=_0 WRITE_ANY -> writeany;
    flags &&/=_0 MARK_NUMBERS -> nomarknumbers;
    flags &&/=_0 MARK_PACKED -> nomarkpacked;
    flags &&/=_0 MARK_FULL -> nomarkfull;
    Mark_data(data);
    if marktotal /== 0 then Write_varsize_type(PMARKNEXT, marktotal); endif;
    Write_data(data);
enddefine;


/* REPEATERS */

define global discdatain(dev) -> dev;
    lvars dev, device, real_device, flags = 2:1; ;;; don't error on eof
    if dev.isinteger then dev -> (dev, flags); endif;
    if dev.isdevice or (dev.isprocedure and pdnargs(dev) == 0) then
        ;;; its a device or a repeater
        dev ->> real_device -> device;
		while real_device.isclosure and datalength(real_device) >= 1 then
			;;; this digs out the device from a -discin-,
			;;; allowing our repeater to work with isclosed.
			frozval(1, real_device) -> real_device;
		endwhile;
    else
        if isword(dev) then
            fast_word_string(dev) sys_>< pop_default_type -> dev;
        endif;
        sysopen(dev, 0, true, `N`) -> device;
    endif;
    define lconstant Repeater(dummy, dev, flags);
        lvars dummy, dev, flags;
        unless sys_read_data(dev, flags) == true then
            sysclose(dev);
            termin;
        endunless;
    enddefine;
    Repeater(%real_device, device, flags%) -> dev;
    device.isdevice and device_full_name(device) or pdprops(device)
            -> pdprops(dev);
enddefine;

define global discdataout(dev) -> dev;
    lvars dev, device, flags = 0, real_device;
    if dev.isinteger then dev -> (dev, flags); endif;
    if dev.isdevice or (dev.isprocedure and pdnargs(dev) == 1) then
        ;;; its a device or a consumer
        dev ->> real_device -> device;
		while real_device.isclosure and datalength(real_device) >= 1 then
			;;; this digs out the device from a -discout-,
			;;; allowing our consumer to work with isclosed.
			frozval(1, real_device) -> real_device;
		endwhile;
    else
        if isword(dev) then
            fast_word_string(dev) sys_>< pop_default_type -> dev;
        endif;
        unless syscreate(dev, 1, false) ->> device then
            mishap(dev, 1, 'CAN\'T CREATE FILE')
        endunless
    endif;
    define lconstant Consumer(data, dummy, dev, flags);
        lvars data, dummy, dev, flags;
        if data == termin then
            if dev.isprocedure then
				fast_apply(termin, dev);
			else
				sysclose(dev);
			endif;
        else
            sys_write_data(dev, data, flags)->;
        endif;
    enddefine;
    Consumer(%real_device, device, flags%) -> dev;
    device.isdevice and device_full_name(device) or pdprops(device)
            -> pdprops(dev);
enddefine;

global vars datainout = true;
endsection;

/* --- Revision History --------------------------------------------------
JM, 27/10/93
	--- Mods to sys_read_data to use more fast procs.

JM, 10/8/93
	--- Added the LIST type, for lists with no shared pairs (i.e. not
		circular lists). This is to reduce the recursion nesting level for
		long lists.

JM, 20/5/93
	--- Rewrote so that it always writes data in MSB ordering. This makes
		reading/writing on MSB machines faster and smaller. LSB machines
		pay a penalty.

		The main reason for this change is to ensure that the data generated
		by different machines will always be the same for the same Poplog
		datastructures, allowing reliable hashing to be done on the output.
		See HELP *DBM.

JM, 18/5/93
	--- Added PPROCNAME
*/
