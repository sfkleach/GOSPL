
/*
new_list_box(name) -> list_box

In all the following procedures,

is_list_box(item) -> bool
kill_list_box(list_box)

listBoxItems(________list_box) -> ___vec
___vec -> listBoxItems(________list_box)
    ___vec is a vector of list items, which are either strings, dstrings
    or vectors. If they are vectors, then the item can contain strings,
    font names or color names. For example:

        {'A' 'B' 'C'} -> list_box.listBoxItems;

        {'A' {'A' _helvetica_14_b 'B'} 'C'} -> list_box.listBoxItems;

        {'A' '\{b}B\{i}C' 'D'} -> list_box.listBoxItems;

    ___vec can also be a list, or an integer specifying a number of items
    on the stack.


listBoxValue(list_box) -> n
n -> listBoxValue(list_box)
    The index for the currently selected item, or false if nothing
    is selected.

listBoxVisibleItemCount(list_box) -> n
    How many things are visible in the list.

listBoxTop(list_box) -> n
n -> listBoxTop(list_box)
    The index of the item that is shown at the top of the list box.

listBoxFont(list_box) -> font
font -> listBoxFont(list_box)
    The font for items in the list.

reformat_listbox( list_box )
    Recalibrates a particular list box.

ENTER listbox [<name>]
    Recallibrates all list boxes on the current scene.
    If given a name argument, this creates a new list box called <name>

hipActivate
    This message is sent to a list box when an item is double
    clicked on.
*/

section $-list_box =>
    new_list_box
    is_list_box
    kill_list_box

    listBoxItems
    listBoxTop
    listBoxVisibleItemCount
    listBoxValue
    listBoxFont

    listBoxChildren
    listBoxDrawing
    listBoxSlider
    listBoxButton

    ved_listbox
    reformat_listbox
;

compile_mode :pop11 +strict;

lconstant SLIDER_SUFFIX = "_SLIDER";
lconstant BUTTON_SUFFIX = "_BUTTON";

defclass _lb_data {
    lb_items,
    lb_value,
    lb_top,
    lb_visible_items,
    lb_font,
};

/* ---- INTERNAL ROUTINES */

define list_box_data = hip_value(%"listBoxData", true%) enddefine;

define try_get_list_box_data(item); lvars item;
    item.hip_is_drawing and hip_has_property(item, "listBoxData")
        and list_box_data(item)
enddefine;

define check_name(list_box) -> list_box;
    lvars list_box;
    if list_box.isword then
        lvars c = hip_get(list_box, hip_system.hipCurrentScene);
        unless c then
            hip_get(list_box, hip_system.hipCurrentBackground) -> c;
        endunless;
        if c then c -> list_box; endif;
    endif;
enddefine;

define is_list_box
    = check_name <> try_get_list_box_data <> is_lb_data;
enddefine;

define get_list_box_data(list_box) -> data;
    lvars list_box, data = try_get_list_box_data(list_box);

    unless data.is_lb_data then
        mishap(list_box, 1, 'LIST BOX NEEDED');
    endunless;
enddefine;


define list_box_children(list_box) -> (drawing, slider, button);
    lvars list_box, drawing, slider, button;

    list_box -> drawing;

    hip_get(list_box.hipName <> SLIDER_SUFFIX, list_box.hipParent) -> slider;

    unless slider then
        mishap(list_box, 1, 'BROKEN LIST BOX (has no slider)');
    endunless;

    hip_get(list_box.hipName <> BUTTON_SUFFIX, list_box.hipParent) -> button;

    unless button then
        mishap(list_box, 1, 'BROKEN LIST BOX (has no background button)');
    endunless;

enddefine;

define listBoxDrawing( lb ); lvars lb;
    lb.get_list_box_data and lb
enddefine;

define listBoxSlider( lb ); lvars lb;
    lvars ( d, s, b ) = list_box_children( lb );
    s
enddefine;

define listBoxButton( lb ); lvars lb;
    lvars ( d, s, b ) = list_box_children( lb );
    b
enddefine;

