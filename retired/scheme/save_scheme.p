
uses scheme;

define save_scheme;
    lvars s = version_scheme >< ' ' >< sysdaytime() >< '\n';
    "scheme" -> subsystem;
    sysgarbage();
    if syssave( '$poplocal/bin/scheme.psv' ) do
        pr( s );
        true -> pop_first_setpop;
        unless poparglist = [] do
            popval( [ved ^^poparglist] );
        endunless;
        switch_subsystem_to( "scheme" );
    endif;
enddefine;
