;;; So this works with -uses- (YUK)
vars table = true;

/*

Tables
------
newtable() -> table

set_table_children(table, drawing, horiz_slider, vert_slider)
        Sets up the objects used by the table

resize_table(table)
        Recomputes the geometries of the table.

redraw_table(table)
        Redraws the table in the table drawing.

table(r, c) -> value
value -> table(r, c)
        Sets or retrieves the value of an entry in the table

table_row(table) -> row
row -> table_row(table)
        The row that is displayed at the top left corner of the table.

table_col(table) -> col
col -> table_col(table)
        The column that is displayed at the top left corner of the table.

table_x(table) -> x
x -> table_x(table)
        The X pixel coordinate of the top left corner of the table data.
        Updating this effects table_col.

table_y(table) -> y
y -> table_y(table)
        The Y coordinate of the top left corner of the table data.
        Updating this effects table_row.

table_width(table) -> npixels
table_height(table) -> npixels
        The size of the table data in pixels

the_fill(table) -> color
color -> the_fill(table)
        The background color of the table

the_pen(table) -> color
color -> the_pen(table)
        The text color of the table

the_font(table) -> color
color -> the_font(table)
        The default font of the table.
        Call resize_table after changing this.

the_alignment(table) -> beginning|center|end
beginning|center|end -> the_alignment(table)

table_cells(table) -> array
        Array of table cells

table_grid_pen(table) -> color
color -> table_grid_pen(table)
        Color of grid lines, or false to turn off grid

    /* information about rows and colums */
    slot table_row_spine = newspine();
    slot table_col_spine = newspine();

    /* min_width max_width min_height max_height column_spacing row_spacing */
    slot table_cell_bounds == {40 200 12 300 10 4};

    /* the current top left cell */
    slot table_col == 1;
    slot table_row == 1;

table_data(table) -> cels
vector -> table_data(table)

Spines
------
There are two spines per table, the

    table_row_spine(table) -> row_spine
        (a vertical spine for row headings) and
    table_col_spine(table) -> col_spine
        (a horizontal spine for column headings)

;;; global settings
the_fill(spine) -> color
the_pen(spine) -> color
the_font(spine) -> color
the_alignment(spine) -> beginning|center|end

;;; setting the labels along a spine
spine_labels(spine) -> vector
vector -> spine_labels(spine)

;;; once you have set the labels, spine_cells is available
spine_cells(spine) -> vector_of_cells

Cells
-----
Each entry in the table is held in a cell. Also, the row and
columns spines have a vector of cells holding the labels for
the rows/columns.

table(r,c) -> value
value -> table(r,c)

To get a cell:

    table.table_data -> cells
    cells(r, c) -> cell

    or

    table.table_row_spine.spine_cells -> cells
    cells(n) -> cell

    or

    table.table_col_spine.spine_cells -> cells
    cells(n) -> cell

Spell slots:

the_fill(cell) -> color_or_false
the_pen(cell) -> color_or_false
the_font(cell) -> color_or_false
the_alignment(cell) -> beginning|center|end

cell_value(cell) -> value
value -> cell_value(cell)

*/

section;
compile_mode :pop11 +strict;

lvars do_redraw = true;

constant procedure (resize_table, redraw_table);

define t_access_slot = apply(%%); enddefine;

define :method the_table(t); t; enddefine;

define :generic table_resize_needed; enddefine;

define updaterof t_access_slot(val, inst, p);
    lvars val, inst, p;

    apply(val, inst, p);

    if do_redraw then
        redraw_table(inst.the_table);
    endif;
enddefine;

p_typespec Bool :byte#XptCoerceBoolean;

define :mixin table_format;
    ;;; beginning, center, end (false to use default)
    slot the_alignment == false;

    ;;; font, or false to use default
    slot the_font == false;

    ;;; pen and fill colors, or false to use default
    slot the_pen  == false;
    slot the_fill == false;
enddefine;

define table_broken(i); lvars i;
    dlocal do_redraw = false;
    true -> i.the_table.table_resize_needed;
enddefine;

/*
define :wrapper updaterof the_font(val, inst:table_format, p);
    table_broken(inst);
    apply(val, inst, p);
enddefine;
*/

