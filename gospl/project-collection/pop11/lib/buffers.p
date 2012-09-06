;;; Summary: an implementation of extensible vectors

compile_mode :pop11 +strict;

section;


;;; Error messages.
lconstant
    non_neg_msg = 'Non-negative integer needed',
    pos_int_msg = 'Positive integer needed';

defclass lconstant store {
    store_vector,
    store_used      : pint,
    store_capacity  : pint,
    store_default,
    store_buffer
};

define lconstant fast_buffer_store( buffer );
    buffer.pdprops.back
enddefine;

define lconstant buffer_store( item );
    lvars s;
    if
        item.isprocedure and
        item.pdprops.ispair and
        isstore( item.pdprops.back ->> s )
    then
        s
    else
        mishap( item, 1, 'Buffer required' )
    endif
enddefine;

define lconstant ensure( k, store );
    lvars vec = store.store_vector;
    max( k, store.store_capacity * 2 + 8 ) -> k;
    ;;; [ expanding from % store.store_capacity % to ^k ( ^k was suggested ) ] =>
    lvars newvec = class_init( datakey( store.store_vector ) )( k );
    move_subvector( 1, vec, 1, newvec, vec.datalength );
    k -> store.store_capacity;
    newvec -> store.store_vector;
enddefine;

define lconstant buffer_diagnosis( num, store );
    lvars buf = store.store_buffer;
    if num.isinteger then
        if num < 1 then
            mishap( num, buf, 2, 'Index out of range (too small)' )
        elseif num > store.store_used then
            mishap( num, buf, 2, 'Index out of range (too big)' )
        else
            mishap( 0, 'Internal error' )
        endif
    else
        mishap( num, buf, 2, 'Invalid index for buffer (integer needed)' )
    endif
enddefine;

define new_buffer_hint( key, size, default ) -> buffer;

    key or vector_key -> key;
    lvars store =
        consstore(
            class_init( key )( fi_check( size, 0, false ) ),
            0,
            size,
            default,
            _           ;;; will become a self-pointer.
        );
    lvars props = conspair( key.class_dataword <> "_buffer", store );

    define check();
        sysLVARS( "num", 0 );
        sysPOP( "num" );
        sysPUSH( "num" );
        sysCALL( "isinteger" );
        sysIFNOT( "ouch" );
        sysPUSHQ( store );
        sysFIELD( 2, class_field_spec( store_key ), false, false );
        sysPUSH( "num" );
        sysCALL( "fi_<" );
        sysIFSO( "ouch" );
        sysPUSH( "num" );
        sysPUSHQ( 1 );
        sysCALL( "fi_<" );
        sysIFSO( "ouch" );
    enddefine;

    define push();
        sysPUSH( "num" );
        sysPUSHQ( store );
        sysFIELD( 1, class_field_spec( store_key ), false, false );
    enddefine;

    define diagnosis();
        sysGOTO( "done" );
        sysLABEL( "ouch" );
        sysPUSH( "num" );
        sysPUSHQ( store );
        sysCALLQ( buffer_diagnosis );
        sysLABEL( "done" );
    enddefine;

    procedure();
        sysPROCEDURE( props, 1 );
        check();
        push();
        sysFIELD( false, conspair( class_field_spec( key ), _ ), false, false );
        diagnosis();
        sysPUSHQ( sysENDPROCEDURE() );
        sysEXECUTE();
    endprocedure.sysCOMPILE ->> buffer -> store.store_buffer;

    procedure();
        sysPROCEDURE( false, 2 );
        check();
        push();
        sysUFIELD( false, conspair( class_field_spec( key ), _ ), false, false );
        diagnosis();
        sysPUSHQ( sysENDPROCEDURE() );
        sysEXECUTE();
    endprocedure.sysCOMPILE -> buffer.updater;

enddefine;

define new_buffer( key, default );
    new_buffer_hint( key, 0, default )
enddefine;

define app_buffer( buffer, procedure proc );
    lvars store = buffer.buffer_store;
    lvars vec = store.store_vector;
    lvars subscr = class_fast_subscr( datakey( vec ) );
    lvars i;
    fast_for i from 1 to store.store_used do
        proc( fast_apply( i, vec, subscr ) )
    endfor;
enddefine;


