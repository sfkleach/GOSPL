;;; Summary: affine transformations in any whole-numbered dimension

/* Copyright:      James A.D.W. Anderson 1990. All rights reserved.
 > File:           $usemod/lib/modtransfm.p
 > Release:        %W%    %G%
 > Purpose:        Provides matrix datatypes and operations on
                   the TRSHM transformation.
 > Documentation:  $usemod/help/modtransfms
 > Related Files:  $usepop/pop/lib/auto/external.p
                   $usepop/pop/lib/auto/fortran_dec.p
                   /usr/lang/SC0.0/libnag.a
                   /usr/lang/SC0.0/libF77.a
                   /usr/lib/libm.a
 > Notes:          Transformations and vectors are stored in array_of_double
                   so that they can be shared with FORTRAN.
*/

section $-library => modtransfms modnewcoords modnewtransfm modnewparams
    modisrowbasis modisaffine modismatrix modiscoords modistransfm
    modisparams modrowbasisneeded modaffineneeded modmatrixneeded
    modcoordsneeded modtransfmneeded modparamsneeded modsize
    moddimension modmatrixcopy modmatrixpr modsystranspose modtranspose
    modsyscat modcat ##* modsysinverse modinverse modsystransfm
    modtransfm modsysparams modparams;

uses external;
uses fortran_dec;

global vars modtransfms = true;

section modtransfms => modnewcoords modnewtransfm modnewparams
    modisrowbasis modisaffine modismatrix modiscoords modistransfm
    modisparams modrowbasisneeded modaffineneeded modmatrixneeded
    modcoordsneeded modtransfmneeded modparamsneeded modsize
    moddimension modmatrixcopy modmatrixpr modsystranspose modtranspose
    modsyscat modcat ##* modsysinverse modinverse modsystransfm
    modtransfm modsysparams modparams;

vars popdprecision = true;

/* Create matrix datatypes.

   'modcoords'  is a matrix of homogeneous coordinates.
   'modtransfm' is a transformational matrix.
   'modparams'  is a matrix of transformation parameters.

   'modmatrix'  is the super type of the above three.

   'modprops'   is a property that stores type information.
*/

;;; 'modprops' is a minimally small hash table which grows
;;; to defend 75% full. The key is any pop-object and the target
;;; a 'modtype', with default 'false'. Updating the 'modprops'
;;; is dangerous for the uninitiated.
vars modprops;

unless isproperty(modprops)
then   newanyproperty([],4,1,3,false,false,false,false,false) -> modprops;
endunless;

;;; In the binary fields 0 is false 1 is true.
;;; 'modaffine' reserved for future use.
recordclass modtype modsizemag      :16
                    moddimensionmag : 8
                    modrowbasisid   : 1
                    modaffineid     : 1
                    modmatrixid     : 1
                    modcoordsid     : 1
                    modtransfmid    : 1
                    modparamsid     : 1;

;;; Store name printed by 'modtypeneeded' along with system name.
[modrowbasisid  MODROWBASIS ] -> pdprops(modrowbasisid);
[modaffineid    MODAFFINE   ] -> pdprops(modaffineid);
[modmatrixid    MODMATRIX   ] -> pdprops(modmatrixid);
[modcoordsid    MODCOORDS   ] -> pdprops(modcoordsid);
[modtransfmid   MODTRANSFM  ] -> pdprops(modtransfmid);
[modparamsid    MODPARAMS   ] -> pdprops(modparamsid);

;;; Return the zero coordinate matrix.
define global modnewcoords(size, dimension) -> coords;
    lvars size dimension coords;
    dlocal poparray_by_row = true;

    ;;; Check arguments.
    if   size < 1
    then mishap('SIZE >= 1 NEEDED', [^size])
    endif;
    if   dimension < 0
    then mishap('DIMENSION >= 0 NEEDED', [^dimension])
    endif;

    ;;; Create augmented matrix, initialised with zeros.
    array_of_double([% 1, dimension+1, 1, size %], 0) -> coords;

    ;;; Create a null closure to enable modification in-place in
    ;;; other procedures.
    partapply(coords, []) -> coords;

    ;;; Create and bind type.
    consmodtype(size,dimension,1,1,1,1,0,0) -> modprops(coords);
