;;; Summary: bbc micro as terminal setup

define bbcvt100();
    vars vt100escbrtable vt100goldFtable vt100goldtable vt100escFtable
         vt100querychange table num vt100escescbrtable vt100goldescbrtable
         vt100goldescescbrtable;
    vedvt100(false);
    [% ;;; arrow-keys
        `A`, vedcharup,
        `B`, vedchardown,
        `C`, vedcharright,
        `D`, vedcharleft,
    %] -> vt100escbrtable;

    [% ;;; <esc> arrow-keys
        `A`, vedcharuplots,
        `B`, vedchardownlots,
        `C`, vedcharrightlots,
        `D`, vedcharleftlots,
    %] -> vt100escescbrtable;

    [% ;;; <gold> arrow-keys
        `A`, vedlineabove,
        `B`, vedlinebelow,
        `C`, vedtextright,
        `D`, vedtextleft,
    %] -> vt100goldescbrtable;

    [%
        `[`, [%
                `A`, procedure; vedcharup(); vedtextleft(); endprocedure,
                `B`, procedure; vednextline(); vedtextleft(); endprocedure,
                `C`, vedscreenright,
                `D`, vedscreenleft,
             %],
    %] -> vt100goldescescbrtable;


    [%
        `P`, ved_pop, ;;; <F0>F0-F9, except F4, F7
        `Q`, ved_xup,
        `t`, ved_xdn,
        `u`, vedclearhead,
        `q`, vedcleartail,
        `R`, ved_da,
        `p`, ved_lcp,
        `n`, ved_yankc,
    %] -> vt100goldFtable;

    [%
        `\^[`, [%
                    `[`, vt100goldescbrtable,
                    `O`, vt100goldFtable,
                    `\^[`, vt100goldescescbrtable,
                %],
        `\^M`, vedexchangeposition,  ;;; <gold><RET>
        `\^?`, vedpopkey,  ;;; <gold><DEL>
        `\^H`, vedpushkey, ;;; <gold><COPY>
    %] -> vt100goldtable;


    [%
        `P`, nonmac dcl, ;;; <esc>F0-F9, except F7
        `Q`, vedtopfile,
        `t`, vedendfile,
        `u`, ved_yankw,
        `w`, ved_yankl,
        `q`, ved_yankw,
        `R`, ved_yank,
        `p`, ved_mcp,
        `n`, vedstatusswitch,
    %] -> vt100escFtable;

    {%
        `P`, vt100goldtable,
        `Q`, vedscreenup,
        `t`, vedscreendown,
        `u`, vedwordleft,
        `w`, vednextline,
        `q`, vedwordright,
        `R`, ved_copy,
        `r`, ved_m,
        `p`, vedmarklo,
        `n`, vedenter,

        `y`, vedwordleftdelete, ;;; <shift> F3-F9
        `s`, vedlinedelete,
        `v`, vedwordrightdelete,
        `l`, ved_d,
        `m`, ved_tr,
        `S`, vedmarkhi,
        `M`, veddocommand,
    %} -> vt100querychange;

    copy(vednormaltable) -> vednormaltable;
    vedrefresh -> vednormaltable(`\^H`);
    copy(vedescapetable) -> vedescapetable;
    vt100escbrtable -> vedescapetable(`[`);
    ved_cut -> vedescapetable(`\^?`);
    ved_splice -> vedescapetable(`\^H`);
    vednextline -> vedescapetable(`\^M`);



    `O` -> vedquery;
    copy(vedquerytable) ->> vedquerytable
                        ->> vedescapetable(`?`)
                        -> vedescapetable(vedquery);
    copy(vt100querychange) -> table;
    for num from 1 by 2 to datalength(table) do
        fast_subscrv(num+1,table)
        -> fast_subscrv(fast_subscrv(num,table), vedquerytable);
    endfor;

    [%
        `O`, vt100escFtable,
        `[`, vt100escescbrtable,
    %] -> vedescapetable(vedescape);
enddefine;


if vedterminalselect then
    bbcvt100();
    false -> vedterminalselect;
endif;