;;; an entry in the table
define :class cell;
    isa table_format;

    ;;; what the user assigned to the cell
    slot cell_value == false;
    slot cell_table == false;

    ;;; printed version of the value
    slot cell_string == nullstring;

    ;;; size of the printed version of the value
    slot cell_width :ushort == 0;
    slot cell_height :ushort == 0;

    ;;; whether cell is drawn or not
    slot cell_visible :Bool == true;

    ;;; is the cell_string/cell_width/cell_height out of date?
    slot cell_dirty :Bool == true;

    ;;; set to true if any of the following settings are non-default
    slot cell_fancy :Bool == false;
enddefine;

/*
define :wrapper updaterof cell_value(val, inst:cell, p);
    procedure;
        dlocal do_redraw = false;
        true -> inst.cell_dirty;
        table_broken(inst);
    endprocedure();

    apply(val, inst, p);
enddefine;
*/

define :method the_table(c:cell);
    c.cell_table;
enddefine;

;;; this holds information about the whole row or the whole column
define :class spine;
    isa table_format;

    slot the_fill == "yellow";
    slot the_pen == "black";
    slot the_font == "_helvetica_14_";
    slot the_alignment == "center";

    ;;; pointer to my table
    slot spine_table == false;

    ;;; a vector of cells, one for each row/col
    slot spine_cells == false;


    ;;; the width of a row spine, the height of a column spine
    slot spine_size == 0;

    ;;; a vector of widths for a col spine, or heights for a row spine
    slot spine_sizes == false;

    on access do t_access_slot;
enddefine;

define :method the_table(s:spine);
    s.spine_table;
enddefine;

define :class table;
    isa table_format;

    slot table_cells == false;

    /* defaults for items in the table */
    slot the_font == "_times_14_";
    slot the_alignment == "beginning";
    slot the_fill == "gray";
    slot the_pen == "black";

    /* pointers to hip objects */
    slot table_drawing == false;
    slot table_hbar == false;
    slot table_vbar == false;

    slot table_resize_needed == true;

    /* defaults for grid */
    slot table_grid_pen == "gray";

    /* information about rows and colums */
    slot table_row_spine = newspine();
    slot table_col_spine = newspine();

    /* min_width max_width min_height max_height column_spacing row_spacing */
    slot table_cell_bounds == {40 200 12 300 10 4};

    /* if this is true, table rows/cols expand/contract to fit largest items */
    slot table_autofit == true;

    /* the current top left cell */
    slot table_col == 1;
    slot table_row == 1;

    /* number of rows/cols in the table */
    slot table_num_rows == 0;
    slot table_num_cols == 0;

    /* number that are currently visible */
    slot table_shown_rows == 0;
    slot table_shown_cols == 0;

    /* a pixel-wise shift */
    slot table_x_shift == 0;
    slot table_y_shift == 0;

    /* how big the table is (pixels) */
    slot table_width == 0;
    slot table_height == 0;

    /* this is the how big to make cells that off the edge of the table */
    slot table_grid_width, table_grid_height;

    on new do procedure(p) -> inst; lvars p, inst;
        apply(p) -> inst;
        inst -> inst.table_col_spine.spine_table;
        inst -> inst.table_row_spine.spine_table;
    endprocedure;

    on access do t_access_slot;
enddefine;

define :method spine_labels(i);
    i.spine_cells and {%
        lvars cell;
        for cell in_vector i.spine_cells do
            cell.cell_value;
        endfor;
    %}
enddefine;

define :method updaterof spine_labels(val, i);
    dlocal do_redraw = false;

    lvars table = i.spine_table;
    val and {%
        lvars label;
        for label in_vector val do
            lvars cell = newcell();
            table -> cell.cell_table;
            label -> cell.cell_value;
            cell;
        endfor;
    %} -> i.spine_cells;

    true -> table.table_resize_needed;
    redraw_table(table);
enddefine;

define lconstant vector_to_cells(table, vector) -> cells;
    lvars table, vector, procedure cells;

    lvars i, j, nrows = length(vector), ncols = 0, row;

    for row in_vector vector do
        max(ncols, length(row)) -> ncols;
    endfor;

    newanyarray([1 ^nrows 1 ^ncols], false, vector_key) -> cells;

    for i from 1 to length(vector) do
        vector(i) -> row;
        for j from 1 to length(row) do
            lvars data = row(j);
            if data == undef or data == nullstring then
                nextloop;
            else
                lvars cell = newcell();
                table -> cell.cell_table;
                data -> cell.cell_value;
                cell -> cells(i, j);
            endif;
        endfor;
    endfor;
