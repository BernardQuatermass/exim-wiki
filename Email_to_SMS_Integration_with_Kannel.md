Here is presented an example router an transport for redirecting mail
addressed to e.g. `user@07123456789.sms` to the Kannel SMS gateway.

We have a workflow system that generates event driven emails, so it was
a natural choice to use Exim for SMS integration, especially after
having already configured Hylafax.

Our Configuration

    * Slackware 12
    * Exim 4.68
    * Kannel SMS gateway
    * Ericsson F251m

The Ericsson F251m is a FCT (Fixed Cellular GSM Terminal), sometimes
known as a "Premicell", that additionally has a RS-232 serial port
allowing it to be controlled by Kannel
[http://www.kannel.org/](http://www.kannel.org/).

I will not discuss configuring Kannel here, other that to remind you
that both the *bearerbox* and *smsbox* daemons should already be
configured, tested and running as described here
[http://www.kannel.org/download/1.4.1/userguide-1.4.1/userguide.html\#AEN4201](http://www.kannel.org/download/1.4.1/userguide-1.4.1/userguide.html#AEN4201).

Your Exim routers section will require something like this:

    sms:
            driver = manualroute
            transport = sms
            route_list ="*.sms"

Transports will require:

    sms:
            driver = pipe
            group = exim
            user = exim
            command = "/usr/bin/lynx -dump \"http://localhost:13013/cgi-bin/sendsms?username=userxxx&password=passzzz&to=${extract{1}{.}{$domain}}&text=${tr{$header_subject:}{ }{+}}\""

this is a simple replace of spaces with "+" though given a little more
time there should be a full URL encoding of the message text (which
comes from the subject line only). A URLEncode expansion operator would
be useful.

Only the subject line is relayed as a SMS. This was for convenience and
compatiblity of being able to already send SMS to some Orange mobile
users through the Orange email to text facility, which similarly
displays the subject line as the SMS text message.