define listBoxChildren( lb ); lvars lb;
    list_box_children( lb )
enddefine;

define refresh_or_pick(list_box, pick, refresh) -> found;
    lvars list_box, pick, refresh, found = false;

    lvars data = get_list_box_data(list_box);
    lvars (drawing, _ , _ ) = list_box_children(list_box);

    lvars (text, seln, L, _, font) = data.explode;
    lvars (_, typeface, size, _) = hip_dest_font (font);


    lvars drawing_width  = drawing.hipWidth;
    lvars drawing_height = drawing.hipHeight;

    lvars y = 0, i, n_lines = 0;

    #|
        hip_do_font(hip_new_font(false, typeface, size, 0));
        hip_do_pen_style("dot");
        hip_do_fill_color(false);

        for i from max(1, L) to length(text) do
            lvars line = subscrv(i, text);
            lvars width, height, base;

            if line.isdstring then
                {%
                    lvars c, attr = 0, stacked = 0;
                    appdata(line, procedure(c); lvars c;
                            lvars c_attr = c && `\[bi]`;
                            if c_attr /== attr then
                                if stacked /== 0 then
                                    consstring(stacked);
                                    0 -> stacked;
                                endif;
                                c_attr -> attr;
                                hip_new_font(false, typeface, size,
                                    (attr &&/=_0 `\[b]` and 1 or 0) ||
                                    (attr &&/=_0 `\[i]` and 2 or 0));
                            endif;
                            c && 16:FF; stacked + 1 -> stacked;
                        endprocedure);
                    if stacked /== 0 then
                        consstring(stacked);
                    endif;
                    %} -> line;
            endif;

            if i == seln then
                hip_do_save();
            endif;

            define lconstant show_seln(y, height); lvars y, height;
                if i == seln then
                    hip_do_fill_color(drawing.hipPenColor);
                    hip_do_pen_color(false);
                    hip_do_rect(0, y, drawing_width, y + height);
                    hip_do_pen_color(drawing.hipFillColor);
                endif;
            enddefine;

            lconstant PAD = 20;

            if line.isvector then
                hip_do_save();

                lvars str, x = 0;
                lvars part;
                lvars f = font;
                lvars mascent = 0, mdescent = 0;

                for part in_vector line do
                    if part.isstring then
                        hip_string_extents(f, part) -> (width, height, base);
                        max(base, mascent) -> mascent;
                        max(height - base, mdescent) -> mdescent;
                    elseif part.isword then
                        part -> f;
                    endif;
                endfor;

                lvars mheight = mascent + mdescent;

                show_seln(y, mheight);

                for part in_vector line do
                    if part.isstring then
                        hip_string_extents(f, part) -> (width, height, base);
                        lvars top = y + mascent - base;
                        hip_do_label(x, top, x+width + PAD, top + height, part, "beginning");
                        x + width -> x;
                    elseif part.isword and part.hip_is_font then
                        part -> f;
                        hip_do_font(f);
                    elseif part.isinteger or part.isword then
                        hip_do_pen_color(part);
                    endif;
                endfor;
                mascent -> base;
                mheight -> height;
                hip_do_restore();
            elseif line.isstring then
                hip_string_extents(font, line) -> (width, height, base);
                show_seln(y, height);
                hip_do_label(0, y, width + PAD, y + height, line, "beginning");
            else
                mishap( 'INVALID LISTBOX ITEM', [ ^line ] )
            endif;

            if i == seln then
                hip_do_restore();
            endif;

            if pick and pick >= y and pick <= y + height then
                i -> found;
            endif;
            y + height -> y;

            quitif(y >= drawing_height);

            n_lines + 1 -> n_lines;
        endfor;
        0 |#;

    if refresh then
        -> drawing.hipDrawData;
        n_lines ->> data.lb_visible_items -> found;
    else
        erasenum();
    endif;
enddefine;

define refresh_list_box(list_box); lvars list_box;
    lvars (drawing, slider, _) = list_box_children(list_box);
    lvars n_lines = refresh_or_pick(drawing, false, true);
    n_lines -> slider.hipSliderSize;
