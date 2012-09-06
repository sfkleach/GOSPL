;;; Defines:
;;;
;;;     picture_tree( tree ) -> picture_of_tree
;;;     vidtree( tree )  { Draws picture in buffer BEETLE }
;;;
;;; Uses:
;;;     uses vedpictures, fold
;;;     procedure isleaf, root, daughters
;;;


compile_mode :pop11 +strict;

vars
    procedure isleaf = atom,
    procedure root = hd,
    procedure daughters = tl
    ;

vars
    vspace = 5
    ;

uses vedpictures;
uses fold;

;;; ----------------------------------------------------------
;;; Now tree-drawing itself ----------------------------------

define lconstant as_chars( x ); lvars x;
    if x.isword or x.isstring then x else x >< '' endif
enddefine;

define lconstant above_with_gap( p1, p2 ); lvars p1 p2;
    lconstant gap = vgap( 1 );
    above( p1, above( gap, p2 ) )
enddefine;

define lconstant beside_with_gap( p1, p2 ); lvars p1 p2;
    lconstant gap = hgap( 1 );
    beside( p1, beside( gap, p2 ) )
enddefine;

lconstant top_offsets = newproperty( [], 100, 0, false );
lconstant bot_offsets = newproperty( [], 100, 0, false );

define lconstant beside_balanced( p1, p2 ); lvars p1 p2;
    ;;; Tries to balance the vertical heights of p1 and p2
    lvars v1 = p1.pic_depths, v2 = p2.pic_depths;
    lvars interval = abs( v1 - v2);
    lvars gap_size = interval.abs div 2, gap = gap_size.vgap;
    if v1 > v2 then
        beside( p1, above( gap, p2 ) )
    elseif v1 < v2 then
        lvars x = beside( above( gap, p1 ), p2 );
        gap_size -> x.top_offsets;
        interval - gap_size -> x.bot_offsets;
        x
    else
        beside( p1, p2 )
    endif
enddefine;

define lconstant enclose_in_box( pic ); lvars pic;
    lvars d = pic.pic_depths, w = pic.pic_widths;
    lvars hyphens = hcopies( w + 2, `-` );
    lvars bars = vcopies( d, `|` );
    above
        (
        hyphens,
        above
            (
            beside( bars, beside( pic, bars ) ),
            hyphens
            )
        )
enddefine;

define lconstant picture_label( label ); lvars label;
    lvars inside =
        if label.ispair then
            fold above over maplist( label, as_chars pdcomp hchars ) endfold
        else
            label.as_chars.hchars
        endif;
    inside.enclose_in_box
enddefine;

define picture_tree( tree ); lvars tree;
    if tree.isleaf then
        tree.as_chars.hchars
    else
        lvars ds = tree.daughters;
        lvars label = tree.root.picture_label;
        if ds == [] then
            label
        else
            lvars pds = maplist( ds, picture_tree );
            lvars pd = fold above_with_gap over pds endfold;
            lvars fd = pds.first, ld = pds.last;
            lvars vline =
                above
                    (
                    vgap( fd.top_offsets ),
                    vcopies( pd.pic_depths - fd.top_offsets - ld.bot_offsets, `|` )
                    );
            beside_balanced
                (
                beside( label, hgap(1) ),
                beside( vline, pd )
                )
        endif
    endif
enddefine;

define vedtree( tree ); lvars tree;
    vedselectbuffer( 'BEETLE' );
    ved_clear();
    draw( tree.picture_tree, 1, 1 )
enddefine;