enddefine;

;;; Return the identity transformation.
define global modnewtransfm(dimension) -> transfm;
    lvars i size props dimension transfm;
    dlocal poparray_by_row = true;

    ;;; Create zeroed matrix.
    dimension + 1 -> size;
    modnewcoords(size, dimension) -> transfm;

    ;;; Initialise matrix.
    for i to size do 1 -> transfm(i,i) endfor;

    ;;; Overwrite properties.
    0 -> transfm.modprops.modcoordsid;
    1 -> transfm.modprops.modtransfmid;
enddefine;

;;; Return the identity parameter matrix.
define global modnewparams(dimension) -> params;
    lvars dimension params;

    ;;; Create and initialise matrix.
    modnewtransfm(dimension) -> params;

    ;;; Overwrite properties.
    0 -> params.modprops.modtransfmid;
    1 -> params.modprops.modparamsid;
enddefine;

/* Recognisers for the 'modmatrix' types.
*/
define modistype(object, type);
    lvars props object type;
    if   modprops(object) ->> props
    then type(props) == 1
    else false
    endif;
enddefine;

global vars modisrowbasis = modistype(% modrowbasisid %),
     modisaffine   = modistype(% modaffineid   %),
     modismatrix   = modistype(% modmatrixid   %),
     modiscoords   = modistype(% modcoordsid   %),
     modistransfm  = modistype(% modtransfmid  %),
     modisparams   = modistype(% modparamsid   %);

"modisrowbasis" -> pdprops(modisrowbasis);
"modisaffine"   -> pdprops(modisaffine  );
"modismatrix"   -> pdprops(modismatrix  );
"modiscoords"   -> pdprops(modiscoords  );
"modistransfm"  -> pdprops(modistransfm );
"modisparams"   -> pdprops(modisparams  );

/* Trappers for the 'modmatrix' types.
*/
define modtypeneeded(object, type);
    lvars object type props;
    unless modistype(object, type)
    then   mishap(type.pdprops.tl.hd >< ' NEEDED', [^object])
    endunless;
enddefine;

global vars modrowbasisneeded = modtypeneeded(% modrowbasisid %),
            modaffineneeded   = modtypeneeded(% modaffineid   %),
            modmatrixneeded   = modtypeneeded(% modmatrixid   %),
            modcoordsneeded   = modtypeneeded(% modcoordsid   %),
            modtransfmneeded  = modtypeneeded(% modtransfmid  %),
            modparamsneeded   = modtypeneeded(% modparamsid   %);

"modrowbasisneeded" -> pdprops(modrowbasisneeded);
"modaffineneeded"   -> pdprops(modaffineneeded);
"modmatrixneeded"   -> pdprops(modmatrixneeded);
"modcoordsneeded"   -> pdprops(modcoordsneeded);
"modtransfmneeded"  -> pdprops(modtransfmneeded);
"modparamsneeded"   -> pdprops(modparamsneeded);

define global modsize(matrix);
    lvars matrix;
    modmatrixneeded(matrix);
    matrix.modprops.modsizemag;
enddefine;

define global moddimension(matrix);
    lvars matrix;
    modmatrixneeded(matrix);
    matrix.modprops.moddimensionmag;
enddefine;

/* Copy procedure for 'modmatrix' types.
*/
define global modmatrixcopy(matrix1) -> matrix2;
    lvars matrix1 matrix2;

    ;;; Check argument.
    modmatrixneeded(matrix1);

    ;;; Copy the matrix and the arrayvector elements.
    array_of_double(matrix1.boundslist, matrix1) -> matrix2;

    ;;; Create a null closure to enable modification in-place in
    ;;; other procedures.
    partapply(matrix2, []) -> matrix2;

    ;;; Copy the modprops.
    matrix1.modprops.copy -> matrix2.modprops;
enddefine;

/* Printer for the 'modmatrix' types.
*/
vars mod_pr_figs   = 6;
syssynonym("mod_pr_places", "pop_pr_places");

