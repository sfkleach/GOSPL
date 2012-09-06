;;; Summary: supports operations on rectangular blocks in VED

/*
LIB CHUNKS           Chris Thornton  --  May 84

      - enables various operations on 'logical chunks' in VED
*/

section;

vars chunks = true;

define global tell();
   apply( vedediting and vedputmessage or npr )
enddefine;


tell('Loading GRAPHCHARSETUP');
uses graphcharsetup;
graphcharsetup();


global vars
    separation,
    max_width,
    max_height,
    tab_step;

endsection;

section $-chunks => ved_box ved_dbox ved_boxg ved_rbox ved_tbox
   ved_chbox ved_chboxg                          ;;; drawing
   ved_jch ved_shch                              ;;; justifying/showing
   ved_chl ved_chr ved_chu ved_chd               ;;; moving
   ved_tch ved_mch ved_vch ved_rch               ;;; transferring
   ved_chmarg ved_nmarg ved_dmarg ved_mbr        ;;; margins
   ved_cch                                       ;;; compiling
   ved_dch ved_yankch                            ;;; deleting
   box chunkin at_box boxdimensions_at;          ;;; utilities


vars
    normal_left,
    normal_right,
    source_topleft,
    target_topleft,
    botright,
    chdump;

3 -> separation;
25 -> max_height;
150 -> max_width;
6 -> tab_step;
false -> botright;
[] -> chdump;


;;; utilities

constant inc = nonop fi_+ (%1%);
constant dec = nonop fi_- (%1%);


define here();
   {%vedline, vedcolumn, 11%}
enddefine;


define vedpositionpopp();
   ;;; pop the positionstack and don't fiddle with it
   vedjumpto(fast_front(vedpositionstack));
   vedcheck();
   fast_back(vedpositionstack) -> vedpositionstack;
enddefine;


define length_longest(strings) -> result;
   ;;; return the length of the longest string in the list STRINGS
   lvars string len strings result; 0 -> result;
   for string in strings do
      if (datalength(string) ->> len) fi_> result then len -> result endif;
   endfor
enddefine;


define at(index, string);
   ;;; subscript the STRING, or return FALSE if its not long enough
   lvars index string;
   if datalength(string) fi_< index or index fi_< 1 then
      false
   else
      fast_subscrs(index, string)
   endif
enddefine;


tell('Loading first half of CHUNKS');


define issubs(subs, index, str);
   ;;; check for membership of SUBString in STR, if STR is long enough
   lvars subs index str;
   if datalength(str) fi_>= index then
      issubstring(subs, index, str)
   else
      false
   endif
enddefine;


define scan_SE(pos, range, str);
   ;;; scan 'south-east' (ie. below and to right) in file for STR
   ;;; if find it, return its position
   lvars line col pos range str;
   pos(1) -> line;
   repeat range times
      quitif(line fi_> vvedbuffersize);
      if (issubs(str, max(pos(2),1), vedbuffer(line)><' ') ->> col) then
         return({%line, col, 11%})
      else
         inc(line) -> line;
      endif
   endrepeat;
   return(false)
enddefine;


define markhi_below();
   ;;; check to see if there is a likely-looking end-of-range mark below
   if vvedmarkhi fi_> vedline and
         vvedmarkhi fi_< (vedline fi_+ max_height) then
      vvedmarkhi
   else
      false
   endif
enddefine;


define wiggle(needed);
   if needed then
      repeat 4 times vedwiggle(vedline, vedcolumn) endrepeat;
   endif;
   vedcharright();
enddefine;


define eat_tab(max_blanks);
   ;;; gobble up the current-tab (provided its not too big) and return length
   lvars blanks max_blanks;
   for blanks from 0 to max_blanks do
      if vedcurrentchar() /== ` ` then return(blanks) endif;
      vedcharright();
   endfor;
   return(false)
enddefine;


define set_margins(left, right);
   left -> vedleftmargin;
   right -> vedlinemax;
   vedputmessage('NEW MARGINS: '><left><' '><right);
