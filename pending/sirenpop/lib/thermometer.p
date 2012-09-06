compile_mode :pop11 +strict;

section;

global vars thermometer = true;     ;;; make work with uses.

lconstant
    THERMOMETER_WIDTH = 400,
    THERMOMETER_HEIGHT = 25,
    THERMOMETER_FG = 'red',
    THERMOMETER_BG = 'blue';

defclass lconstant thermometer {
    thermometerTop      : full,
    thermometerPopup    : full,
    thermometerFrame    : full,
    thermometerRowCol   : full,
    thermometerLabel    : full,
    thermometerGraphic  : full,
    thermometerLevel    : float,
};

define global new_thermometer( title ); lvars title;

    lvars xxx = xt_new_top_level_shell( 'thermometer' );

    lvars www =
        xt_new_popup_shell(
            xxx,
            { background 'yellow' },
            { overrideRedirect ^true },
            { allowShellResize ^true },
            { x 400 },
            { y 350 }
        );
    lvars frame =
        xt_new_frame(
            www,
            { shadowType ^XmSHADOW_ETCHED_OUT },
            { shadowThickness 6 },
            false   ;;; inhibit management
        );
    lvars rc = xt_new_row_column( frame, { background 'gray60' } );
    lvars label = xt_newg_label_f( rc, title.to_string, [] );
    lvars graphic =
        xt_new_graphic(
            rc,
            { width ^THERMOMETER_WIDTH },
            { height ^THERMOMETER_HEIGHT },
            { background ^THERMOMETER_BG }
        );

    XtRealizeWidget( www );

    consthermometer( xxx, www, frame, rc, label, graphic, 0 )
enddefine;

define global thermometer_label( th ); lvars th;
    thermometerLabel( th )( "labelString" )
enddefine;

define updaterof thermometer_label( str, th ); lvars str, th;
    str.to_string -> thermometerLabel( th )( "labelString" )
enddefine;

define global thermometer_level( th ); lvars th;
    thermometerLevel( th )
enddefine;

define updaterof thermometer_level( r, th ); lvars r, th;
    r -> thermometerLevel( th );
    lvars width = thermometerGraphic( th )( "width" );
    lvars height = thermometerGraphic( th )( "height" );
    lvars n = round( width * r );
    lvars g = th.thermometerGraphic;

    XpwSetColor( g, THERMOMETER_FG ).erase;
    XpwFillRectangle( g, 0, 0, n, THERMOMETER_HEIGHT );
    XpwSetColor( g, THERMOMETER_BG ).erase;
    XpwFillRectangle( g, n, 0, width - n, THERMOMETER_HEIGHT );
enddefine;

include xt_constants
define global show_thermometer( th ); lvars th;
    XtManageChild( th.thermometerFrame );
    0 -> thermometer_level( th );
enddefine;

define global hide_thermometer( th ); lvars th;
    XtUnmanageChild( th.thermometerFrame )
enddefine;

endsection;