enddefine;

define lconstant cells_bounds(cells); lvars cells;
    lvars (_, rows, _, cols) = explode(cells.boundslist);
    rows, cols;
enddefine;

define :method table_data(i); lvars i;
    ;;; oops
    i.table_cells;
enddefine;

define :method updaterof table_data(val, i);
    dlocal do_redraw = false;

    vector_to_cells(i, val) -> i.table_cells;
    true -> i.table_resize_needed;
    redraw_table(i);
enddefine;

define lconstant incharline( r ); lvars procedure r;
    lconstant terminator = identfn(% termin %);
    procedure();
        lvars count = 0;
        repeat
            lvars c = r();
            if c == `\n` do
                consstring(count);
                quitloop
            elseif c == termin do
                if count == 0 then
                    termin
                else
                    consstring(count);
                    terminator -> r;
                endif;
                quitloop
            else
                c; 1 fi_+ count -> count
            endif;
        endrepeat;
    endprocedure
enddefine;

#_IF not(DEF string_extents)

loadinclude xpt_xfontstruct.ph;
XptLoadProcedures 'table' lvars XTextWidth;

lvars last_f = false, last_fs, last_str, last_width, last_height;

define lconstant string_extents(f, str); lvars f, str;
    lvars width, height, base, fs;

    if f == last_f then
        if str = last_str then
            return(last_width, last_height)
        endif;
        last_fs
    else
        f -> last_f;
        simplefont_to_XFontStruct(XptDefaultDisplay, f) ->> last_fs
    endif -> fs;

    if locchar(`\n`, 1, str) then
        procedure(r); lvars r, item;
            lvars mwidth = 0, mheight = 0;
            fast_for item from_repeater r do
                lvars (w, h) = string_extents(f, item);
                fi_max(w, mwidth) -> mwidth;
                h fi_+ mheight -> mheight;
            endfast_for;
            mwidth, mheight;
        endprocedure(str.stringin.incharline) -> (last_width, last_height);
    else
        exacc (3):int raw_XTextWidth(fs, str, datalength(str)) -> last_width;
        exacc :XFontStruct fs.ascent fi_+ exacc :XFontStruct fs.descent
            -> last_height;
    endif;

    last_width, last_height;
enddefine;

#_ENDIF

define :method format_cell(cell:cell);
    lvars cell;
    cell.cell_value >< nullstring -> cell.cell_string;
enddefine;

define cell_size(font, cell); lvars font, cell;
    if cell then
        if cell.cell_dirty then
            format_cell(cell);
            lvars label = cell.cell_string;
            lvars (width, height) =
                        string_extents(cell.the_font or font, label);
            width -> cell.cell_width;
            height -> cell.cell_height;
            false -> cell.cell_dirty;
            width, height;
        else
            cell.cell_width, cell.cell_height,
        endif;
    else
        0, 0
    endif;
enddefine;

