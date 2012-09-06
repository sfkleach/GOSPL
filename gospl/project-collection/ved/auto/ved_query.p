;;; Jonathan Laventhol, 17 Oct 1984.			*** UNIX ONLY ***
;;;
;;; facility for david allport for getting questions from msc students
;;; for the help file finder project.
;;;
;;; ENTER query <question>
;;; bungs the question in a file in a spool directory, with a filename made
;;; from the username and a number.
;;; directory is currently $usepop/pop/local/spool/questions
;;; filenames are like jcl.5

section ved => ved_query;

;;; where to put the questions.
;;;
constant querydir;
	'$usepop/pop/local/spool/questions' -> querydir;

;;; check that it exists, as a directory
;;;
unless readable(querydir dir_>< '.') then
	mishap(querydir, 1, 'don\'t know where to put questions')
endunless;

vars col;

;;; format the printing so lines break after 60 chars, on space
define fmt(c);
lvars c;
	if (c == ` ` and col > 60) or col > 78 then
		cucharout(`\n`);
		0 -> col
	else
		cucharout(c);
		col + 1 -> col;
	endif;
enddefine;

define global procedure ved_query();
lvars n name;
vars cucharout col pop_file_mode;
	8:666 -> pop_file_mode;
	0 -> col;
	1 -> n;
	;;; get filename like jcl.1
	while readable((querydir dir_>< popusername >< '.' >< n) ->> name) do
		1 + n -> n
	endwhile;
	discout(name) -> cucharout;
	appdata(vedargument, fmt);
	cucharout(`\n`);
	cucharout(termin);
	vedputmessage('Your question is filed. Thanks.')
enddefine;

endsection;