enddefine;

/* ---- USER PROPERTIES */

define listBoxItems(list_box); lvars list_box;
    lvars data = get_list_box_data(check_name(list_box) ->> list_box);
    data.lb_items;
enddefine;

define updaterof listBoxItems(vec, list_box);
    lvars vec, list_box;

    lvars data = get_list_box_data(check_name(list_box) ->> list_box);
    lvars (drawing, slider, button) = list_box_children(list_box);

    if vec.islist then
        vec.destlist.consvector -> vec;
    elseif vec.isinteger then
        consvector(vec) -> vec;
    endif;

    vec -> data.lb_items;
    false -> data.lb_value;
    1   -> data.lb_top;

    refresh_list_box(list_box);

    0 -> slider.hipValue;

    if length(vec) == 0 then
        1 -> slider.hipMaximum;
        1 -> slider.hipSliderSize;
    else
        length(vec) -> slider.hipMaximum;
    endif;
enddefine;

define listBoxValue(list_box); lvars list_box;
    check_name(list_box) -> list_box;
    lvars data = get_list_box_data(list_box);
    data.lb_value;
enddefine;

define updaterof listBoxValue(n, list_box);
    lvars n, list_box;

    check_name(list_box) -> list_box;

    lvars data = get_list_box_data(list_box);
    lvars (drawing, slider, button) = list_box_children(list_box);

    n -> data.lb_value;
    refresh_list_box(drawing);
enddefine;

define listBoxTop(list_box); lvars list_box;
    check_name(list_box) -> list_box;
    lvars data = get_list_box_data(list_box);
    data.lb_top;
enddefine;

define updaterof listBoxTop(n, list_box); lvars n, list_box;
    check_name(list_box) -> list_box;
    lvars data = get_list_box_data(list_box);

    lvars n_items = data.lb_items.length;

    returnif (n_items == 0);

    fi_check(n, 1, n_items) -> n;

    max(1, min(n, n_items) - data.lb_visible_items + 1) -> data.lb_top;
    refresh_list_box(list_box);

    lvars ( _ , slider, _ ) = list_box_children(list_box);
    data.lb_top - 1 -> slider.hipValue;
    data.lb_visible_items -> slider.hipSliderSize;
enddefine;

define listBoxVisibleItemCount(list_box); lvars list_box;
    list_box_data(list_box.check_name).lb_visible_items;
enddefine;

define listBoxFont(list_box); lvars list_box;
    list_box_data(list_box.check_name).lb_font;
enddefine;
define updaterof listBoxFont(f, list_box); lvars f, list_box;
    check_name(list_box) -> list_box;
    f -> list_box_data(list_box).lb_font;
    refresh_list_box(list_box);
enddefine;

/* ---- UTILITY PROCEDURES */

define reglue_list_box(list_box); lvars list_box;
    lvars (drawing, slider, button) = list_box_children(list_box);

    "device" -> drawing.hipInitialUnits;
    0 -> drawing.hipMarginLeft;
    0 -> button.hipHighlightThickness;
    2 -> button.hipShadowThickness;
    0 -> slider.hipHighlightThickness;
    2 -> slider.hipShadowThickness;

    true -> drawing.hipOpaque;

    lvars (pen, fil) = (drawing.hipPenColor, drawing.hipFillColor);
    fil -> drawing.hipDrawFillColor;
    pen -> button.hipPenColor;
    fil -> button.hipFillColor;
    fil -> slider.hipFillColor;

    lvars (x, y, width, height) = drawing.hip_coords;

    x + width + 4, y - 4, false, height + 8 -> slider.hip_coords;
    x - 4, y - 4, width + 8, height + 8 -> button.hip_coords;

    drawing.hipLayer - 1 -> slider.hipLayer;
    drawing.hipLayer - 2 -> button.hipLayer;
enddefine;

