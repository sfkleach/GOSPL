compile_mode :pop11 +strict;

section;


global vars cgi_env_names = [
    'SERVER_SOFTWARE'
    'SERVER_NAME'
    'GATEWAY_INTERFACE'
    'SERVER_PROTOCOL'
    'SERVER_PORT'
    'PATH_INFO'

    'PATH_TRANSLATED'
    'SCRIPT_NAME'
    'QUERY_STRING'
    'REMOTE_HOST'
    'REMOTE_ADDR'
    'AUTH_TYPE'
    'REMOTE_USER'
    'REMOTE_IDENT'
    'CONTENT_TYPE'
    'CONTENT_LENGTH'

    'HTTP_ACCEPT'
    'HTTP_USER_AGENT'
];

endsection;
