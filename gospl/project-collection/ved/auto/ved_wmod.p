/* LIB VED_WMOD                                     Chris Slymon, October 1983

	Write file with a specified mode, which must be in octal form e.g.

    	wmod 752

    writes a file with owner read write and execute permission, group read
    and execute permission and world write permission. (i.e. rwxr-x-w-)

    File is unlinked if it already exists, to stop use of current mode!

*/

section $-ved => ved_wmod;

define global ved_wmod();
    vars pop_file_mode;
    strnumber('8:' <> vedargument) -> pop_file_mode;
    if readable(veddirectory dir_>< vedcurrent) then
	    sysunlink(veddirectory dir_>< vedcurrent) ->;
    endif;
    ved_w1();
enddefine;

endsection;
