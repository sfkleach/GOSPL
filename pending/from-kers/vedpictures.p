;;; vedpictures     Kers, HPLabs Bristol, October 1986
;;;
;;; This file provides simple picture-drawing facilities in Ved.
;;; Pictures are proper data-structures.
;;;
;;; Pictures. The picture primitives are -
;;;
;;;     hchars( chars )         Line with those characters
;;;     above( p1, p2 )         Picture with p1 above p2
;;;     beside( p1, p2 )        Picture with p1 left of p2
;;;     hcopies( n, char )      Picture with n horiz copies of char
;;;     vcopies( n, char )      Picture with n vert copies of char
;;;     hgap( n )               Horizontal n-space gap
;;;     vgap( n )               Vertical n-space gap
;;;
;;;     draw( p, h, v )         Draw p at h, v
;;;

compile_mode :pop11 +strict;

uses vedjumpto;
uses swopproc;

lconstant procedure jump_to = vedjumpto.swopproc;

define lconstant procedure put_char_saving( char ); lvars char;
    vedcurrentchar(), vedcolumn, vedline;
    vedcharinsert( char )
enddefine;

lvars put_char = vedcharinsert;

define lconstant procedure hput_char;
    put_char()
enddefine;

define lconstant procedure vput_char;
    put_char();
    vedchardownleft()
enddefine;

;;; These two are exported 'cos user procedures may need them.
;;;

constant procedure pic_widths = newproperty( [], 100, false, false );
constant procedure pic_depths = newproperty( [], 100, false, false );

;;; Multiple copies -------------------------------------

recordclass constant HCopy
    hcopyCount
    hcopyChar
    ;

define constant procedure hcopies( n, char ); lvars n char;
    lvars h = consHCopy( n, char );
    1 -> h.pic_depths;
    n -> h.pic_widths;
    h
enddefine;

procedure ( horiz, vert, pic ) with_props draw_hcopies;
    lvars horiz vert pic;
    lvars char = pic.hcopyChar;
    jump_to( horiz, vert );
    repeat pic.hcopyCount times char.hput_char endrepeat
endprocedure -> HCopy_key.class_apply;

recordclass constant VCopy
    vcopyCount
    vcopyChar
    ;

define constant procedure vcopies( n, char ); lvars n char;
    lvars v = consVCopy( n, char );
    n -> v.pic_depths;
    1 -> v.pic_widths;
    v
enddefine;

procedure ( horiz, vert, pic ) with_props draw_vcopies;
    lvars horiz vert pic;
    lvars char = pic.vcopyChar;
    jump_to( horiz, vert );
    repeat pic.vcopyCount times char.vput_char endrepeat
endprocedure -> VCopy_key.class_apply;

;;; Gaps ------------------------------------------------

recordclass constant VGap
    vgapN
    ;

define constant procedure vgap( n ); lvars n;
    lvars v = consVGap( n );
    0 -> v.pic_widths;
    n -> v.pic_depths;
    v
enddefine;

procedure ( horiz, vert, pic ) with_props draw_vgap;
    lvars horiz vert pic;
endprocedure -> VGap_key.class_apply;

recordclass constant HGap
    hgapN
    ;

define constant procedure hgap( n ); lvars n;
    lvars h = consHGap( n );
    n -> h.pic_widths;
    0 -> h.pic_depths;
    h
enddefine;

procedure ( horiz, vert, pic ) with_props draw_hgap;
    lvars horiz vert pic;
endprocedure -> HGap_key.class_apply;

;;; Above -----------------------------------------------

recordclass constant Above
    aboveP1
    aboveP2
    ;

define constant procedure above( p1, p2 ); lvars p1 p2;
    lvars a = consAbove( p1, p2 );
    p1.pic_depths + p2.pic_depths -> a.pic_depths;
    max( p1.pic_widths, p2.pic_widths ) -> a.pic_widths;
    a
enddefine;

procedure ( horiz, vert, pic ) with_props draw_above;
    lvars horiz vert pic;
    (pic.aboveP1)( horiz, vert );
    (pic.aboveP2)( horiz, vert + pic.aboveP1.pic_depths )
endprocedure -> Above_key.class_apply;

;;; Beside ----------------------------------------------

recordclass constant Beside
    besideP1
    besideP2
    ;

define constant procedure beside( p1, p2 ); lvars p1 p2;
    lvars b = consBeside( p1, p2 );
    p1.pic_widths + p2.pic_widths -> b.pic_widths;
    max( p1.pic_depths, p2.pic_depths ) -> b.pic_depths;
    b
enddefine;

procedure ( horiz, vert, pic ) with_props draw_beside;
    lvars horiz vert pic;
    (pic.besideP1)( horiz, vert );
    (pic.besideP2)( horiz + pic.besideP1.pic_widths, vert );
endprocedure -> Beside_key.class_apply;

;;; HChars -----------------------------------------------------------------

recordclass constant HChars
    hcharsChars
    ;

define constant procedure hchars( chars ); lvars chars;
    lvars p = consHChars( chars );
    chars.length -> p.pic_widths;
    1 -> p.pic_depths;
    p
enddefine;

procedure ( horiz, vert, pic ) with_props draw_hchars;
    lvars horiz vert pic;
    jump_to( horiz, vert );
    appdata( pic.hcharsChars, hput_char )
endprocedure -> HChars_key.class_apply;

;;; Drawing steering --------------------------------------------------------

define constant procedure draw( pic, horiz, vert ); lvars pic horiz vert;
    dlocal vedstatic = true;
    vedcharinsert -> put_char;
    pic( horiz, vert )
enddefine;

define lconstant procedure restore_pic();
    until dup() == popstackmark do
        jump_to(); vedcharinsert()
    enduntil;
    erase()
enddefine;

define constant procedure draw_exec_restore( proc, pic, horiz, vert );
    lvars proc pic horiz vert;
    dlocal vedstatic = true;
    put_char_saving -> put_char;
    popstackmark;
    pic( horiz, vert );
    proc();
    restore_pic();
enddefine;

;;;
;;; A definition for "uses" to use
;;;

constant vedpictures = true;
