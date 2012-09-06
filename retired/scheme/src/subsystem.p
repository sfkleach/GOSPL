;;; -- Add Scheme as a SUBSYSTEM --------------------------------------------

define set_scheme();
    appdata( '\nSet Scheme\n', cucharout );
enddefine;

[scheme ^compile_scheme '.s' ^prompt_scheme ^set_scheme]
    :: sys_subsystem_table -> sys_subsystem_table;

[ ['.s' {popcompiler compile_scheme} ] ^^vedfiletypes ] -> vedfiletypes; 

define macro scheme();
    "scheme" -> subsystem;
    switch_subsystem_to( "scheme" );
enddefine;

'output.s' -> vedlmr_print_in_file;        

'$poplocal/local/scheme/doc' :: veddoclist -> veddoclist;

uses ved_src;
[ '$poplocal/local/scheme/src' src ] :: vedsrclist -> vedsrclist;
