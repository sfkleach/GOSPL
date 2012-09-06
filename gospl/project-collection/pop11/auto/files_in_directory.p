;;; Summary: gets all files in a directory

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        14th Oct 1991
Description
    Find all the files in a particular directory.  Dumps all the files
    onto the stack.
\**************************************************************************/

section;

define global vars procedure files_in_directory( d ); lvars d;
    lvars i;
    for i in_items files_matching( d dir_>< '.*' ) do
        lvars f = sys_fname_namev( i );
        unless f = '.' or f = '..' then
            i
        endunless
    endfor;
    files_matching( d dir_>< '*' );
enddefine;

sysprotect( "files_in_directory" );

endsection;
