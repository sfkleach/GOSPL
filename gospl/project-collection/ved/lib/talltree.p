;;; Summary: changes showtree to make tall trees

section;

;;; For use with new showtree.

define width(node,name);
    if node_daughters()(node) then
        3
    else
        1
    endif
enddefine;

define height(node,name);
    length(name) + 2
enddefine;

define draw_node(node,val);
vars r1 c1 name c1 c2;

    define box(r1,c1,r2,c2);
        drawline(r1,c1,r2,c1);
        drawline(r1,c1,r1,c2);
        drawline(r1,c2,r2,c2);
        drawline(r2,c1,r2,c2)
    enddefine;

    val --> [?r1 ?r2 ?c1 ?c2];
    node_draw_data()(node) --> [?name ==];
    unless name.isword or name.isstring then
        name><'' -> name
    endunless;
    if node_daughters()(node) then
        box(c1,r1,c2-2,r2);
        c1 + 1 -> c1
    endif;
    vedjumpto(r1+1,c1);
    for i from 1 to length(name) do
        vedcharinsert(name(i));
        vedchardownleft()
    endfor
enddefine;

endsection;