define list_box_from_child(child) -> list_box; lvars child, list_box;
    lvars name;
    if child.hip_is_slider and (child.hipName ->> name).isword
            and isendstring(SLIDER_SUFFIX, name) then
        allbutlast(length(SLIDER_SUFFIX), name) -> name;
    elseif child.hip_is_button and (child.hipName ->> name).isword
            and isendstring(BUTTON_SUFFIX, name) then
        allbutlast(length(BUTTON_SUFFIX), name) -> name;
    elseif child.is_list_box then
        return(child -> list_box);
    else
        mishap(child, 1, 'NOT A LIST BOX CHILD');
    endif;

    hip_get(name, child.hipParent) -> list_box;
    unless list_box.is_list_box then
        mishap(child, 1, 'CANNOT FIND LIST BOX FOR CHILD');
    endunless;
enddefine;

lvars last_item = false;

define list_box_pick(me, event); lvars me, event;
    lvars list_box = me.list_box_from_child;
    lvars val = refresh_or_pick(list_box, event.hipY - me.hipY, false);
    val -> listBoxValue(list_box);

    if event.hipMouseClickCount == 1 then
        if val and last_item == val then
            hipActivate(list_box, val);
        endif;
    else
        val -> last_item;
    endif;
enddefine;

define list_box_slide(me); lvars me;
    lvars list_box = me.list_box_from_child;
    lvars data = get_list_box_data(list_box);
    lvars n = me.hipValue + 1;

    max(1, min(n, length(data.lb_items) - data.lb_visible_items + 1))
        -> data.lb_top;
    refresh_list_box(list_box);
enddefine;

lconstant SLIDER_SCRIPT = '\
define :hip_handler hipSlide(me); \
    $-list_box$-list_box_slide(me);\
enddefine; \
define :hip_handler hipChangeValue(me);\
    $-list_box$-list_box_slide(me);\
enddefine; \
';

lconstant DRAWING_SCRIPT = '\
define :hip_handler hipRelease(me, event);\
    $-list_box$-list_box_pick(me, event);\
enddefine; \
';

define new_list_box(name) -> drawing;
    lvars name;

    lvars drawing = hip_new_drawing([
        hipName ^name
        hipScript ^DRAWING_SCRIPT
      ]);

    lvars slider = hip_new_slider([
        hipName ^(name <> SLIDER_SUFFIX)
        hipWidth 20
        hipScript ^SLIDER_SCRIPT
        hipShowRecessed ^false
        hipSliderSize 100
      ]);

    lvars button = hip_new_button([
        hipName ^(name <> BUTTON_SUFFIX)
        hipButtonType label
        hipValue ^true
        hipFillOnArm ^false
      ]);

    hip_add_property(drawing, "listBoxData", false);

    cons_lb_data(nullvector, false, 1, 0, "_helvetica_14_")
        -> list_box_data(drawing);
    reglue_list_box(drawing);
    nullvector -> listBoxItems(drawing);
enddefine;

define kill_list_box(list_box); lvars list_box;
    check_name(list_box) -> list_box;
    applist([% list_box_children(list_box) %], hip_kill);
enddefine;

define reformat_listbox( it ); lvars it;
    reglue_list_box( it );
    refresh_list_box( it );
    it.listBoxItems -> it.listBoxItems;
enddefine;

define ved_listbox();
    if vedargument = nullstring then
        dlvars count = 0;
        hip_app_children(
            hip_system.hipScene,
            procedure(c); lvars c;
                if c.is_list_box then
                    count + 1 -> count;
                    reformat_listbox( c )
                endif;
            endprocedure
        );
        vedputmessage( 'ALL (' >< count >< ') LIST BOXES ON THIS SCENE REGLUED' );
    else
        lvars name = consword( vedargument );
        lvars it = hip_get( name, hip_system.hipScene );
        if it then
            reformat_listbox( it );
            vedputmessage( 'LISTBOX ' <> vedargument <> ' REGLUED' );
        else
            new_list_box( name ).erase;
            vedputmessage( 'NEW LISTBOX ' <> vedargument <> ' CREATED' );
        endif
    endif;
enddefine;

endsection;