define global modmatrixpr(matrix);
    lvars matrix m n him hin;
    dlocal pop_pr_places;

    ;;; Check argument and get bounds.
    modmatrixneeded(matrix);
    matrix.boundslist.explode ->hin ->; ->him; ->;

    ;;; Correct bug in 'prnum'.
    if     pop_pr_places <= 0
    then   0
    elseif pop_pr_places > 0
    then   pop_pr_places + 1
    endif  -> pop_pr_places;

    ;;; Print the matrix.
    pr(newline);
    for m to him do
        for n to hin do
            prnum(matrix(m, n), mod_pr_figs, mod_pr_places);
            pr(space);
        endfor;
        pr(newline);
    endfor;
    pr(newline);
enddefine;

/* Basic matrix operations imported from NAG library.
*/
external declare modnag in fortran;

    ;;; Matrix transpose.
    SUBROUTINE F01CRF(A,M,N,MN,MOVE,IWRK,IFAIL)
    INTEGER           IFAIL, IWRK, M, MN, N
    DOUBLE PRECISION  A(MN)
    INTEGER           MOVE(IWRK)
    END

    ;;; Matrix multiplication.
    SUBROUTINE F01CKF(A,B,C,N,P,M,Z,IZ,OPT,IFAIL)
    INTEGER           IFAIL, IZ, M, N, OPT, P
    DOUBLE PRECISION  A(N,P), B(N,M), C(M,P), Z(IZ)
    END

    ;;; Matrix inverse.
    SUBROUTINE F04AEF(A,IA,B,IB,N,M,C,IC,WKSPCE,AA,IAA,BB,IBB,IFAIL)
    INTEGER           IA, IAA, IB, IBB, IC, IFAIL, M, N
    DOUBLE PRECISION  A(IA,N),AA(IAA,N),B(IB,M),BB(IBB,M),C(IC,M),WKSPCE(N)
    END
endexternal;

external load modnag;
    '/usr/lang/SC0.0/libnag.a'
    '/usr/lang/SC0.0/libF77.a'
    '-lm'
endexternal;

define global modsystranspose(matrix, workspace);
    lvars m n props tempsize worksize status matrix workspace;

    ;;; Hard noisy exit on failure. Defensive, should never occur.
    0 -> status;

    ;;; Check matrix.
    modmatrixneeded(matrix);

    ;;; Check that workspace is big enough.
    matrix.boundslist.explode ->n; ->; ->m; ->;
    intof((m+n)/2) -> tempsize;
    workspace.arrayvector.length -> worksize;

    unless tempsize <= worksize
    then   mishap('BIGGER WORKSPACE NEEDED', [^workspace])
    endunless;

    ;;; Transpose matrix elements.
    F01CRF(matrix, m, n, m*n, workspace, worksize, ident status);

    ;;; Transpose bounds, if neccessary.
    if   m /== n
    then newanyarray([1 ^n 1 ^m], arrayvector(matrix)) -> pdpart(matrix)
    endif;

    ;;; Toggle modprops to show transposed basis.
    if   matrix.modprops.modrowbasisid == 1
    then 0
    else 1
    endif -> matrix.modprops.modrowbasisid;
enddefine;

define global modtranspose(matrix1) -> matrix2;
    lvars m n workspace worksize matrix1 matrix2;

    ;;; Workspace allocated at run time.
    matrix1.boundslist.explode ->n; ->; ->m; ->;
    intof((m+n)/2) -> worksize;
    array_of_integer([1 ^worksize]) -> workspace;

    modmatrixcopy(matrix1) -> matrix2;

    ;;; Matrix transpose.
    modsystranspose(matrix2, workspace);
enddefine;

