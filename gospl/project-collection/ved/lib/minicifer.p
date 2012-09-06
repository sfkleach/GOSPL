;;; Summary: cifer terminal setup

;;; lib minicifer
;;; load this if cifer terminal has already been programmed

false   -> vedscrollscreen;     ;;; Cifer is not fast enough - refresh instead
false   -> vednokeypad;
false   -> vednotabs;
false   -> vedterminalselect;

define vvedscreenresetpad;
    ;;; called when going out of editing mode
    ;;; this procedure can be re-written to suit the local environment
    ;;; set normal scrolling into VDU memory back
    vedscreenescape(`7`);
enddefine;

define vvedscreensetpad;
    ;;; called when going into editing mode
    ;;; enable Xon/Xoff, set no autowrap, make cursor block, set highlight half
    ;;; change 'B' to 'C' for blinking block. Disable long scroll
    vedscreenescape('%\^[6\^[*W\^B\^[X\^[8'); rawoutflush();
enddefine;



;;; control codes for Cifer. Output after <ESC>
`D` -> vvedscreencharleft;
`C` -> vvedscreencharright;
`A` -> vvedscreencharup;
'^J' -> vvedscreenclear;
'^K' -> vvedscreencleartail;
'^('    -> vvedscreendeletechar;
'^)'    -> vvedscreendeleteline;

'^.'    -> vvedscreeninsertline;
'^A'    -> vvedscreeninsertmode;
'^G'    -> vvedscreenovermode;

`:` -> vvedscreencursorupscroll;

false   -> vednocharinsert;
false   -> vednokeypad;
false   -> vednolineinsert;

;;; The following characters have 8'th bit set to make VED treat them
;;; as 'graphic' characters. They will therefore cause graphic mode
;;; to be set on when they are output.
`<` + 8:200 -> vedscreencommandmark;
` ` + 8:200 -> vedscreencursor;
`+` + 8:200 -> vedscreencursormark;
`>` + 8:200 -> vedscreenlinemark;
`|` + 8:200 -> vedscreenmark;
`~` + 8:200 -> vedscreencontrolmark;

;;; Now the strings output to set terminal into 'graphic' mode, or
;;; reset to alphanumeric mode. Use highlight (reverse video) in place
;;; of graphic.
`N`  -> vvedscreengraphic;      ;;; set highlight
`O`    -> vvedscreenalpha;      ;;; unset highlight



define vedscreenxy(col,row);
    ;;; for locating cursor on screen of cifer
        if col == 1 and row == 1
        then
            vedscreenescape(`H`)
        else
            vedscreenescape(`P`);
            vedoutascii(col + 31);
            vedoutascii(row + 31)
        endif;
        col -> vedscreencolumn;
        row -> vedscreenline;
enddefine;


;;; set up mapping between ESC ESC ? char and procedures, so that ESC
;;; followed by keypad number will cause a biggish move.
copy(vedescapetable) -> vedescapetable;

[%	`?`,	[%
				`q`,	vedchardownleftlots,
				`r`,	vedchardownlots,
				`s`,	vedchardownrightlots,
				`t`,	vedcharleftlots,
				`u`,	vedcharmiddle,
				`v`,	vedcharrightlots,
				`w`,	vedcharupleftlots,
				`x`,	vedcharuplots,
				`y`,	vedcharuprightlots,
			%]
%] -> vedescapetable(`\^[`);