enddefine;


define set_temp_margins(left, right);
   vedleftmargin -> normal_left;
   vedlinemax -> normal_right;
   set_margins(left, right);
enddefine;


define set_normal_margins();
   set_margins(normal_left, normal_right)
enddefine;


define vedconfirm(option);
   ;;; check with the user re. OPTION and return a boolean
   lvars answer line col option p;
   vedline -> line; vedcolumn -> col;
   until answer == `y` or answer == `n` do
      vedputmessage(option><'?  (TYPE "y" or "n")');
      ;;; ensure good view
      vedjumpto(max(line fi_- 5,1), col); vedcheck();
      vedjumpto(line fi_+ 5, col); vedcheck();
      vedjumpto(line, col);
      vedscreenbell();
      vedwiggle(0,40); vedwiggle(line, col);
      vedinascii() -> answer;
   enduntil;
   answer == `y`
enddefine;


define space_writeable_for(object);
   ;;; check that the user really wants to overwrite text
   ;;; - assumes calling pdr has a position stacked up and returns a boolean
   lvars object;
   if not(vedcurrentchar() == ` ` and (vedcharright(); true)) then
      vedconfirm('overwrite text in '><object><' target area');
      vedpositionpopp();
      exitfrom(caller(1));
   endif
enddefine;


;;; BOX drawing/deleting etc.

define at_box(vs, hs, pdr, vert, horiz, tlcor, trcor, blcor, brcor) -> result;
   ;;; execute pdrs (VERT, HORIZ and CORNER) at appropriate places
   lvars vs hs; vars vedautowrite vedstatic;
   false -> vedautowrite; true ->> vedstatic -> result;
   vedpositionpush(); vedchardown();
   repeat vs times pdr(vert); vedchardownleft(); endrepeat;
   pdr(blcor);
   repeat hs times pdr(horiz); endrepeat;
   pdr(brcor);
   vedjumpto(fast_front(vedpositionstack));
   pdr(tlcor);
   repeat hs times pdr(horiz); endrepeat;
   pdr(trcor);
   repeat vs times vedchardownleft(); pdr(vert); endrepeat;
   vedpositionpopp();
enddefine;


define box(height, width, char, check);
   ;;; do something to a box (ie. draw or delete)
   ;;; if CHECK is true then check if overwrite is acceptable
   lvars vs hs height width char check;
   height fi_-2 -> vs; width fi_-2 -> hs;
   if check and not(at_box(vs, hs, space_writeable_for,
         repeat 6 times 'BOX' endrepeat)) then
      vederror('aborted')
   endif;
   vs; hs; vedcharinsert;  ;;; stack up the constant args
   if char == 13 then      ;;; default
      at_box(`|`, `-`, ` `, ` `, ` `, ` `) ->;
   elseif char == 27 then  ;;; graphics
      at_box(graph_vert,graph_horz,graph_topleft,graph_topright,graph_botleft,graph_botright) ->;
   else                    ;;; special char
      at_box(repeat 6 times char endrepeat) ->;
   endif
enddefine;


;;; chunk-transferring

define area_writeable(segments);
   ;;; check that area is clear (or overwrite is OK) for segments in chunk
   lvars seg line segments;
   0 -> line;
   vedpositionpush();
   for seg in segments do
      quitif(vedatend());
      repeat datalength(seg) times space_writeable_for('CHUNK') endrepeat;
      vedjumpto(fast_front(vedpositionstack));
      repeat (inc(line) ->> line) times vedchardown() endrepeat;
   endfor;
   vedpositionpopp();
   return(true)
enddefine;


define segment(seg_length, scrape);
   ;;; return a segment (ie. a string) of prescribed length
   lvars seg_length str l;
   if seg_length = 0 then
      false
   else
      inc(datalength(vedbuffer(vedline))) -> l;
      consstring(repeat seg_length times 32 endrepeat, seg_length) -> str;
      substring(min(l,vedcolumn), seg_length, vedbuffer(vedline)><str);
      if scrape then
         vedpositionpush();
         vedinsertstring(str);
         vedpositionpopp();
      endif;
   endif
