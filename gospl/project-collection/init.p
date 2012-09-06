;;;
;;; N.B. This file is self-homing; it detects the directory it resides
;;; within in order to determine the home of the GOSPL.  So you cannot
;;; load it via a symbolic link.
;;;
compile_mode :pop11 +strict;

section;


;;; Load the root project.

lvars gospl_home = sys_fname_path( popfilename );

compile( gospl_home dir_>< 'root/init.p' );

;;; Now declare the GOSPL project collection.
sys_uses_project_collection( gospl_home );

endsection;
