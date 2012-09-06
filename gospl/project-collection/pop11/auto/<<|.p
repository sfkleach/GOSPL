;;; Summary: procedure variable composition brackets

section;

global vars syntax |>> ;

define global vars syntax <<| ;
    lvars vs = read_variables();
    pop11_need_nextitem( "|>>" ).erase;
    sysPROCEDURE( false, 0 );
    applist( allbutlast( 1, vs ), sysCALL );
    sysPUSH( last( vs ) );
    sysCALL( "chain" );
    sysENDPROCEDURE().sysPUSHQ;
enddefine;

sysprotect( "<<|" );
sysprotect( "|>>" );
endsection;
