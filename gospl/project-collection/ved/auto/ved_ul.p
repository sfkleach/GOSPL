;;; Summary: nroff-style underline in marked range

/* <ENTER> ul - underline in marked range                    R.Evans April 1983
   --------------------------------------

    This command scans the marked range taking special action when the
    following characters are encountered:
        #  - replace with a space and mark the next word for underlining
        $  - replace with space and change mode: underline all words UNLESS
             preceded by # (until another $ is encountered - then change back)
    Each line in the marked range is extended with a string which underlines
    all the words marked for underlining by the above procedure (when printed
    out)


    <ENTER> ul  <char> - ul may optionally be given a single character as an
    argument, which then is used instead of #. A second character, if supplied,
    is used instead of $. Note that POP11 item rules apply (ul looks for the
    POP11 WORD #) so its best to use a sign character to avoid unnecessary
    spaces (eg ~ ^ etc)

*/

section $-library => ved_ul;

    vars oldline uldata ullen;

    define reset();
        [] -> uldata;
        1 -> ullen;
        false -> oldline;
    enddefine;

    /* add data of latest word to underline list */
    define underline(From,Item);
        vars Length;
        Item >< '' -> Item;
        datalength(Item) -> Length;
        /* simple puctuation trap */
        unless Length == 1 and item_chartype(subscrs(1,Item)) > 3 then
            {^(From-ullen) ^Length} :: uldata -> uldata;
            From + Length -> ullen;
        endunless;
    enddefine;

    /* build underline string from data and attatch to end of line */
    define add_underlines;
        vars vedbreak vedline vedcolumn vvedlinesize x;
        if null(uldata) then return endif;
        oldline -> vedline;
        vedsetlinesize();
        vedtextright();
        false -> vedbreak;
        0;  /* room for carriage return */
        for x in rev(uldata) do
            repeat x(1) times ` ` endrepeat;
            repeat x(2) times `_` endrepeat;
        endfor;
        vedinsertstring(consstring(ullen));
        /* put in carriage return afterwards - stop vedcharinsert trapping it */
        13 -> subscrs(vedcolumn - ullen,vedthisline());
    enddefine;

    define notatend;
        vars vedline vvedlinesize;
        if vedatend() or not(vedmarked(vedline)) then false
        elseif vedcolumn <= vvedlinesize then true
        else
            for vedline from vedline+1 to vvedmarkhi do
                vedsetlinesize();
                if vvedlinesize > 0 then return(true) endif;
            endfor;
            false;
        endif;
    enddefine;

/* find next word and underline it */
    define do_underline();
        if notatend() then
            while vedcurrentchar() == ` ` do vedwordright() endwhile;
            if oldline and  vedline /== oldline then
                /* changed line - insert last underline string */
                add_underlines();
                reset();
            endif;
            unless oldline then vedline -> oldline endunless;
            underline(vedcolumn,vedmoveitem());
        endif;
    enddefine;

    define delete(char);
        vars vedbreak; false -> vedbreak;
        until vedcurrentchar() == char do vedwordright() enduntil;
        veddotdelete();
        vedcharinsert(` `);
    enddefine;

define global ved_ul;
    vars markchar markword word vedautowrite
         toggle togchar togword;

    false -> vedautowrite;
    `#` -> markchar;
    `$` -> togchar;
    unless vedargument = vednullstring then
        subscrs(1,vedargument) -> markchar;
        if datalength(vedargument) > 1 then
            subscrs(2,vedargument) -> togchar;
        endif;
    endunless;
    if markchar == togchar then vederror('ILLEGAL FLAG CHARACTERS') endif;
    consword(markchar,1) -> markword;
    consword(togchar,1) -> togword;

    vedmarkfind();
    false -> toggle;
    3 -> item_chartype(`'`);
    reset();

    while notatend() do
        vednextitem() -> word;
        ;;; consume toggle if found
        if word == togword then
            delete(togchar);
            not(toggle) -> toggle;
        endif;
        if (if word == markword then delete(markchar); not(toggle) else toggle
            endif) then
            do_underline();
        else
            erase(vedmoveitem());
        endif;
    endwhile;
    if oldline then add_underlines(); endif;
    vedsetlinesize();
    7 -> item_chartype(`'`);
enddefine;


endsection;