define resize_table(table); lvars table;
    returnunless(table.table_cells and table.table_resize_needed);

    lvars procedure cells = table.table_cells;

    dlocal do_redraw = false;

    lvars row_spine = table.table_row_spine;
    lvars row_cells = row_spine.spine_cells;

    lvars col_spine = table.table_col_spine;
    lvars col_cells = col_spine.spine_cells;

    lvars (rows, cols) = cells_bounds(cells);

    lvars nrows = row_cells and fi_max(rows, row_cells.datalength) or rows;
    lvars ncols = col_cells and fi_max(cols, col_cells.datalength) or cols;

    nrows -> table.table_num_rows;
    ncols -> table.table_num_cols;

    lvars (min_cell_width, max_cell_width, min_cell_height, max_cell_height,
            hspacing, vspacing) = table.table_cell_bounds.explode;

    lvars widths = col_spine.spine_sizes, heights = row_spine.spine_sizes;
    if widths.isintvec and datalength(widths) == ncols then
        set_subvector(min_cell_width, 1, widths, ncols);
    else
        initvectorclass(ncols, min_cell_width, intvec_key) -> widths;
        widths -> col_spine.spine_sizes;
    endif;

    if heights.isintvec and datalength(heights) == nrows then
        set_subvector(min_cell_height, 1, heights, nrows);
    else
        initvectorclass(nrows, min_cell_height, intvec_key) -> heights;
        heights -> row_spine.spine_sizes;
    endif;

    lvars font = table.the_font;

    ;;; go over the whole table finding the maximum sizes of things
    lvars r, c;
    fast_for c from 1 to cols do
        lvars mwidth = min_cell_width;
        fast_for r from 1 to rows do
            lvars (width, height) = cell_size(font, cells(r, c));
            fi_max(height, fast_subscrintvec(r, heights))
                -> fast_subscrintvec(r, heights);
            fi_max(width, mwidth) -> mwidth;
        endfast_for;
        mwidth -> fast_subscrintvec(c, widths);
    endfast_for;

    ;;; scan the row spines checking their widths

    if row_cells then
        lvars font = row_spine.the_font;

        lvars r, mwidth = min_cell_width;

        fast_for r from 1 to length(row_cells) do
            lvars (width, height) = cell_size(font, subscrv(r, row_cells));
            fi_max(width, mwidth) -> mwidth;
            fi_max(height, fast_subscrintvec(r, heights))
                -> fast_subscrintvec(r, heights);
        endfast_for;

        fi_min(mwidth, max_cell_width) fi_+ hspacing -> row_spine.spine_size;
    else
        0 -> row_spine.spine_size;
    endif;

    ;;; scan the column spines checking their widths
    if col_cells then
        col_spine.the_font -> font;

        lvars mheight = min_cell_height;

        fast_for c from 1 to length(col_cells) do
            lvars (width, height) = cell_size(font, subscrv(c, col_cells));
            fi_max(width, fast_subscrintvec(c, widths))
                -> fast_subscrintvec(c, widths);
            fi_max(height, mheight) -> mheight;
        endfast_for;
        mheight -> col_spine.spine_size;
    else
        0 -> col_spine.spine_size;
    endif;

    ;;; now add the row/column spacing
    lvars grid_width = 0, grid_height = 0;

    fast_for r from 1 to nrows do
        lvars height = fi_min(fast_subscrintvec(r, heights), max_cell_height)
            fi_+ vspacing;
        height -> fast_subscrintvec(r, heights);
        height fi_+ grid_height -> grid_height;
    endfast_for;

    fast_for c from 1 to ncols do
        lvars width = fi_min(fast_subscrintvec(c, widths), max_cell_width)
            fi_+ hspacing;
        width -> fast_subscrintvec(c, widths);
        width fi_+ grid_width -> grid_width;
    endfast_for;

    grid_width -> table.table_width;
    grid_height -> table.table_height;

    grid_width div ncols -> table.table_grid_width;
    grid_height div nrows -> table.table_grid_height;

    widths -> col_spine.spine_sizes;
    heights -> row_spine.spine_sizes;

    false -> table.table_resize_needed;
enddefine;

define lconstant resolve_pixel(spine, pos);
    lvars spine, pos, sizes = spine.spine_sizes;
    lvars offset = 0;
    lvars i;
    for i from 1 to sizes.datalength do
        lvars size = sizes(i);
        lvars next = offset + size;
        if next > pos then
            return(i, pos - offset);
        endif;
        next -> offset;
    endfor;
    return(sizes(datalength), pos - offset);
enddefine;

define lconstant resolve_cell(spine, n) -> size;
    lvars spine, n, size = 0, sizes = spine.spine_sizes, i;

    for i from 1 to min(n - 1, length(sizes)) do
        size fi_+ sizes(i) -> size;
    endfor;
enddefine;


define lconstant draw_cells(table, do_hbar, do_vbar);
    lvars table, do_hbar, do_vbar;

    dlocal do_redraw = false;

    lvars drawing = table.table_drawing;
    returnunless(drawing);

    resize_table(table);

    lvars sb = drawing.hipStoryboard;

