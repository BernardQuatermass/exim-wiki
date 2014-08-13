This document is describes how to use exim4 as relay server for internal
network. 1. Creating the perl functions: we need to create several perl
functions to be able check authorization at third party mail servers:
The internal mail server in this example have the mail. prefix.

> {{{sub check\_mail\_dot(\$){ my \$host=shift; \$host="mail.".\$host;
> my \$res = Net::DNS::Resolver-\>new(); my \$query =
> \$res-\>search(\$host)
>
> > or return 1;

my \$ip; if (\$query) {

> foreach my \$rr (\$query-\>answer) {
>
> > next unless \$rr-\>type eq "A"; \$ip=\$rr-\>address;
> >
> > > \# the following regexp is eq our network:

my \$regexp=":superscript:\`192.168.1|\`192.168.2|\^192.168.3"

> if ( \$ip !\~ \$regexp ){return 1}
>
> } } else {return 1;};

if ( \$ip !\~ \$regexp ){return 1}

sub pop3auth (\$\$){ my \$login=shift; my \$password=shift; my
\$mailserver=\$login; my
\$hosthelo="H=(".Exim::expand\_string('\$sender\_helo\_name').")
[".Exim::expand\_string('\$sender\_host\_address')."]"; \#warn
"\$hosthelo popauth: login: \$login,password: \$password";
\$mailserver=\~s/.\*@//; \$mailserver="mail.".\$mailserver; my \$host =
\$mailserver; my \$record; my \$res = Net::DNS::Resolver-\>new(); my
\$query = \$res-\>search(\$host)

> or {warn "\$hosthelo Auth failed - could not found \$host " and return
> 1};

my \$ip; if (\$query) {

> foreach my \$rr (\$query-\>answer) {
>
> > next unless \$rr-\>type eq "A"; \$ip=\$rr-\>address;
>
> \# the following regexp is eq our network:

my \$regexp=":superscript:\`192.168.1|\`192.168.2|\^192.168.3"

> if ( \$ip !\~ \$regexp ){warn "\$hosthelo found not our network ip
> (\$host:\$ip)!";return 1}
>
> } } else {warn "\$hosthelo Failed to resolve ip of \$host!"};

my \$pop3 = Net::POP3-\>new(\$mailserver) or {warn "\$hosthelo Auth
failed - could not connect to pop3 server \$mailserver" and return 1};
my \$tot\_msg = \$pop3-\>login(\$login,\$password) or {warn "\$hosthelo
Auth failed - pop3 srever decline \$login,\$password" and return 1};
warn "\$hosthelo Auth passed for \$login with \$password at
\$mailserver"; return 0 } }}}

* * * * *

2.  in the exim configuration we need to make new router,transport and
    authentificator:

<!-- -->

    auth_route:
            driver = manualroute
            condition = ${if match{$authenticated_id}{\@}{1}{0}}
            domains = *
            transport = auth_transport
            route_list = * ${perl{logtohost}{$authenticated_id}}

    auth_transport:
            driver = smtp
            hosts_try_auth = *
            hosts_require_auth = *
    begin authenticators

    plain:
       driver = plaintext
       public_name = PLAIN
       server_prompts = :
       server_condition = "${if eq {${perl{pop3auth}{$2}{$3}} }{0}{1}}"
       server_set_id = $2::$3
       client_send = ^${perl{parse_login}{$authenticated_id}}^${perl{parse_password}{$authenticated_id}}

    login:
       driver = plaintext
       public_name = LOGIN
       server_prompts = "Username:: : Password::"
       server_condition = "${if eq {${perl{pop3auth}{$1}{$2}} }{0}{1}}"
       server_set_id = $1::$2
       client_send = : ${perl{parse_login}{$authenticated_id}}:${perl{parse_password}{$authenticated_id}}

If wish to you use RCPT Callout verification you will need in next
routers:

    verify_router_special:
         driver = manualroute
         domains = +mailertable
         verify_only = true
         transport = remote_smtp
         route_list = * mail.$domain
         condition = ${if match{$authenticated_id}{\@}{1}{0}}
    verify_router:
            driver = dnslookup
            transport = remote_smtp
            verify_only = true
            domains = *
            condition = ${if match{$authenticated_id}{\@}{1}{0}}

* * * * *

> [CategoryHowTo](CategoryHowTo)
