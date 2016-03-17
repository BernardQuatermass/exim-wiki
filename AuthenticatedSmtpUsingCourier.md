Have exim authenticate against courier authdaemon (thanks to Mark
Bergsma)

Another (and probably better) way to do this is shown in
[[Q0730]]

    plain:
            driver = plaintext
            public_name = PLAIN
            server_prompts = :
            server_condition = ${if eq{${readsocket{COURIERSOCKET}{AUTH
    ${eval:13+${strlen:$2$3}}\nexim\n\login\n$2\n$3\n}{5s}{ } }}{FAIL }{no}{yes}}
            server_set_id = $2

    login:
            driver = plaintext
            public_name = LOGIN
            server_prompts = Username:: : Password::
            server_condition = ${if eq{${readsocket{COURIERSOCKET}{AUTH ${eval:13+${strlen:$1$2}}\nexim\n\login\n$1\n$2\n}{5s}{ } }}{FAIL }{no}{yes}}
            server_set_id = $1

Brian Candler has contributed a comprehensive configuration for the use
of Courier authdaemond, which is uploaded as an
\`attachment:exim-courier-authconf\`\_attachment to this
page.\`attachment:None\`\_
