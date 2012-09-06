compile_mode :pop11 +strict;

section;

define global xt_new_widget_tree( parent, tree ) -> table; lvars tree, table, parent;
    lconstant default = consundef( false );

    define lconstant might_be_tree( item ); lvars item;
        item.islist and
        not( null( item ) ) and
        (
            item(1).isprocedure or
            not( null( item.tl ) ) and item(2).isprocedure
        )
    enddefine;

    newanyproperty(
        [], 8, 1, false,
        false, false, "perm",
        default, false
    ) -> table;

    define lconstant mktree( parent, t ); lvars parent, t;
        lvars p = t.dest -> t;
        lvars name =
            if p.isprocedure then
                default
            else
                p;
                t.dest -> t -> p
            endif;
        parent;
        lvars children = [];
        lvars i;
        for i in t do
            if i.might_be_tree then
                i :: children -> children;
            else
                i
            endif;
        endfor;
        lvars widget = p();
        if name /== default then
            if table( name ) /== default then
                warning( 'Duplicated widget name', [ ^name ] )
            endif;
            widget -> table( name );
        endif;
        lvars i;
        for i in rev( children ) do
            mktree( widget, i )
        endfor;
    enddefine;

    if parent then
        mktree( parent, tree )
    else
        xt_new_top_level_shell( 'tree' ) -> parent;
        mktree( parent, tree );
        xt_be_aware( parent )
    endif
enddefine;

endsection
