;;; ENTER V200KEYS
;;; John Williams, October 25 1984
;;; reads diagram of Visual 200 function key settings into other window
;;; also defines ESC-K to do the same

define ved_v200keys;
    vars vedargument vedstartwindow vednamestring;
    unless vedterminalname == "v200" do
        vederror('Only know VISUAL 200 function keys')
    endunless;
    'v200keys' -> vedargument;
    12 -> vedstartwindow;
    ved_help();
    vedtopfile();
    vedenter();
    vedclearhead();
    vedstatusswitch();
    vedscreenbell();
    'VED FUNCTION KEYS FOR VISUAL 200 TERMINAL' -> vednamestring;
    vedswapfiles()
enddefine;

vedsetkey('\^[k', ved_v200keys);
