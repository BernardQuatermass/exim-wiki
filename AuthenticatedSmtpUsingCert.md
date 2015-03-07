Scenario: you want a server (acting as a relay) and a client (also running Exim) to establish a mutual trust entirely based on certificates.

The client could be a portable computer that may want to send mail from any network (eg. public WiFi that is untrusted.) This method allows for an encrypted connection; the server to restrict relaying to that client; and also for the client to know for sure that it is talking to the correct server and not some man-in-the-middle.

The client configuration can be readable by all users, and doesn't contain any secret information like a plaintext key. This method works with self-signed certificates, making it thoroughly useful for a personal mail server.

There are two methods used for the client to trust the server, and the server to trust the client. You can use both of these, or just a single one. So they are described here separately.

## Certificates

You'll need your client and relay server to each have a valid certificate pair (the public and private part). Plenty of other documents describe how to do this.

## Relay server to trust the client

There are two steps to establishing the trust. They are checking if the certificate

1. is valid (and dealing with self-signing); and
2. is allowed to relay.

For the first, add the following to the top level of the configuration:

    # Server configuration
    
    # A directory containing trusted certificates
    tls_verify_certificates = /etc/ssl/certs/
    tls_try_verify_hosts = *

Copy the SSL certificate of the client to the directory you gave, and index the directory:

    server# cd /etc/ssl/certs
    server# scp client:/etc/ssl/certs/client.pem ./
    server# c_rehash

Ensure the client is providing the certificate. It's important this is in the specific SMTP driver, and not at the top level of the file.

    # Client configuration
    
    remote_smtp:
        driver = smtp
        # <regular configuration here>
        tls_certificate = /etc/ssl/certs/client.pem
        tls_privatekey = /etc/ssl/private/client.pem

Add an ACL which checks for cases (1) and (2):

    # Server configuration

    # A white-list of certificates which we will allow for relay
    RELAY_FROM_CERTS = HA5H0FMYCERT : HA5H0FAN0THERCERT
    
    acl_check_rcpt:

        # <other ACL rules here>

        # Allow relay if the connection is encrypted and we recognise the
        # certificate. The equivalent warning is a convenient way to get
        # the hash of any new certificates.

        accept  verify        = certificate
                condition     = ${if inlist{${sha256:$tls_in_peercert}}{RELAY_FROM_CERTS}}
                control       = submission
                control       = dkim_disable_verify

        warn    verify        = certificate
                condition     = ${if !inlist{${sha256:$tls_in_peercert}}{RELAY_FROM_CERTS}}
                logwrite      = Attempt to relay from a certificate which has not been explicitly allowed: ${sha256:$tls_in_peercert}

        # <other ACL rules here>

Now all that is needed is to populate the value of `RELAY_FROM_CERTS`. Attempting to send a mail will log the "550 relay not permitted" along with the hash of the valid certificate (it is already in `/etc/ssl/certs`.) The message typically will go to `/var/log/exim/mainlog` where it can be pasted into the configuration file.

This is a great method for a small number of valid clients, but of the number of valid clients gets really large then it is probably more sensible to use a private Certificate Authority.

## The client confirms it's communicating with the right relay server

This part is easier to do, but it's not normally mentioned that this can also be a good method using a self-signed certificate.

First ensure the client trusts the server's certificate. If you're using self-signed and not a Certificate Authority, then do this explicitly:

    client# cd /etc/ssl/certs
    client# scp server:/etc/ssl/certs/server.pem ./

Add an explicit check in the SMTP driver:

    # Client configuration
    #
    # Add the lines below along with your existing configuration for
    # a standard remote SMTP.

    remote_smtp:
        driver = smtp
        # <regular configuration here>
        hosts_require_tls = server.example.com
        tls_verify_certificates = /etc/ssl/certs/server.pem