;;; Concatenate matrix1 and matrix 2 in matrix3 by multiplication.
define global modsyscat(matrix1, matrix2, matrix3);
    lvars status m1 n1 m2 n2 m3 n3 matrix1 matrix2 matrix3;

    ;;; Workspace allocated at compile time.
    lconstant tempsize = 1,
              temp = #_< array_of_double([1 ^tempsize]) >_#;

    ;;; Hard noisy exit on failure. Defensive, should never occur.
    0 -> status;

    ;;; Check that all matrices are of type modmatrix.
    modmatrixneeded(matrix1);
    modmatrixneeded(matrix2);
    modmatrixneeded(matrix3);

    ;;; Check that all matrix elements are of compatible types.
    if   modisparams(matrix2) or  modisparams(matrix3)
    then mishap('CANNOT MULTIPLY A MODPARAM',   [^matrix2 ^matrix3])
    endif;
    if   modiscoords(matrix2) and modiscoords(matrix3)
    then mishap('CANNOT MULTIPLY TWO MODCOORDS', [^matrix2 ^matrix3])
    endif;

    ;;; Check that all matrices are conformable for multiplication.
    matrix1.boundslist.explode ->n1; ->; ->m1; ->;
    matrix2.boundslist.explode ->n2; ->; ->m2; ->;
    matrix3.boundslist.explode ->n3; ->; ->m3; ->;

    if     n2 /== m3
    then   mishap('ARGUMENTS NOT CONFORMABLE', [^matrix2 ^matrix3]);
    elseif m1 /== m2 or n1 /== n3
    then   mishap('RESULT NOT CONFORMABLE', [^matrix1 ^matrix2 ^matrix3]);
    endif;

    ;;; Check that both multiplication arguments have the same basis.
    if   matrix2.modprops.modrowbasisid /== matrix3.modprops.modrowbasisid
    then mishap('ARGUMENTS INCOMPATIBLE BASIS', [^matrix2 ^matrix3])
    endif;

    ;;; Check that both multiplication arguments have the correct basis.
    if   modiscoords(matrix3) and matrix3.modprops.modrowbasisid /== 1
    then mishap('ROW BASIS VECTORS NEEDED', [^matrix1 ^matrix2 ^matrix3]);
    endif;
    if   modiscoords(matrix2) and matrix2.modprops.modrowbasisid /== 0
    then mishap('COLUMN BASIS VECTORS NEEDED', [^matrix1 ^matrix2 ^matrix3]);
    endif;

    ;;; Matrix multiplication.
    F01CKF(matrix1,matrix2,matrix3,m2,n3,n2,temp,1,1,ident status);

    ;;; Force correct element type in result.
    if   modiscoords(matrix2) or modiscoords(matrix3)
    then 1 -> matrix1.modprops.modcoordsid;
         0 -> matrix1.modprops.modtransfmid;
         0 -> matrix1.modprops.modparamsid;
    else 0 -> matrix1.modprops.modcoordsid;
         1 -> matrix1.modprops.modtransfmid;
         0 -> matrix1.modprops.modparamsid;
    endif;

    ;;; Force correct basis in result.
    matrix2.modprops.modrowbasisid -> matrix1.modprops.modrowbasisid;
enddefine;

define global modcat(matrix2, matrix3) -> matrix1;
    lvars m n matrix1 matrix2 matrix3;

    ;;; Workspace, 'matrix1', allocated at run time.
    ;;; Type coerced by modsyscat.
    matrix2.boundslist.explode ->;  ->; ->m; ->;
    matrix3.boundslist.explode ->n; ->; ->;  ->;
    modnewcoords(n, m-1) -> matrix1;

    ;;; Matrix multiplication.
    modsyscat(matrix1, matrix2, matrix3);
enddefine;

;;; Matrix concatenation (multiplication) operator.
define global 1.5 ##* (matrix2, matrix3);
    lvars matrix2 matrix3;
    modcat(matrix2, matrix3);
enddefine;

