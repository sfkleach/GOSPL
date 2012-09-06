section;

;;; compile_latex.p                R.J.Popplestone, MAR92

/*
The code below will, for any file with the extension '.tex'
call Latex to process the file and present it using xdvi
Please copy and distribute.
*/

vars procedure( finish_file, show_dvi );

define compile_latex( repin ); lvars repin;
    lvars
        FileName_tex = systmpfile(false,'latex_poplog','.tex'),
        n            = length(FileName_tex),
        FileName_dvi = substring(1,n-3,FileName_tex) <> 'dvi',
        c,
        repout       = discout(FileName_tex),
        is_lmr       = member(ved_lmr,syscallers()),   ;;; Are we called from lmr?
        ;


    while ( repin() -> c; c /== termin ) do
        repout( c );
    endwhile;
    repout( termin );

    ;;;  if is_lmr then finish_file(FileName_tex)
    ;;;  endif;

    sysobey( 'cd /tmp\nlatex '<> FileName_tex, `%` );
    sysobey( 'cd /tmp\nxdvi ' <> FileName_dvi <> '&', `%` );
    vedrefresh();
enddefine;

[
    ['.tex' {popcompiler compile_latex}]
    ['.tex' {vedcompileable true}]
] <> vedfiletypes -> vedfiletypes;

define show_dvi();
    sysobey( 'xdvi ' <> vedcurrent <> '&' );
    exitto( veddocommand );
enddefine;

if popunderx then
    [['.dvi' ^show_dvi]] <> vedfiletypes -> vedfiletypes;
endif;


define show_ps();
    sysobey( 'dxpsview -geometry 500x600 ' <> vedcurrent <> '&' );
    exitto( veddocommand );
enddefine;

if popunderx then
    [['.ps' ^show_ps]] <> vedfiletypes -> vedfiletypes;
endif;


define show_idraw();
    sysobey( 'dxpsview -geometry 500x600 ' <> vedcurrent <> '&' );
    exitto( veddocommand );
enddefine;

if popunderx then
    [['.idraw' ^show_ps]] <> vedfiletypes -> vedfiletypes;
endif;


define show_obj();
    lvars FileName = systmpfile( false, vedcurrent, '.txt' );
    sysobey( 'nm '<> vedcurrent <> ' > ' <> FileName );
    FileName -> vedcurrent;
enddefine;


[['.o' ^show_obj]] <> vedfiletypes -> vedfiletypes;

endsection;