define buffer_insert( item, num, buffer );

    unless isinteger( num ) and num fi_>= 1 do
        mishap( num, 1, pos_int_msg )
    endunless;

    lvars store = buffer.buffer_store;
    lvars capacity = store.store_capacity;
    lvars used = store.store_used;
    lvars vec = store.store_vector;

    lvars used1 = used fi_+ 1;              ;;; safe because used <= capacity
    lvars newused = max( used1, num );      ;;; and capacity is a datalength

    if newused fi_>= capacity then
        if num fi_<= used then
            move_subvector(
                num, vec,
                num fi_+ 1, vec,            ;;; safe because num <= used
                used1 fi_- num              ;;; safe because both > 0
            )
        else
            set_subvector(
                store.store_default,
                used1,
                vec,
                num fi_- used1              ;;; safe because both > 0
            )
        endif;
        ;;; The update to store is done _after_ the move/set_subvector
        ;;; because they perform necessary dynamic checks.
        newused -> store.store_used;
        item -> vec( num )
    else
        ensure( num, store );
        chain( item, num, buffer, buffer_insert )
    endif
enddefine;


;;; We need a key lemma here for fast integer subtraction :-
;;; Lemma:
;;;     for all integers A >= 0 and B >= 0,
;;;         A - B == A fi_- B

;;; We also make use of an absolutely key assumption - that datalength
;;; always returns a results SMALLER than the pop_max_int.  This
;;; assumption lets us write datalength( x ) fi_+ 1 safely.  But does
;;; Poplog enforce this?  If it doesn't it would be a bug!  Note that
;;; we CANNOT make the same requirement of length (because of dynamic
;;; lists).

define buffer_insert_n( n, num, buffer );
    ;;; [ insert ^n ^num ^buffer ] =>

    ;;; Sneaky code to avoid lots of work for inserting 0 items.
    unless isinteger( n ) and n fi_> 0 do
        returnif( n == 0 );     ;;; ALERT!  Efficiency hack!
        mishap( num, 1, 'Number of items to insert must be a non-negative integer' )
    endunless;

    ;;; ASSERT: isinteger( n ) and n >= 1.

    unless isinteger( num ) and num fi_>= 1 do
        mishap( num, 1, 'Insertion point must be a non-negative integer' )
    endunless;

    lvars store = buffer.buffer_store;
    lvars used = store.store_used;

    ;;; This will be the length of active portion of the buffer.
    lvars newused = max( num fi_- 1, used ) + n;
    unless isinteger( newused ) do
        mishap( n, 1, 'Attempt to overflow buffer overflow trapped (too many items)' )
    endunless;

    ;;; This is the index of the last item inserted into the list.  Typically
    ;;; this is not the same as newused.
    lvars newfinal = num + ( n fi_- 1 );               ;;; not safe, use +
    unless isinteger( newfinal ) do
        mishap( n, num, 2, 'Attempt to overflow buffer (insertion point too big)' )
    endunless;

    lvars capacity = store.store_capacity;
    lvars used = store.store_used;
    lvars vec = store.store_vector;

    lvars used1 = used fi_+ 1;       ;;; safe because used <= capacity & capacity is a datalength.
    if newused fi_<= capacity then
        if num fi_<= used then
            ;;; We will have to shift items out of the way.
            move_subvector(
                num, vec,
                num fi_+ n, vec,
                used1 fi_- num      ;;; safe because used1 and num are >= 0
            );
        else
            ;;; [ extending vector, woah! ] =>
            set_subvector(
                store.store_default,
                used1,
                vec,
                num fi_- used1      ;;; safe because used1 and num are >= 0
            );
        endif;
    else
        ensure( newused, store );
        chain( n, num, buffer, buffer_insert_n )
    endif;

    newused -> store.store_used;
    lvars usubscr = updater( class_fast_subscr( datakey( vec ) ) );
    lvars i;
    fast_for i from newfinal by -1 to num do
        fast_apply( (), i, vec, usubscr )
    endfor;
enddefine;

define buffer_length( buffer );
    buffer.buffer_store.store_used
enddefine;

define buffer_pop( buffer );
    lvars store = buffer.buffer_store;
    lvars used = store.store_used;
    if used fi_>= 1 then
        lvars vec = store.store_vector;
        vec( used );                        ;;; push item onto stack.
        used fi_- 1 -> store.store_used;
    else
        mishap( buffer, 1, 'Trying to pop an empty buffer' )
    endif
enddefine;

