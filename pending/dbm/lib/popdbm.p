/* --- Copyright Integral Solutions Ltd 1993. All rights reserved. ----------
 > File:            $pophipworks/local/lib/popdbm.p
 > Purpose:         Interface to the GNU GDBM library
 > Author:          Jonathan Meyer, Nov 10 1992
 > Documentation:   REF *DBM, MAN * DBM
 */
global vars $-popdbm = systranslate('popdbm') or '$poplocal/local/dbm';

#_IF DEF vedediting
extend_searchlist([[%popdbm dir_>< 'ref'% ref]], vedreflist) -> vedreflist;
;;; extend_searchlist([[%popdbm dir_>< 'gdbm'% src]], vedsrclist) -> vedsrclist;
#_ENDIF
extend_searchlist(popdbm dir_>< 'auto', popautolist) -> popautolist;
extend_searchlist(popdbm dir_>< 'lib', popuseslist) -> popuseslist;
