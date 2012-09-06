uses vedcompletions;

section $-VedComplete => vedusecompletion;

define global vars procedure vedusecompletion();
    vedtrimline();
    lvars completion = vedthisline();
    ved_q();
    lvars len = finditem().length;
    lvars i;
    for i from len+1 to completion.length do
        vedcharinsert( completion( i ) );
    endfor;
enddefine;

endsection;