procedure;
    dlocal 1 % sb.hipUpdateWindow % = false;

    lvars col_spine = table.table_col_spine;
    lvars row_spine = table.table_row_spine;

    lvars widths = col_spine.spine_sizes, heights = row_spine.spine_sizes;

    lvars row = table.table_row, col = table.table_col;

    lvars max_width = drawing.hipWidth, max_height = drawing.hipHeight;

    max_width + table.table_x_shift -> max_width;
    max_height + table.table_y_shift -> max_height;

    "device" -> drawing.hipInitialUnits;
    true -> drawing.hipOpaque;
    table.the_fill -> drawing.hipFillColor;

    lvars cells = table.table_cells;
    lvars (data_rows, data_cols) = cells.cells_bounds;

    lvars max_row = table.table_num_rows;
    lvars max_col = table.table_num_cols;

    lvars x_shift = table.table_x_shift;
    lvars y_shift = table.table_y_shift;

    define lconstant disable_bar(bar); lvars bar;
        if bar then
            0 -> bar.hipValue;
            100 -> bar.hipMaximum;
            100 -> bar.hipSliderSize;
        endif;
    enddefine;

    if max_row == 0 or max_col == 0 then
        {} -> drawing.hipDrawData;
        disable_bar(table.table_vbar);
        disable_bar(table.table_hbar);
        return;
    endif;

    lvars data_x, data_y;

    if row_spine.spine_cells then
        row_spine.spine_size
    else
        0
    endif -> data_x;

    if col_spine.spine_cells then
        col_spine.spine_size
    else
        0
    endif -> data_y;

    lvars shown_rows = 0, shown_cols = 0;

    define lconstant do_grid_fills;
        lvars x, y;

        hip_do_save();
        hip_do_translate(x_shift, y_shift);
        hip_do_pen_color(false);

        if col_spine.spine_cells then
            hip_do_fill_color(col_spine.the_fill);
            hip_do_rect(data_x, 0, max_width, data_y);
        endif;

        if row_spine.spine_cells then
            hip_do_fill_color(row_spine.the_fill);
            hip_do_rect(0, data_y, data_x, max_height);
        endif;


        hip_do_restore();
    enddefine;

    define lconstant do_grid_lines;
        lvars x, y, c, r;

        returnunless(table.table_grid_pen);

        hip_do_save();

        lvars grid_width = table.table_grid_width;
        lvars grid_height = table.table_grid_height;

        define lconstant do_x(pdr); lvars procedure pdr;
            lvars x = data_x;

            fast_for c from col to max_col do
                quitif(x fi_> max_width);
                pdr(x);
                x fi_+ fast_subscrintvec(c, widths) -> x;
            endfast_for;

            while x fi_< max_width do
                pdr(x);
                x fi_+ grid_width -> x;
            endwhile;
        enddefine;

        define lconstant do_y(pdr); lvars procedure pdr;
            lvars y = data_y;

            fast_for r from row to max_row do
                quitif(y fi_> max_height);
                pdr(y);
                y fi_+ fast_subscrintvec(r, heights) -> y;
            endfast_for;

            while y fi_< max_height do
                pdr(y);
                y fi_+ grid_height -> y;
            endwhile;
        enddefine;

        hip_do_pen_color(table.table_grid_pen);

        do_x(procedure(x); lvars x;
            hip_do_line(x, data_y, x, max_height);
        endprocedure);

        do_y(procedure(y); lvars y;
            hip_do_line(data_x, y, max_width, y);
        endprocedure);


        if col_spine.spine_cells then
            lvars (_, _, top, bot) = hip_shadow_colors(col_spine.the_fill);

            hip_do_translate(0, y_shift);

            hip_do_pen_color(top);
            do_x(procedure(x); lvars x;
                hip_do_line(x + 1, 0, x + 1, data_y);
            endprocedure);
            hip_do_line(data_x, 0, max_width, 0);

            hip_do_pen_color(bot);
            do_x(procedure(x); lvars x;
                hip_do_line(x, 0, x, data_y);
            endprocedure);
            hip_do_line(data_x, data_y, max_width, data_y);

            hip_do_translate(0, -y_shift);
        endif;

        if row_spine.spine_cells then
            lvars (_, _, top, bot) = hip_shadow_colors(row_spine.the_fill);

            hip_do_translate(x_shift, 0);
            hip_do_pen_color(top);

            do_y(procedure(y); lvars y;
                hip_do_line(0, y + 1, data_x, y + 1);
            endprocedure);
            hip_do_line(0, data_y, 0, max_height);

            hip_do_pen_color(bot);

            do_y(procedure(y); lvars y;
                hip_do_line(0, y, data_x, y);
            endprocedure);
            hip_do_line(data_x, data_y, data_x, max_height);
            hip_do_translate(-x_shift, 0);
        endif;

        hip_do_restore();
    enddefine;

    lvars font, align;

    define lconstant do_cell(x, y, width, height, cell);
        lvars x, y, width, height, cell;

        returnunless(cell);

        lvars fnt = font, algn = align;

        lvars ex = x fi_+ width, ey = y fi_+ height;

        define lconstant do_label;
            lvars label = cell.cell_string;

            returnunless(label.isstring and label /= nullstring);

            x fi_+ 3 -> x;

            if locchar(`\n`, 1, label) then
                ;;; multi line labels are costly
                lvars (, lheight) = string_extents(fnt, nullstring);
                lvars rep = label.stringin.incharline;
                fast_for label from_repeater rep do
                    hip_do_label(x, y, ex, fi_min(ey, y fi_+ lheight),
                            label, algn);
                    y fi_+ lheight -> y;
                    quitif(y fi_> ey);
                endfast_for;
            else
                hip_do_label(x, y, ex, ey, label, algn);
            endif;
        enddefine;

        if cell.cell_fancy then
            lvars val;

            hip_do_save();

            if cell.the_fill ->> val then
                hip_do_pen_color(false);
                hip_do_fill_color(val);
                hip_do_rect(x, y, ex, ey);
            endif;

            if cell.the_pen ->> val then
                hip_do_pen_color(val);
            endif;

            if cell.the_font ->> val then
                val -> fnt;
                hip_do_font(val);
            endif;

            if cell.the_alignment ->> val then
                val -> algn;
            endif;

            do_label();

            hip_do_restore();
        else
            do_label();
        endif;
    enddefine;

    define lconstant do_spine(spine, down);
        lvars spine, down;

        if spine.spine_cells then
            lvars x, y, i, cells = spine.spine_cells;
            lvars nitems = cells.length;
            spine.the_alignment -> align;

            hip_do_save();

            hip_do_font(spine.the_font ->> font);

            lvars pen = spine.the_pen;
            hip_do_pen_color(spine.the_pen);

            if down then
                hip_do_translate(x_shift, 0);
                1 -> x; data_y fi_+ 1 -> y;
                fast_for i from row to nitems do
                    lvars size = heights(i);
                    do_cell(x, y, data_x, size, cells(i));
                    y fi_+ size -> y;
                    quitif(y fi_> max_height);
                endfast_for;
                fi_max(i fi_- 1, shown_rows) -> shown_rows;
                hip_do_translate(-x_shift, 0);
            else
                hip_do_translate(0, y_shift);
                data_x fi_+ 2 -> x; 1 -> y;
                fast_for i from col to nitems do
                    lvars size = widths(i);
                    do_cell(x, y, size, data_y, cells(i));
                    x fi_+ size -> x;
                    quitif(x fi_> max_width);
                endfast_for;
                fi_max(i fi_- 1, shown_cols) -> shown_cols;
                hip_do_translate(0, -y_shift);
            endif;

            hip_do_restore();
        endif;
    enddefine;

    define lconstant do_data;
        lvars r, c, x, y;

        hip_do_save();

        hip_do_pen_color(table.the_pen);
        hip_do_font(table.the_font ->> font);
        table.the_alignment -> align;

        data_y -> y;
        fast_for r from row to fi_min(max_row, data_rows) do
            data_x -> x;
            fast_for c from col to fi_min(max_col, data_cols) do
                do_cell(x, y, widths(c), heights(r), cells(r, c));
                x fi_+ widths(c) -> x;
                quitif(x fi_> max_width);
            endfast_for;
            fi_max(c fi_- 1, shown_cols) -> shown_cols;
            y fi_+ heights(r) -> y;
            quitif(y fi_> max_height);
        endfast_for;
        fi_max(r fi_- 1, shown_rows) -> shown_rows;

        hip_do_restore();
    enddefine;

    #|
        hip_do_translate(-x_shift, -y_shift);

        do_data();
        do_grid_fills();
        do_grid_lines();
        do_spine(col_spine, false);
        do_spine(row_spine, true);

        hip_do_translate(x_shift, y_shift);
        hip_do_pen_color(false);
        hip_do_fill_color(table.the_fill);
        hip_do_rect(0, 0, data_x, data_y);
        lvars (_, _, _, bot) = hip_shadow_colors(table.the_fill);
        hip_do_pen_color(bot);
        hip_do_line(data_x, 0, data_x, data_y);
        hip_do_line(0, data_y, data_x, data_y);
    |# -> drawing.hipDrawData;

    shown_rows fi_- row -> shown_rows;
    shown_cols fi_- col -> shown_cols;


    if do_vbar or do_hbar then
        lvars (x, y, width, height) = drawing.hip_coords;
        lvars bar = table.table_vbar;
        if do_vbar and bar then
            x fi_+ width, data_y fi_+ y, false, height fi_- data_y -> bar.hip_coords;

            if table.table_height <= height - data_y then
                disable_bar(bar);
            else
                resolve_cell(col_spine, table.table_col) - x_shift -> bar.hipValue;
                table.table_height -> bar.hipMaximum;
                height - data_y -> bar.hipSliderSize;
            endif;

            0 -> bar.hipHighlightThickness;
            table.the_fill -> bar.hipFillColor;
        endif;

        lvars bar = table.table_hbar;
        if do_hbar and bar then
            x fi_+ data_x, y fi_+ height, width fi_- data_x, false -> bar.hip_coords;
            col fi_- 1 -> bar.hipValue;

            if table.table_width <= width - data_x then
                disable_bar(bar);
            else
                resolve_cell(row_spine, table.table_row) - y_shift -> bar.hipValue;
                table.table_width -> bar.hipMaximum;
                width - data_x -> bar.hipSliderSize;
            endif;
            0 -> bar.hipHighlightThickness;
            table.the_fill -> bar.hipFillColor;
        endif;
    endif;

