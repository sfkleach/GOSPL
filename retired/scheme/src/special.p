 
;;; -- Both valid_sexp & plant_sexp are driven off special table

recordclass constant Special
    validSpecial
    plantSpecial;

constant special_table =
    newanyproperty(
        [], 25, 1, false,
        false, false, true,
        false,
        procedure( k, p ); lvars k, p;
            consSpecial(
                false,
                false
            ) ->> p( k )
        endprocedure
    );
