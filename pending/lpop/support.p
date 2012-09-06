;;; -- Support for LFOR -- incorporated into PLUG Source Code Library v2.0

define global exists( data, pred ) -> r;
    false -> r;
    if data.islist then
        until null( data ) do
            if pred( fast_destpair( data ) -> data ) ->> r then
                return
            endif;
        enduntil;
    else
        appdata(
            data,
            procedure( x ); lvars x;
                if pred( x ) ->> r then
                    exitfrom( appdata )
                endif;
            endprocedure
        )
    endif
enddefine;

define global syntax def_typespec_predicate;
    lvars w = readitem();
    lvars name = w <> "':typespec'";
    if pop11_try_nextreaditem( "=" ) then
        pop11_comp_expr()
    else
        sysPUSH( w );
    endif;
    procedure( procedure p );
        lvars ts = identfn(% %);
        procedure( x ) -> x;
            unless p( x ) do
                mishap( x, 1, 'TYPESPEC FAILED (' sys_>< w sys_>< ')' )
            endunless
        endprocedure -> updater( ts );
        conspair( true, ts(% "full", true %) )
    endprocedure.sysCALLQ;
    sysCONSTANT( name, 0 );
    sysGLOBAL( name );
    sysPOP( name );
enddefine;

def_typespec_predicate isvector;
def_typespec_predicate isprocedure;
def_typespec_predicate isword;

define lconstant bitval_to_bool( bit );
    bit /== 0
enddefine;

define updaterof bitval_to_bool( bool );
    unless bool do
        0
    elseif bool == true then
        1
    else
        mishap( bool, 1, 'Boolean needed for flag field' )
    endunless
enddefine;

p_typespec flag : 1 # bitval_to_bool;

define global isvectorclasskey( k );
    returnunless( k.iskey )( false );
    lvars s = k.class_field_spec;
    s and not( s.islist )
enddefine;

define isnull( x );
    if x.isvectorclass then datalength( x ) == 0 else null( x ) endif
enddefine;
