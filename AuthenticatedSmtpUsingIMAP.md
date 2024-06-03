SMTP Authentication using IMAP
==============================

This is a simple solution for SMTP Authentication. It is for those who
have a IMAP server and want to provide Authenticated SMTP for everyone
that has an IMAP account using the same user and password as IMAP uses.
This method does an IMAP call and attempts to log in using the presented
name and password. If it succeeds it logs out and returns true allowing
the user to send email.

The advantage of this method is that it doesn't need to know anything
about the IMAP backend. The assumption is that if IMAP calls to good
then SMTP will call it good too. It eliminates the need to write Exim
code to read the IMAP backend database. If you decide to change IMAP
servers you don't have to change anything in Exim to do user
authentication.

The Perl Solution
-----------------

This method uses EXIM's embedded perl to do the job. You have to load a
perl program at start time and then it makes calls to a perl subroutine.
The Perl routine attempts the IMAP login and returns the result to Exim.
In order to make this work you must first load the Perl script as
follows:

    perl_startup = do '/etc/exim/perl.pl'
    perl_at_start

Then - create a small perl program using this code. In this example the
file is /etc/exim/perl.pl. It requires the perl module Net::IMAP::Simple
(and Net::IMAP::Simple::SSL should you want SSL) be installed. You can
install it using cpan.

    # Simple Version

    use Net::IMAP::Simple;

    sub imapLogin {
       my $host = shift;
       my $account = shift;
       my $password = shift;
       my $server = undef;
       my $result = 0; # (false?)

       # open a connection to the IMAP server
       if (! ($server = new Net::IMAP::Simple($host))) {
          return 0;
       }

       # login, if success set result to 1 (true?)
       if ($server->login( $account, $password )) {
          $result = 1;
       }

       # always close connection to the IMAP server
       $server->close();

       # return authentication result
       return $result;
    }

NB This code used to return '1', i.e. success, if the connection failed
to open. Failing to '0' seems much more secure.

Finally - these authenticators will allow the user and password to be
passed on to the Perl script. It calls the subroutine imapLogin passing
the host, account, and plain text password. If your users use an
encrypted connection the password won't be in the clear.

    ######################################################################
    #                   AUTHENTICATION CONFIGURATION                     #
    ######################################################################

    begin authenticators

    plain:
      driver = plaintext
      public_name = PLAIN
      server_condition = ${perl{imapLogin}{localhost}{$2}{$3}}
      server_set_id = $2

    login:
      driver = plaintext
      public_name = LOGIN
      server_prompts = "Username:: : Password::"
      server_condition = ${perl{imapLogin}{localhost}{$1}{$2}}
      server_set_id = $1

A variation of this code could be used to authenticate from multiple
servers. One could possible do a lookup based on the domain to find the
remote server to connect to and authenticate against that.

### Needed

Need MD5 CRAM/DIGEST version of this code.

* * * * *

Cyrus SASL Solution
-------------------

Exim supports calls to Cyrus SASL and Cyrus can authenticate against
IMAP. Cyrus support needs to be compiled into Exim to work. Here's a
piece of the Makefile that needs to be edited:

    #------------------------------------------------------------------------------
    # Exim has support for the AUTH (authentication) extension of the SMTP
    # protocol, as defined by RFC 2554. If you don't know what SMTP authentication
    # is, you probably won't want to include this code, so you should leave these
    # settings commented out. If you do want to make use of SMTP authentication,  
    # you must uncomment at least one of the following, so that appropriate code is
    # included in the Exim binary. You will then need to set up the run time
    # configuration to make use of the mechanism(s) selected.

    AUTH_CRAM_MD5=yes
    AUTH_CYRUS_SASL=yes
    AUTH_PLAINTEXT=yes
    AUTH_SPA=yes

    #------------------------------------------------------------------------------
    # If you specified AUTH_CYRUS_SASL above, you should ensure that you have the 
    # Cyrus SASL library installed before trying to build Exim, and you probably
    # want to uncomment the following line:

    AUTH_LIBS=-lsasl2

Then - you need to configure your authenticators to talk to the Cyrus
code.

    ######################################################################
    #                   AUTHENTICATION CONFIGURATION                     #
    ######################################################################

    begin authenticators

    plain:
      driver = plaintext
      public_name = PLAIN
      server_condition = ${if saslauthd{{$2}{$3}}{1}{0}}
      server_set_id = $2

    login:
       driver = plaintext
       public_name = LOGIN
       server_prompts = "Username:: : Password::"
       server_condition = ${if saslauthd{{$1}{$2}}{1}{0}}
       server_set_id = $1

You then need to configure the /etc/sysconfig/saslauthd file
(Redhat/Fedora installation).

    # To see a list of authentication mechanisms supported by saslauthd execute this command
    # /usr/sbin/saslauthd -v
    #
    # rimap talks to the local IMAP server

    MECH=rimap

Finally you need to start the daemon:

    service saslauthd start

And set the service to automatically start on bootup:

    chkconfig saslauthd on

If you are running a different distro - these are the general steps that
need to be done. There might be some differences in how you accomplish
it.

External python script version
------------------------------

The python script checking the user credentials (saved in this example
as /usr/local/bin/checkimappw.py)

    import sys
    import imaplib

    """ Test authentication to a IMAPS-server

    usage: checkimappw.py server.example.com username password
    outputs "OK" and sets exit code 0 if logging in was successful
    outputs "error" and sets exit code 1 if logging in was unsuccessful (server not reachable or password incorrect)
    outputs "too few arguments" and sets exit code 2 if called with too few parameters

    """

    def main(args):
      if len(args) < 3:
        print "too few arguments"
        return 2
      try:
        m = imaplib.IMAP4_SSL(args[1])
        m.login(args[2],args[3])
        m.logout()
        print "OK"
        return 0
      except:
        print "error ",sys.exc_info()[0]
        m.logout()
        return 1

    if __name__ == "__main__":
      sys.exit(main(sys.argv))

exim authenticator section:

    begin authenticators

    plain:
      driver = plaintext
      public_name = PLAIN
      server_advertise_condition = ${if eq{$tls_cipher}{}{no}{yes}}
      # username: $auth2, password: $auth3
      server_condition = ${run{/usr/local/bin/checkimappw.py 'server.example.com' '${escape:$auth2}' '${escape:$auth3}'}{yes}{no}}
      server_set_id = $auth2

    login:
      driver           = plaintext
      public_name      = LOGIN
      server_prompts   = Username:: : Password::
      server_advertise_condition = ${if eq{$tls_cipher}{}{no}{yes}}
      # username: $auth1, password: $auth2
      server_condition = ${run{/usr/local/bin/checkimappw.py 'server.example.com' '${escape:$auth1}' '${escape:$auth2}'}{yes}{no}}
      server_set_id    = $auth1

* * * * *

> [CategoryHowTo](CategoryHowTo)
