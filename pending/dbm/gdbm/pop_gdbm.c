/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            $poplocal/local/dbm/extern/pop_dbm.c
 > Purpose:         Interface to the UNIX NDBM library
 > Author:          Jonathan Meyer, Nov 10 1992
 > Documentation:   REF *GDBM_FILE, MAN * NDBM
 */

/*
Unfortunately, the GDBM library takes and returns datum structures, rather
than pointers to these structures. This means we must write a set of `C'
wrappers to the library.
*/

#include "gdbm.h"

int pop_gdbm_firstkey(dbm, dat)
GDBM_FILE *dbm;
datum *dat;
{
	/* use dbm_firstkey to fill in the user supplied datum */
	*dat = gdbm_firstkey(dbm);
	return(dat->dptr ? 0 : -1);
}

int pop_gdbm_nextkey(dbm, dat)
GDBM_FILE *dbm;
datum *dat;
{
	/* use dbm_nextkey to fill in the user supplied datum */
	*dat = gdbm_nextkey(dbm, *dat);
	return(dat->dptr ? 0 : -1);
}

int pop_gdbm_fetch(dbm, key, klen, contentd)
GDBM_FILE *dbm;
char *key;
int klen;
datum *contentd;
{
	datum keyd;
	/* fill in a datum with the key/length and then call dbm_fetch,
       setting the supplied contentd to the result.
    */
	keyd.dptr = key;
	keyd.dsize = klen;
	*contentd = gdbm_fetch(dbm, keyd);
	return(contentd->dptr ? 0 : -1);
}

int pop_gdbm_store(dbm, key, klen, content, clen)
GDBM_FILE *dbm;
char *key, *content;
int klen, clen;
{
	datum keyd, contentd;
	/* fill in a datum with the key/length and content/length, and
       then call dbm_store with update mode GDBM_REPLACE.
    */
	keyd.dptr = key;
	keyd.dsize = klen;
	contentd.dptr = content;
	contentd.dsize = clen;
	return gdbm_store(dbm, keyd, contentd, GDBM_REPLACE);
}

int pop_gdbm_delete(dbm, key, klen)
GDBM_FILE *dbm;
char *key;
int klen;
{
	datum keyd, contentd;
	keyd.dptr = key;
	keyd.dsize = klen;
	return gdbm_delete(dbm, keyd);
}

/* locates an integer in an intvec. Returns the index to the integer where
1 is the first element, or -1 if it is not found
*/
int pop_gdbm_locint(i, ivec, len)
register int i, *ivec;
int len;
{
	register int count = len;
	do {
		if (*ivec++ == i)
			return(len - count + 1);
	} while (count--);
	/* not found */
	return(-1);
}

/*
JM, 17/6/93
	Changed pop_dbm_nextkey to pass the datum it is given to
	gdbm_nextkey
*/