enddefine;


define scrapesegment();  ;;; seg_length stays on the stack
   segment(true)
enddefine;



define copysegment();    ;;; ditto
   segment(false)
enddefine;


define segmentlength(current_tab) -> len current_tab;
   ;;; return the length of current segment, and length of current tab
   ;;; - looks for next occurence of three blank spaces
   lvars leftcolumn seg_end current_tab separator;
   vedpositionpush();
   vedcolumn -> leftcolumn;
   if vedcolumn fi_> vvedlinesize or
      not(eat_tab(current_tab fi_+ tab_step) ->> current_tab) then
      0 -> len
   else
      consstring(repeat separation times 32 endrepeat, separation) -> separator;
      issubstring(separator, vedcolumn, vedthisline()><separator) -> seg_end;
      (seg_end fi_- leftcolumn) -> len
   endif;
   vedpositionpopp();
enddefine;


define boxdimensions_at(startline, startcol, shift) -> height width;
   ;;; return the dimensions of the current box
   ;;; - works from bottom-right corner (SHIFT set to DECrement)
   ;;;   or from top, left corner (SHIFT set to INCrement).
   ;;; - crawls along edges of box looking SHIFTwards for a 'give-away' char
   lvars shift ishorizchar isvertchar boxchar line col startline startcol;
   2 ->> height -> width;
   shift(startline) -> line; startcol -> col;
   if not(at(col, vedbuffer(startline)) ->> boxchar) or
         member(boxchar, #_<[%32,graph_topleft,graph_topright,graph_botleft,graph_botright%]>_#) then
      false -> boxchar
   endif;
   member(%boxchar :: #_<[45 224 228 227]>_#%) -> ishorizchar;
   member(%boxchar :: #_<[124 225 238 239]>_#%) -> isvertchar;
   until ishorizchar(at(shift(col), vedbuffer(line))) do
      quitif(not(isvertchar(at(col, vedbuffer(line)))) and (2 -> height;true));
      inc(height) -> height; shift(line) -> line;
   enduntil;
   startline -> line; shift(startcol) -> col;
   until isvertchar(at(col,vedbuffer(shift(line)))) do
      quitif(not(ishorizchar(at(col, vedbuffer(line)))) and (2 -> width;true));
      inc(width) -> width; shift(col) -> col
   enduntil;
   ;;; meaningfulize output
   if height == 2 or width == 2 then 0 ->> height -> width endif;
enddefine;

tell('Loading second half of CHUNKS');


define inboxon(line, col) -> topleft;
   ;;; return top-left position if cursor is inside a box with
   ;;; bottom-right at LINE & COL; otherwise return FALSE
   lvars height width line col;
   boxdimensions_at(line, col, dec) -> width -> height;
   if width /== 0 and (vedline fi_> (line fi_- height) and
         vedcolumn fi_>= (col fi_- width)) then
      {%line fi_- height fi_+ 1, col fi_- width fi_+ 1, 11%}
   else
      false
   endif -> topleft;
enddefine;


define inboxwith_botright(pattern);
   ;;; search SE for the PATTERN and check if it is the bottom-right
   ;;; part of an enclosing box; return TOPLEFT position or FALSE
   lvars line col botright offset topleft pattern;
   dec(datalength(pattern)) -> offset;
   explode(here()) ->; -> col -> line;
   col fi_- offset -> col;
   until not(scan_SE({%line, col%}, max_height fi_- (line fi_- here()(1)),
         pattern) ->> botright) do
      if (inboxon(botright(1), botright(2) fi_+ offset) ->> topleft) then
         return(topleft)
      endif;
      inc(botright(1)) -> line;
   enduntil;
   return(false)
enddefine;


define inbox();
   inboxwith_botright('-- ') or inboxwith_botright(#_<consstring(graph_botright,1)>_#)
enddefine;


define atbox_topleft();
   if erase(boxdimensions_at(vedline, vedcolumn, inc)) /== 0 then
      here()
   else
      false
   endif
enddefine;


define gobox_topleft_?();
   unless atbox_topleft() do
      if dup(inbox()) then vedjumpto() else -> endif;
   endunless
enddefine;


define isboxedchunk();
   lvars topleft;
   if (atbox_topleft() ->> topleft) or (inbox() ->> topleft) then topleft else false endif
enddefine;


define getboxchunk(height, width, getsegment, include_box);
   ;;; return a list of segments using GETSEGMENT pdr.
   ;;; - adjusts parameters if INCLUDE_BOX is true
   lvars height width correction getsegment include_box;
   (if include_box then 0 else vedchardownright(); 2 endif) -> correction;
   [% if width /== 0 then
          repeat (height fi_- correction) times
             getsegment(width fi_- correction);
             if not(vedatend()) then vedchardown() endif;
          endrepeat
       endif %]
enddefine;


define getchunk(getsegment) -> result;
   ;;; return the list of segments which comprise the
   ;;; current chunk, using GETSEGMENT
   lvars seg limit height current_tab getsegment; 0 -> current_tab;
   if botright then  /* user has marked the botright of the chunk */
      getboxchunk(inc(botright(1)) fi_- vedline, inc(botright(2)) fi_- vedcolumn,
         getsegment, true) -> result;
      false -> botright;
   elseif atbox_topleft() then
      getboxchunk(boxdimensions_at(vedline, vedcolumn, inc),
         getsegment, true) -> result
   else
      if (markhi_below() ->> limit) then
         limit fi_- vedline fi_+ 1
      else
         vvedbuffersize
      endif -> height;
      [% repeat height times
             if (getsegment((segmentlength(current_tab) -> current_tab)) ->> seg) then
                seg
             else
                quitif(not(limit));
                0 -> current_tab;
                ''
             endif;
          quitif(vedatend()); vedchardown();
          endrepeat %] -> result;
   endif
enddefine;


define putchunk(segments) -> result;
   lvars seg;
   if not((area_writeable(segments)->> result)) then vedjumpto(source_topleft) endif;
   vedcheck();
   for seg in segments do
      vedpositionpush(); vedinsertstring(seg); vedpositionpopp();
      vedchardown()
   endfor
enddefine;



/* (try to) transfer the current chunk to TARGET_TOPLEFT */
define transfer_to() -> result;
   /* there may be up to 2 args */
   lvars seg segments target_topleft arg scoop; vars vedstatic vedautowrite;
   /* if the top arg is not a pdr, then provide default */
   unless isprocedure(dup()) then scrapesegment endunless -> scoop -> target_topleft;
   true -> vedstatic; false -> vedautowrite;
   vedcheck(); vedpositionpush();
   here() -> source_topleft;
   if not(target_topleft) or null(getchunk(scoop) ->> segments) then
      false -> result;
   else
      vedjumpto(target_topleft);
      putchunk(segments) -> result;
   endif;
   if result then target_topleft else source_topleft endif; vedjumpto();
enddefine;


/* (try to) transfer the marked chunk to HERE (transcribe/move), */
define transfer_here(transcribe) -> result;
   lvars transcribe scoop;
   if transcribe then copysegment else scrapesegment endif -> scoop;
   here() -> target_topleft;
   vedpositionpopp(); gobox_topleft_?();
   if not(transfer_to(target_topleft, scoop) ->> result) then
      vedjumpto(target_topleft)
   endif
enddefine;


define rightposition() -> result;
   ;;; go through the positionstack looking for the 'return'
   ;;; position; return <position> or FALSE
   vars vedpositionstack; lvars current_pos pos wrongs result;
   false -> result;
   here() -> current_pos;
   [%allbutlast(1,current_pos)%] -> wrongs;
   if isvector(source_topleft) then conspair(source_topleft,vedpositionstack) -> vedpositionstack endif;
   for pos in vedpositionstack do
      if not(member(allbutlast(1, pos), wrongs)) then
         vedjumpto(pos);
         quitif(vedconfirm('to here...'><pos) and (true; pos -> result));
         conspair(allbutlast(1, pos), wrongs) -> wrongs;
      endif
   endfor;
   vedjumpto(current_pos);
enddefine;


define chunkdimensions() -> height width;
   lvars br_save segments height width;
   botright -> br_save;
   vedpositionpush();
   getchunk(copysegment) -> segments;
   vedpositionpopp();
   br_save -> botright;
   length_longest(segments) -> width;
   length(segments) -> height;
enddefine;



;;; ENTER commands for drawing and deleting chunks

define ved_box();
   if vedargument = '' then
      vederror('dimensions?')
   else
      box(compile(stringin(vedargument)), 13, true)
   endif
enddefine;


define ved_boxg();
   if vedargument = '' then
      vederror('dimensions?')
   else
      box(compile(stringin(vedargument)), 27, true);
   endif
enddefine;


define rbox(char);
   ;;; redo this box using CHAR
   lvars width height;
   gobox_topleft_?();
   boxdimensions_at(vedline, vedcolumn, inc) -> width -> height;
   if width == 0  then
      vederror('cursor position?')
   else
      box(height, width, char, false)
   endif
enddefine;


define ved_dbox();
   rbox(32)
enddefine;


define ved_rbox();
   vedputmessage('format? type <RETURN> (=default), <ESC> (=graphics) or <CHAR>');
   rbox(vedinascii())
enddefine;


define ved_tbox();
   ;;; trace out the corners of a box of specified dimensions
   lvars height width;
   if vedargument = '' then
      vederror('dimensions?')
   else
      compile(stringin(vedargument)) -> width -> height;
      if width /== 0 then
         at_box(height fi_-2, width fi_-2, wiggle, false, false,
            true, true, true, true) ->;
         if vedconfirm('draw it') then ved_box() endif;
      endif
   endif
enddefine;


;;; ENTER command for 'showing' a chunk

define ved_shch();
   lvars seg segs line br_save;
   botright -> br_save;
   gobox_topleft_?();
   vedpositionpush(); getchunk(copysegment) -> segs; vedpositionpopp();
   if null(segs) then
      vederror('cursor position')
   else
      vedputmessage('CHUNK: height = '><length(segs)><', width = '><length_longest(segs));
      vedline -> line;
      for seg in segs do
         vedwiggle(line, vedcolumn);
         vedwiggle(line, vedcolumn fi_+ datalength(seg));
         inc(line) -> line;
      endfor;
   endif;
   br_save -> botright;
enddefine;


;;; ENTER commands for moving chunks about

define vedmovechunk(cursor_movement);
   gobox_topleft_?();
   vedpositionpush();
   repeat vedargnum(vedargument) times cursor_movement() endrepeat;
   here() -> target_topleft;
   vedpositionpopp();
   if not(transfer_to(target_topleft)) then
      vederror('cant move')
   endif;
enddefine;


define ved_chl();
   vedmovechunk(vedcharleft)
enddefine;


define ved_chr();
   vedmovechunk(vedcharright)
enddefine;


define ved_chu();
   vedmovechunk(vedcharup)
enddefine;


define ved_chd();
   vedmovechunk(vedchardown)
enddefine;


;;; ENTER commands for wrapping-up chunks in boxes and boxgs

define vedwrapchunk(char);
   lvars height width;
   gobox_topleft_?();
   chunkdimensions() -> width -> height;
   if transfer_to({%vedline fi_+1, vedcolumn fi_+2%}) then
      vedcharleft(); vedcharupleft();
      box(height fi_+ 2, width fi_+ 4, char, true);
   else
      vederror('cant enclose')
   endif
enddefine;


define ved_chbox();
   vedwrapchunk(13)
enddefine;


define ved_chboxg();
   vedwrapchunk(27)
enddefine;


;;; ENTER command for transcribing chunks between two positions

define ved_tch();
   if transfer_here(true) then
      vedputmessage('DONE')
   else
      vederror('cant transfer here')
   endif
enddefine;


;;; ENTER command for moving chunks between two positions

define ved_mch();
   if transfer_here(false) then
      vedputmessage('DONE')
   else
      vederror('cant move here')
   endif
enddefine;


;;; ENTER command for deleting a chunk

define ved_dch();
   vars vedstatic vedautowrite; true -> vedstatic; false -> vedautowrite;
   gobox_topleft_?();
   here() -> source_topleft;
   if null(getchunk(scrapesegment) ->> chdump) then
      'cant delete'
   else
      'DONE'
   endif;
   vederror();
enddefine;


define ved_yankch();
   vars vedstatic vedautowrite; true -> vedstatic; false -> vedautowrite;
   if null(chdump) then
      'nothing to yank'
   else
      /* rightposition doesn't consider current pos, so */
      vedcharrightlots();
      if dup(rightposition()) then
         vedjumpto();
         if putchunk(chdump) then
            'DONE'
         else
            'cant yank'
         endif;
      else /* take pos off stack */
         ->; 'nowhere to yank to'
      endif
   endif;
   vederror();
enddefine;



;;; ENTER command for 'VEDing' chunks

define ved_vch();
   gobox_topleft_?();
   if transfer_to({%vedusedsize(vedbuffer) fi_+2, vedleftmargin fi_+1%}) then
      vedputmessage('source position = '><source_topleft);
   else
      vederror('cant ved')
   endif
enddefine;


;;; ENTER command for replacing chunks (eg. after VEDing them)

define ved_rch();
   gobox_topleft_?();
   if transfer_to(rightposition()) then
      vedputmessage('DONE')
   else
      vedputmessage('cant replace')
   endif
enddefine;


;;; ENTER command for justifying an ordinary chunk

define ved_jch();
   ;;; justify the current chunk
   vars vedlinemax vedleftmargin; lvars height;
   inc(chunkdimensions()) -> vedlinemax; -> height;
   if transfer_to({%vedusedsize(vedbuffer) fi_+2, 1%}) then
      0 -> vedleftmargin;
      vedpositionpush(); vedmarkpush();
      vedmarklo(); vedjumpto(vedline fi_+ height, vedcolumn); vedmarkhi();
      ved_j();
      vedpositionpopp();
      transfer_to(source_topleft) ->;
      vedmarkpop();
   else
      vederror('cursor position?')
   endif;
enddefine;


;;; ENTER commands for setting margins

define ved_chmarg();
   lvars width;
   gobox_topleft_?();
   chunkdimensions() -> width -> ;
   if width /== 0 then
      set_temp_margins(dec(vedcolumn), dec(vedcolumn fi_+ width));
   else
      vederror('curson position?')
   endif
enddefine;


define ved_nmarg();
   set_normal_margins()
enddefine;


define ved_dmarg();
   set_margins(0, 78)
enddefine;


define ved_mbr();
   {%vedline, vedcolumn%} -> botright;
   vedscreenbell(); vedputmessage('MARKED');
enddefine;


unless isprocedure(vedgetproctable('\^[m')) do
   vedsetkey('\^[m', ved_mbr)
endunless;


;;; chunk character repeaters

define chunkin() -> repeater;
   lvars seg str segs topleft;
   '' -> str;
   gobox_topleft_?();
   if atbox_topleft() then
      getboxchunk(boxdimensions_at(vedline, vedcolumn, inc), copysegment, false)
   else
      getchunk(copysegment)
   endif -> segs;
   for seg in segs do str >< seg -> str; endfor;
   stringin(str) -> repeater;
enddefine;


;;; chunk compilations

define ved_cch();
   popcompiler(chunkin())
enddefine;


endsection;
