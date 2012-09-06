
uses subsystem;
uses ved_wiggle;

true -> popdefineconstant;
true -> popdefineprocedure;

define lconstant loadhere( s ); lvars s;
    lconstant here = '$poplocal/local/scheme/src/' ;
    pr( ';;; Scheme loading -- '); pr( s ); nl( 1 );
    compile( here sys_>< s );
enddefine;

loadhere( 'init.p' );
loadhere( 'pushable.p' );
loadhere( 'read.p' );
loadhere( 'kernel.p' );
loadhere( 'vm.p' );
loadhere( 'special.p' );
loadhere( 'valid.p' );
loadhere( 'plant.p' );
loadhere( 'eval.p' );
loadhere( 'print.p' );
loadhere( 'display.p' );
loadhere( 'utils.p' );
loadhere( 'builtin.p' );
loadhere( 'subsystem.p' );

false -> popdefineconstant;
false -> popdefineprocedure;