;;; Return status 0 if O.K, 1 if singular, 2 if ill conditioned.
define global modsysinverse(matrix, inverse, decomp, residual, identity,
              workspace) -> status;
    lvars size matrix inverse decomp residual identity workspace status;

    ;;; Silent soft exit.
    1 -> status;

    ;;; Check that all matrices are of type modtransfm.
    modtransfmneeded(matrix);
    modtransfmneeded(inverse);
    modtransfmneeded(decomp);
    modtransfmneeded(residual);
    modtransfmneeded(identity);

    ;;; Check that all matrices are the same shape.
    matrix.modprops.modsizemag -> size;
    unless inverse.modprops.modsizemag  == size and
           decomp.modprops.modsizemag   == size and
           residual.modprops.modsizemag == size and
           identity.modprops.modsizemag == size
    then   mishap('SAME SHAPE MATRICES NEEDED',
                  [^matrix ^inverse ^decomp ^residual ^identity]
           );
    endunless;

    ;;; Check that the workspace is big enough.
    unless workspace.arrayvector.length >= size
    then   mishap('BIGGER WORKSPACE NEEDED', [^workspace])
    endunless;

    ;;; Matrix inverse.
    F04AEF(matrix, size, identity, size, size, size, inverse, size, workspace,
           decomp, size, residual, size, ident status);
enddefine;

define global modinverse(matrix) -> inverse -> status;
    lvars size dimension matrix inverse status;

    ;;; Check argument.
    modmatrixneeded(matrix);

    ;;; Get size.
    matrix.modprops.modsizemag      -> size;
    matrix.modprops.moddimensionmag -> dimension;

    ;;; Allocate space for inverse.
    modnewtransfm(dimension) -> inverse;

    ;;; Matrix inverse.
    modsysinverse(matrix,
                  inverse,
                  modnewtransfm(dimension),
                  modnewtransfm(dimension),
                  modnewtransfm(dimension),
                  array_of_double([1 ^size])
    ) -> status;
enddefine;

/* TRSHM procedures.
*/
;;; Copy perspective and translation parts of params into transfm.
;;; Return status = 3 on non-identity perspective part.
define compose_t(params, transfm, dimension, status);
    lvars i size params transfm dimension status;

    ;;; Dimension 0 params and transfm have no t part or vanishing
    ;;; points, but the for loop guards this case preventing any work
    ;;; being done.

    dimension + 1 -> size;

    ;;; Check zero vanishing points and copy translation.
    for i from 1 to dimension do
        if   params(size,i) /= 0
        then 3 -> idval(status);
        endif;
        0              -> transfm(size,i);
        params(i,size) -> transfm(i,size);
    endfor;

    ;;; Check unit zoom and copy to transfm.
    if   params(size, size) /= 1
    then 3 -> idval(status);
    endif;
    1 -> transfm(size, size);
enddefine;

;;; Check rotation parameter constraints.
;;; Return status = 2 on failure.
define checkrot(params, dimension, semirot, rightrot, status);
    lvars i j a params dimension semirot rightrot status;

    ;;; Dimension 0 and 1 params and transfm have no r part, but the for
    ;;; loops guard these cases preventing any work being done.

    for j from 1 to dimension-1 do
        params(dimension, j) -> a;

        ;;; Check range of r angles.
        if   (a <= -semirot) or (a > semirot)
        then 2 -> idval(status)
        endif;

        ;;; Check determinism constraint on r angles.
        if   abs(a) = rightrot
        then
             ;;; Check determinism constraint on r+ angles
             for i from j+1 to dimension-1 do
                 unless params(i,j) = rightrot
                 then 2 -> idval(status);
                 endunless;
             endfor;
        else
             ;;; Check range of r+ angles.
             for i from j+1 to dimension-1 do
                 params(i,j) -> a;
                 if   (a <= -rightrot) or (a > rightrot)
                 then 2 -> idval(status)
                 endif;
             endfor;
        endif;
    endfor;
enddefine;

define compose_r(params, transfm, dimension, status);
    lvars i j k a c s val1 val2 params transfm dimension status;

    dlocal popradians = true;

    ;;; Dimension 0 and 1 params and transfm have no r part, but the for
    ;;; loops guard these cases preventing any work being done.

    ;;; Check rotation constraints.
    checkrot(params, dimension, pi, pi/2, status);

    ;;; Compose rotation.
    for i from dimension by -1 to 2 do
        for j from i-1 by -1 to 1 do

            ;;; Calculate cos and sin from rotation parameter.
            params(i,j) -> a;
            sin(a) -> s;
            cos(a) -> c;

            ;;; Fast pre-multiplication of transfm by rotation.
            if   a /= 0
            then for k from 1 to dimension do
                     transfm(j,k) -> val1;
                     transfm(i,k) -> val2;
                     c*val1 - s*val2 -> transfm(j,k);
                     c*val2 + s*val1 -> transfm(i,k);
                 endfor;
            endif;
        endfor;
    endfor;
