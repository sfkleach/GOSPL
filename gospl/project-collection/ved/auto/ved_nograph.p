;;; Summary: make the current buffer printable by any printer

compile_mode :pop11 +strict;

section;

;;; NOGRAPH
;;; Convert the current ved buffer to something printable by any printer
;;; (replace graphics characters)
;;; Chris Mellish, 1984

uses graphchars;
graphcharsetup();

vars print_code;

newproperty([

[^graph_horz  `-` ]
[^graph_vert  `|` ]
[^graph_cross `+` ]
[^graph_topleft  `r` ]
[^graph_topright  `i` ]
[^graph_botleft   `\`` ]
[^graph_botright  `'` ]
[^graph_teeup `T` ]
[^graph_teedown `I` ]
[^graph_teeleft   `|` ]
[^graph_teeright  `|` ]
[^graph_degree    `o` ]
[^graph_plusminus `+` ]
[^graph_rightarrow   `>` ]
[^graph_leftarrow  `<` ]
[^graph_uparrow   `^` ]
[^graph_downarrow `V` ]
[^graph_dotdot    `.` ]
[^graph_divide    `*` ]
[^graph_yen   `Y` ]
[^graph_cent  `c` ]
[^graph_pound  `$` ]
[^graph_sub0  `0` ]
[^graph_sub1  `1` ]
[^graph_sub2  `2` ]
[^graph_sub3  `3` ]
[^graph_sub4  `4` ]
[^graph_sub5  `5` ]
[^graph_sub6  `6` ]
[^graph_sub7  `7` ]
[^graph_sub8  `8` ]
[^graph_sub9  `9` ]
[^graph_para  `|` ]
[^graph_diamond  `D` ]
[^graph_checkerboard  `C` ]
[^graph_ht    `H` ]
[^graph_ff    `F` ]
[^graph_cr    `C` ]
[^graph_lf    `L` ]
[^graph_nl    `N` ]
[^graph_vt    `V` ]
[^graph_lesseq    `<` ]
[^graph_greateq   `>` ]
[^graph_pi    `^` ]
[^graph_noteq `#` ]
[^graph_dot   `.` ]],
300,false,true) -> print_code;

define ved_nograph();
   vars c;
   vedendfile();
   until vedatstart() do
      vedcharleft();
      vedcurrentchar() -> c;
      if c.isgraphiccode then
         print_code(c) -> vedcurrentchar()
      endif
   enduntil
enddefine;

endsection;