endprocedure();

enddefine;

define redraw_table(t); lvars t;
    dlocal do_redraw = false;
    0 -> t.table_x_shift;
    0 -> t.table_y_shift;
    draw_cells(t, true, true);
enddefine;

define :method apply_instance(t:table);
    lvars x, y;
    -> (x, y);
    (t.table_cells)(x, y).cell_value;
enddefine;

define :method updaterof apply_instance(t:table);
    lvars x, y, val;
    -> (val, x, y);
    val -> (t.table_cells)(x, y).cell_value;
    resize_table(t);
    redraw_table(t);
enddefine;

lconstant bar_to_table = newproperty([], 32, false, "tmparg");

define table_x(table); lvars table;
    resolve_cell(table.table_col_spine, table.table_col)
        - table.table_x_shift
enddefine;

define updaterof table_x(x, table);
    lvars table, col, x;
    dlocal do_redraw = false;
    resolve_pixel(table.table_col_spine, x) -> (col, x);
    col -> table.table_col;
    x -> table.table_x_shift;
    draw_cells(table, false, false);
enddefine;

define table_y(table); lvars table;
    resolve_cell(table.table_row_spine, table.table_row)
        - table.table_y_shift
enddefine;

define updaterof table_y(y, table);
    lvars table, row, y;
    dlocal do_redraw = false;
    resolve_pixel(table.table_row_spine, y) -> (row, y);
    row -> table.table_row;
    y -> table.table_y_shift;
    draw_cells(table, false, false);
