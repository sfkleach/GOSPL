;;; This file is part of the GOSPL admin and not the general distribution.
;;;
;;; It iterates over all the package directories and creates
;;; several documentation files for each package:
;;;
;;;     .htaccess           --  contains AddDescriptions for Apache folders
;;;     CONTENTS.html       --  a listing of contents in HTML
;;;     CONTENTS.txt        --  as above but in plain text for VED
;;;
;;; These are prepared from the special summary lines that are added
;;; to the files in the "auto" and "lib".
;;;

;;; Load up the initialization library.
;;; load $poplib/init.p
sysinitcomp();

;;;
;;; Used to create a link to help-files.  Given a file name,
;;; find the corresponding help file (or fall back to ref/teach/
;;; doc in order).
;;;
define find_help_file( name ) -> result;
    lconstant dirs = [ 'help' 'ref' 'teach' 'doc' ];

    lvars result = nullstring;
    lvars d;
    for d in dirs do
        lvars file = d dir_>< name;
        if file.sys_file_exists then
            sprintf(
                '%p <A HREF="%p"><FONT SIZE=-1>%p</FONT></A>',
                [% result, file, d %]
            ) -> result
        endif
    endfor;

    if datalength( result ) == 0 then
        '&nbsp;' -> result
    endif;
enddefine;

;;;
;;; A regular expression that defines the summary line and
;;; pulls out the content as a backref.
;;;
constant ( _, summary_p ) = (
    regexp_compile(
        '@^;;;@[\s\t@]@*Summary@[\s\t@]@*:@[\s\t@]@*@(@.@*@)@$'
    )
);


;;;
;;; Search for the special 'Summary' lines and creates a list
;;; of pairs
;;;     front:  filename
;;;     back:   the contents of the summary lines
;;;
define make_data( subdir );
    [%
        lvars f;
        for f in_directory subdir do
            nextif( sysisdirectory( f ) );
            lvars line = discinline( f )();
            nextunless( line.isstring );
            nextif( datalength( sys_fname( f, 6 ) ) > 0 );
            lvars extn = sys_fname_extn( f );
            unless extn = '.html' or extn = '.txt' do
                conspair(
                    f,
                    if summary_p( 1, line, false, false ) -> _ then
                        substring( regexp_subexp( 1, summary_p ) )
                    else
                        false
                    endif
                )
            endunless
        endfor;
    %]
enddefine;

;;;
;;; Used to add line number info to CONTENTS.html
;;;
define count_lines( f );
    lvars ch, n = 0;
    for ch from_repeater f.discin do
        if ch == `\n` then
            n + 1 -> n
        endif
    endfor;
    n
enddefine;

define make_htaccess( alldata );
    dlocal cucharout = discout( '.htaccess' );
    lvars i;
    for i in alldata do
        lvars ( name, summary ) = i.destpair;
        if summary then
            nprintf(
                'AddDescription "%p" "%p"',
                [% summary, sys_fname_namev( name ) %]
            )
        endif
    endfor;
    cucharout( termin );
enddefine;

define make_contents_txt( alldata );
    dlocal cucharout = discout( 'CONTENTS.txt' );
    lvars i;
    for i in alldata do
        lvars ( name, summary ) = i.destpair;
        pr( name );
        sp( max( 4, 24 - name.datalength ) );
        npr( summary or nullstring );
    endfor;
    cucharout( termin );
enddefine;

define make_contents_html( data, cols, dir );
    dlocal cucharout = discout( 'CONTENTS.html' );
    npr( '<HTML>' );
    npr( '<HEAD><TITLE>Summary of Files</TITLE></HEAD>' );
    npr( '<BODY BGCOLOR="#FFF8E8">' );

    lvars L = split_string( dir, `/` ).consvector;
    nprintf( '<H1>Listing of package %p</H1>', [% L.last %] );

    npr( '<TABLE BORDER=1>' );
    lvars dat, col;
    for dat, col in_vector data, cols do
        nprintf( '<TR><TD COLSPAN=4 BGCOLOR="#DDDDFF"><STRONG><FONT SIZE=+1>%p</FONT></STRONG></TD></TR>', [% col %] );
        npr( '<TR BGCOLOR="#EEEEFF"><TH ALIGN=LEFT>filename</TH><TH ALIGN=LEFT>summary</TH><TH ALIGN=LEFT>docs</TH><TH ALIGN=LEFT>#lines</TH></TR>' );
        lvars i;
        for i in dat do
            lvars ( name, summary ) = i.destpair;
            summary or '&nbsp;' -> summary;         ;;; sort out Netscape table layout
            lvars helpfile = find_help_file( sys_fname_nam( name ) );
            lvars lineno = count_lines( name );
            nprintf(
                '<TR><TD><A HREF="%p">%p</A></TD><TD>%p</TD><TD>%p</TD><TD>%p</TD></TR>',
                [% name, name.sys_fname_name, summary, helpfile, lineno %]
            )
        endfor;
    endfor;
    npr( '</TABLE>' );

    npr( '</BODY>' );
    npr( '</HTML>' );
    cucharout( termin );
enddefine;

;;;
;;; Creates the documentation files
;;;     .htaccess, CONTENTS.html and CONTENTS.txt
;;; from the files in the auto & lib directories.
;;;
define make_readme( dir );
    dlocal current_directory = dir;
    lconstant cols = { 'auto' 'lib' };

    lvars data = mapdata( cols, make_data );
    lvars alldata = [% appdata( data, dl ) %];

    make_htaccess( alldata );
    make_contents_txt( alldata );
    make_contents_html( data, cols, dir );

enddefine;

;;;
;;; I have changed my mind several times about how the GOSPL
;;; home directory should be identified.  My current view is that
;;; the GOSPL ADMIN should be obliged to setup $popgospldev to
;;; avoid the necessity for a gospl user.
;;;
lvars file;
for file in_directory '$popgospldev/gospl/project-collection' do
    if file.sysisdirectory then
        make_readme( file )
    endif
endfor;