define buffer_pop_n( n, buffer );

    ;;; "Cunning" trick used again.  We do not want to do much if n == 0.
    ;;; However, we do not want to add a n == 0 test since that would
    ;;; increase, even if only minutely, the overall cost of the common
    ;;; case.  Instead we trap it indirectly via a test we are obliged
    ;;; to perform anyway.
    unless isinteger( n ) and n fi_> 0 do
        returnif( n == 0 );
        mishap( n, 1, non_neg_msg )
    endunless;

    ;;; We now know that n is at least 1.  This is vital because later
    ;;; on we wish to compute used - n + 1.  We can only do this in
    ;;; fast arithmetic because of this guarantee!  The cunning trick
    ;;; pays double dividends.

    ;;; BIZARRE INFLAMMATORY INSERT ------------------------------------

    ;;; I am sorry it is so ugly.  Blame them - the secret evil
    ;;; conspiracy that makes computers that cannot do general arithmetic.
    ;;; The ugliness stems directly from the horrid restrictions on
    ;;; arithmetic.  It is not my fault.  It is not Poplog's fault.

    ;;; And to think that people programming in C, C++ and Java neglect
    ;;; this nearly all the time!  Hey - if you do not believe me try
    ;;; doing weakest preconditions on the safety of all your arithmetic.
    ;;; You have to prove that EVERY + and EVERY - and EVERY * (etc)
    ;;; is safe i.e. will not overflow.  Go on - do it.  I can promise
    ;;; a form of ghastly enlightenment.  Perhaps one should call it
    ;;; endarkening, the kind of revelation that shows matters are
    ;;; worse, far worse, than you had ever imagined?

    ;;; And what are the consequences if there is an overflow?  The
    ;;; damage is potentially unlimited.  In point of fact, indexing
    ;;; from an unproven safe integer in C can potentially lead to total
    ;;; system corruption and, worse, can act as a backdoor for hostile
    ;;; penetration.  The tradeoff in Java is rather more subtle, though.
    ;;; You may come to believe, as I do, that the use of 32-bit
    ;;; arithmetic reduces the overall performance of the JVM.

    ;;; Come, the darkness is beckoning ....

    ;;; END OF BIZARRE INFLAMMATORY INSERT  ----------------------------

    lvars store = buffer.buffer_store;
    lvars used = store.store_used;

    if used fi_>= n then
        lvars vec = store.store_vector;
        lvars i, subscr = class_fast_subscr( datakey( vec ) );
        fast_for i from used fi_- n fi_+ 1 to used do
            fast_apply( i, vec, subscr );               ;;; push item onto stack.
        endfor;
        used fi_- n -> store.store_used;
    else
        mishap( n, buffer, 2, 'Not enough elements in buffer (only ' sys_>< used sys_>< ')' )
    endif
enddefine;

;;; We utilise the guarantee that capcity is an integer.  Thus if used
;;; is an integer less than capacity is is safe to add 1.
;;;
define buffer_push( item, buffer );
    lvars store = buffer.buffer_store;
    lvars capacity = store.store_capacity;
    lvars used = store.store_used;
    lvars vec = store.store_vector;
    if used fi_< capacity then
        item -> vec( used fi_+ 1 ->> store.store_used )
    else
        ensure( used + 1, store );
        chain( item, buffer, buffer_push )
    endif
enddefine;

;;; You have to be VERY CAREFUL with the fast integer arithmetic in
;;; this routine.  You cannot assume n is an integer or that even if it
;;; is that (used + n) is an integer.  However, since used >= 0 and
;;; isinteger( used ), if (used + n) is an integer, everything is fine.
;;;
define buffer_push_n( n, buffer );
    lvars store = buffer.buffer_store;
    lvars capacity = store.store_capacity;
    lvars used = store.store_used;
    lvars vec = store.store_vector;
    lvars newused = fi_check( used + n, 0, false );
    if newused fi_<= capacity then
        lvars usubscr = updater( class_fast_subscr( datakey( vec ) ) );
        lvars i;
        fast_for i from 0 to n fi_- 1 do
            fast_apply( (), newused fi_- i, vec, usubscr )
        endfor;
        newused -> store.store_used;
    else
        ;;; [ newused ^newused used ^used ^n ] =>
        ensure( newused, store );
        chain( n, buffer, buffer_push_n )
    endif
enddefine;