enddefine;

define lconstant table_scroll(i);
    lvars i, t;

    if bar_to_table(i) ->> t then

        dlocal do_redraw = false;

        lvars pos = i.hipValue;
        lvars do_hbar, do_vbar;

        if t.isref then
            t.cont -> t;
            pos -> table_x(t);
        else
            pos -> table_y(t);
        endif;
    endif;
enddefine;

define set_table_children(table, drawing, hbar, vbar);
    lvars table, drawing, hbar, vbar;

    drawing -> table.table_drawing;

    define lconstant set_slider(bar, data);
        lvars bar, data;
        returnunless(bar);
        data -> bar_to_table(bar);
        hip_set_handler(bar, "hipChangeValue", table_scroll);
        hip_set_handler(bar, "hipSlide", table_scroll);
    enddefine;

    hbar -> table.table_hbar;
    set_slider(hbar, consref(table));

    vbar -> table.table_vbar;
    set_slider(vbar, table);
enddefine;

define table_size(table) -> (width, height);
    lvars table, width, height;
    resize_table(table);
    table.table_width + table.table_row_spine.spine_size -> width;
    table.table_height + table.table_col_spine.spine_size -> height;
    if table.table_hbar then
        table.table_hbar.hipHeight + height -> height;
    endif;
    if table.table_vbar then
        table.table_vbar.hipWidth + width -> width;
    endif;
enddefine;


endsection;
