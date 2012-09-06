;;; Summary: all files matching wildcard specification

/**************************************************************************\
Contributor                 Steve Knight, HP Labs.
Date                        14th Oct 1991
Description
    Find all the files matching a particular wildcard.  The file names
    are dumped on the stack.
\**************************************************************************/

compile_mode :pop11 +strict;

section;

uses sys_file_match;

define files_matching( f );
    apprepeater( sys_file_match( f, false, false, false ), identfn )
enddefine;

endsection;
