Sometimes some of the automatic spam systems try just to connect and
send smtp command not waiting for a banner or any response from our SMTP
server. To protect from such behavior we provide some delays.

In this example we delay only banner advertisement which is enough to
detect such behavior. If you want you can provide delay on the other
SMTP commands, but i think it's not necessary.

If your SMTP server is used to receive and send e-mails it's problem for
your clients delaying them. To prevent it, we set exim to listen on two
different IPs. One of them is used as mx for our domains, and another ip
is used for our clients to send their e-mails. We do delaying only for
one of those IPs - the MX one.

To get random numbers i use mysql.

    acl_connect:

       accept hosts = *
              condition   = ${if eq{$interface_address}{xx.xx.xx.xx}{1}{0}}
              delay       = ${lookup mysql{SELECT OCT(RAND()*10)}}s

    accept

Alle the clients that does not wait for a banner are rejected with
protocol violation message.
