;;; Summary: access prolog teach files

section;
global vars vedpteachlist;
['use$pop:[pop.local.pteach]' ^^vedteachlist] -> vedpteachlist;


define global ved_pteach();
	vedsysfile("vedteachname",vedpteachlist,vedhelpdefaults);
enddefine;

endsection;