define buffer_set_length( n, buffer );
    lvars store = buffer.buffer_store;
    lvars capacity = store.store_capacity;
    lvars used = store.store_used;
    lvars vec = store.store_vector;
    if fi_check( n, 0, false ) fi_<= used then
        n -> store.store_used
    elseif n fi_<= capacity then
        set_subvector(
            store.store_default,
            fi_check( used + 1, 1, false ),
            vec,
            vec.datalength fi_- used
        );
        n -> store.store_used
    else
        ensure( n, store );
        chain( n, buffer, buffer_set_length )
    endif
enddefine;

define buffer_remove( num, buffer ) -> item;

    lvars store = buffer.buffer_store;
    lvars used = store.store_used;
    lvars vec = store.store_vector;

    ;;; Incidentally proves isinteger( num ) and 1 <= num <= capacity
    vec( num ) -> item;

    if used fi_> 0 and used fi_>= num then
        move_subvector(
            num fi_+ 1, vec,      ;;; safe because num <= capacity and capacity is a datalength
            num, vec,
            used fi_- num
        );
        used fi_- 1 -> store.store_used;    ;;; safe by Lemma
    else
        mishap( num, buffer, 2, 'Index too big for buffer' )
    endif
enddefine;

define buffer_remove_n( n, num, buffer );

    ;;; Yet again we do the ugly trick.  However, I resist bursting
    ;;; into another rant against evil architectures.  Well, almost ...
    unless isinteger( n ) and n fi_> 0 do
        returnif( n == 0 );     ;;; ALERT!  All too clever by half ...
        mishap( n, 1, non_neg_msg )
    endunless;

    ;;; ASSERT n >= 1 and isinteger( n )

    unless isinteger( num ) and num fi_>= 1 do
        mishap( num, 1, pos_int_msg )
    endunless;

    lvars store = buffer.buffer_store;
    lvars used = store.store_used;
    lvars vec = store.store_vector;

    lvars final = num + ( n fi_- 1 );
    unless isinteger( final ) and final fi_<= used do
        mishap( n, num, buffer, 3, 'Not enough elements in buffer for removal' )
    endunless;

    ;;; ASSERT final <= used <= capacity  (therefore final fi_+ 1 is OK)
    ;;; ASSERT final >= num ..... so num <= used
    ;;; ASSERT final >= n   ..... so n   <= used

    lvars subscr = class_fast_subscr( datakey( vec ) );
    lvars i;
    fast_for i from num to final do
        fast_apply( i, vec, subscr )        ;;; PUSH!
    endfor;

    move_subvector(
        final fi_+ 1, vec,
        num, vec,
        used fi_- final
    )
enddefine;

define dest_buffer( buffer );
    #| app_buffer( buffer, identfn ) |#
enddefine;

define explode_buffer( buffer );
    app_buffer( buffer, identfn )
enddefine;

define is_buffer( item );
    item.isprocedure and
    item.pdprops.ispair and
    item.pdprops.back.isstore
enddefine;

define is_empty_buffer( buffer );
    buffer.buffer_store.store_used == 0
enddefine;

define map_buffer( buffer, proc ) -> new;
    lvars store = buffer.buffer_store;
    new_buffer_hint(
        store.store_vector.datakey,
        store.store_used,
        store.store_default
    ) -> new;
    buffer_push_n(
        #| app_buffer( buffer, proc ) |#,
        new
    )
enddefine;

define buffer_contents( buffer ) -> result;
    lvars store = buffer.buffer_store;
    lvars vec = store.store_vector;
    lvars used = store.store_used;
    class_init( datakey( vec ) )( used ) -> result;
    move_subvector(
        1, vec,
        1, result,
        used
    )
enddefine;

define buffer_copy( buffer );
    map_buffer( buffer, identfn )
enddefine;

define ncmap_buffer( buffer, procedure proc ) -> buffer;
    lvars store = buffer.buffer_store;
    lvars vec = store.store_vector;
    lvars subscr = class_fast_subscr( datakey( vec ) );
    lvars usubscr = updater( subscr );
    lvars i;
    fast_for i from 1 to store.store_used do
        fast_apply( proc( fast_apply( i, vec, subscr ) ), i, vec, usubscr )
    endfor;
enddefine;

define subscr_buffer( num, buffer );
    buffer.buffer_store -> _;
    fast_apply( num, buffer )
enddefine;

define updaterof subscr_buffer( value, num, buffer );
    buffer.buffer_store -> _;
    value -> fast_apply( num, buffer )
enddefine;

endsection;
