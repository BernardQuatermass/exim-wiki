Using Exim for Real Time Information Gathering
==============================================

Exim has a very powerful feature [ReadSocket](ReadSocket) that allows
Exim to send simple TCP/IP messages. These messages can be accepted and
stored for real time data processing. The idea is that multiple Exim
installation that are processing email could, for example, send black
list data to a central gathering computer. The central gathering
computer could update in real time a blacklist DNSBL making the
blacklist information available to the world within seconds of minutes
after the event occurred. In this example we'll assume that an Exim
server has detected a virus bot and wants to report the IP address if
the virus to a centralized blacklist. The centralized blacklist is
receiving the TCP messages from many reporters who are all part of a
spam fighting group.

The Exim Sending Code
---------------------

In this example we have Exim servers configured to send simple one line
messages to a central location that is gathering the status of IP
addresses. The message will look like this

    black 1.2.3.4

The message is sent using the Exim [ReadSocket](ReadSocket) feature.

    set acl_c_socket = ${readsocket{inet:listening-server.com:444}{black $sender_host_address\n}{3s}{}{}}

In the above example the message "black" along with the IP address of
the sender is sent on a single line to the host "listening-server.com"
on port 444. You can of course send any messages you can construct. You
might want to send "white" and an IP address to white list.

The Listening End
-----------------

The listening end can be any program that accepts connections and does
something with the information. In this simple example we will just take
the data and store it in a file in /tmp/karma.log.

    socat -u TCP4-LISTEN:444,reuseaddr,fork OPEN:/tmp/karma.log,creat,append&

This file could be harvested once a minute, for example, and processed
into a DNSBL. Or you could do something more interesting like update a
MySQL database that is controlling an DNSBL to make the information
available instantly.

The Purpose
-----------

If a coalition of Exim users organized to provide real time data to an
IP or host name based reputation service where all who participated
shared in the results it could become a powerful spam fighting tool.
Exim with its [ReadSocket](ReadSocket) command is very suited for
such a project.