enddefine;

;;; Compose SHM setting status = 1 if magnitude or handedness
;;; constraints broken.
define compose_shm(params, transfm, dimension, status);
    lvars i j m params transfm dimension status;

    ;;; Dimension zero has no smh part.
    if dimension = 0 then return endif;

    ;;; Check constraints on m.
    for i from 1 to dimension-1 do
        if   params(i,i) <= 0
        then 1 -> idval(status);
        endif;
    endfor;

    ;;; Check constraint on hm.
    if   params(dimension,dimension) = 0
    then 1 -> idval(status)
    endif;

    ;;; Compose smh in transfm.
    for j from 1 to dimension do

        params(j,j) -> m;
        m -> transfm(j,j);

        ;;; Multiply shear by magnitude.
        for i from 1 to j-1 do
            m*params(i,j) -> transfm(i,j);
        endfor;
    endfor;
enddefine;

define global modsystransfm(params, transfm, dimension, status);
    lvars params transfm dimension status;

    ;;; Check arguments.
    modparamsneeded(params);
    modtransfmneeded(transfm);
    if   dimension < 0
    then mishap('DIMENSION >= 0 NEEDED', [^dimension])
    endif;

    ;;; Clear status to indicate correct execution.
    ;;; Set by compose procedures to indicate error.
    0 -> idval(status);

    ;;; Compose trsmh.
    compose_shm (params, transfm, dimension, status);
    compose_r   (params, transfm, dimension, status);
    compose_t   (params, transfm, dimension, status);
enddefine;

define global modtransfm(params) -> transfm -> status;
    lvars workspace rowbasis dimension params transfm status;

    ;;; Check argument is a modparams.
    modparamsneeded(params);

    ;;; Workspace allocated at run time.
    params.modprops.moddimensionmag -> dimension;
    modnewtransfm(dimension) -> transfm;

    ;;; Workspace conditionally allocated at run time.
    ;;; Force params to have rowbasis <true>.
    unless modisrowbasis(params) ->> rowbasis
    then   array_of_integer([1 %dimension+1%]) -> workspace;
           modsystranspose(params, workspace);
    endunless;

    ;;; Do work.
    modsystransfm(params, transfm, dimension, ident status);

    ;;; Force params and transfm to have same basis as original params.
    unless rowbasis
    then   modsystranspose(params,  workspace);
           modsystranspose(transfm, workspace);
    endunless;
enddefine;

;;; Decompose SHM setting status = 1 if magnitude or handedness
;;; constraints broken.
define decompose_shm (transfm, params, dimension, status);
    lvars i j m transfm params dimension status;

    ;;; Dimension 0 params and transfm have no smh part.
    if dimension = 0 then return endif;

    ;;; Check constraints on m.
    for i from 1 to dimension-1 do
        if   transfm(i,i) <= 0
        then 1 -> idval(status);
        endif;
    endfor;

    ;;; Check constraint on hm.
    if   transfm(dimension,dimension) = 0
    then 1 -> idval(status)
    endif;

    ;;; Return on error to prevent division by zero.
    unless idval(status) = 0 then return endunless;

    ;;; Deompose smh into params.
    for j from 1 to dimension do

        transfm(j,j) -> m;
        m -> params(j,j);

        ;;; Divide shear by magnitude.
        for i from 1 to j-1 do
            transfm(i,j)/m -> params(i,j);
        endfor;
    endfor;
enddefine;

;;; Calculate c,s with c >= 0 and angle unique.
define rplus(i, j, transfm) -> c -> s;
    lvars tjj tij val i j transfm c s;

    transfm(j,j) -> tjj;
    transfm(i,j) -> tij;

    ;;; Compute c and s.
    if     tjj = 0
    then   1 -> s;
           0 -> c;
    elseif tij = 0
    then   0 -> s;
           1 -> c;
    elseif abs(tjj) >= abs(tij)
    then   tij/tjj -> val;
           1/sqrt(1 + val*val) -> c;
           c*val -> s;
    else   tjj/tij -> val;
           sign(val)/sqrt(1 + val*val) -> s;
           s*val -> c;
    endif;
enddefine;

;;; Calculate magnitude >= 0, angle unique.
define r(i, j, transfm) -> c -> s;
    lvars tjj tij val i j transfm c s;

    transfm(j,j) -> tjj;
    transfm(i,j) -> tij;

    ;;; Compute c and s.
    if     (tjj = 0) and (tij = 0)
    then   return
    elseif tjj = 0
    then   sign(tij) -> s;
           0 -> c;
    elseif tij = 0
    then   sign(tjj) -> c;
           0 -> s;
    elseif abs(tjj) >= abs(tij)
    then   tij/tjj -> val;
           sign(tjj)/sqrt(1 + val*val) -> c;
           c*val -> s;
    else   tjj/tij -> val;
           sign(tij)/sqrt(1 + val*val) -> s;
           s*val -> c;
    endif;
enddefine;

;;; Decomposition algorithm enforces rotation constraints, so no need to
;;; check them. The status flag is not changed.
define decompose_r(transfm, params, dimension, status);
    lvars i j k a c s val1 val2 transfm params dimension status;

    dlocal popradians = true;

    ;;; Dimension 0 and 1 params and transfm have no r part, but the for
    ;;; loops guard these cases preventing any work being done.

    ;;; Compose rotation.
    for i from 2 to dimension do
        for j from 1 to i-1 do

            ;;; Calculate cos and sin from transfm.
            if   i < dimension
            then rplus(i, j, transfm) -> c -> s;
            else r    (i, j, transfm) -> c -> s;
            endif;

            ;;; Store angle in params.
            arctan2(c, s) -> a;
            a -> params(i,j);

            ;;; Fast pre-multiplication of transfm by inverse rotation.
            if   a /= 0
            then for k from 1 to dimension do
                     transfm(j,k) -> val1;
                     transfm(i,k) -> val2;
                     c*val1 + s*val2 -> transfm(j,k);
                     c*val2 - s*val1 -> transfm(i,k);
                 endfor;
            endif;
        endfor;
    endfor;
enddefine;

;;; Translation and perspective components of a transfm are identical to
;;; their parameters, so call compose_t with params and transfm swapped.
define decompose_t(transfm, params, dimension, status);
    lvars transfm params dimension status;
    compose_t(transfm, params, dimension, status);
enddefine;

define global modsysparams(transfm, params, dimension, status);
    lvars transfm params dimension status;

    ;;; Check arguments.
    modtransfmneeded(transfm);
    modparamsneeded(params);
    if   dimension < 0
    then mishap('DIMENSION >= 0 NEEDED', [^dimension])
    endif;

    ;;; Clear status to indicate correct execution.
    ;;; Set by decompose procedures to indicate error.
    0 -> idval(status);

    ;;; Decompose trsmh.
    decompose_t   (transfm, params, dimension, status);
    decompose_r   (transfm, params, dimension, status);
    decompose_shm (transfm, params, dimension, status);
enddefine;

define global modparams(transfm) -> params -> status;
    lvars rowbasis workspace dimension transfm params status;

    ;;; Check argument is a modtransfm.
    modtransfmneeded(transfm);

    ;;; Workspace allocated at run time.
    modmatrixcopy(transfm) -> transfm;
    transfm.modprops.moddimensionmag -> dimension;
    modnewparams(dimension) -> params;

    ;;; Workspace conditionally allocated at run time.
    ;;; Force params to have rowbasis <true>.
    unless modisrowbasis(transfm) ->> rowbasis
    then   array_of_integer([1 %dimension+1%]) -> workspace;
           modsystranspose(transfm, workspace);
    endunless;

    ;;; Do work.
    modsysparams(transfm, params, dimension, ident status);

    ;;; Force params to have same basis as original params.
    unless rowbasis
    then   modsystranspose(params,  workspace);
    endunless;
enddefine;

section_cancel(current_section);

endsection;
endsection;
