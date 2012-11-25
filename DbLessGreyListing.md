Easy Greylisting Without A Database
===================================

Other variants
--------------

In May 2008 the general algorithm described below was implemented also
in alternative variants without Perl: [using
\${dlfunc](DbLessGreyListingC) and [using
\${run](DbLessGreyListingRun).

Update (2007-07-23)
-------------------

I've been successfully using this script for over a year now, and the
only changes I've made to it are minor spelling and a touch of code
clean-up. I think it's safe to say that it works. Posted below is the
updated script, version 1.0. Also, for your convenience, the updated
script is posted as an attachment to this page.

Introduction
------------

We're a small organization, and I'm a lazy man. I don't really want to
set up and maintain a database server. Especially since for us a
greylist only involves keeping track of a few hundred KB of data at any
one time. So, for your hacking pleasure, I give to you, the "E-Z
Greylisting Without A Database" perl script. If you've compiled exim to
include the perl interpreter then all you have to do is drop in this
script, tweak a few variables to your liking, and add a few lines to
your exim configuration file.

Requirements
------------
-   Exim with an embeded perl interpreter compiled in. (Perl support has
    been compiled in to exim in the Debian distribution since the Sarge
    release, and it works out of the box.)
-   Basic knowledge of your exim configuration file.
-   Rudimentary understanding of PERL. (Enough to be able to spot
    comments and variables, and be able to change a variable's value.)
-   Basic knowledge of UNIX. (Of course.)

The PERL Script
---------------

Save this script somewhere. Don't forget where. (I keep mine in the same
directory as my exim4.conf file: /etc/exim4/perl.pl).

    # use strict;
    use warnings qw(all);
    use diagnostics;
    use IO::File;
    use File::Path;
    use Data::Dumper;

    require 'syscall.ph';

    #
    # Poor Man's Simple Greylisting
    # by Michael Peek <peek@tiem.utk.edu>
    # 2006-05-04
    # Vers. 0.1
    #
    # Update: This script has withstood the test of time.
    # 2007-07-19
    # Vers. 1.0
    #

    # Function:
    #
    # int greylist(<sender_host_address>,<sender_addres>,<recipient_address>)
    #
    # Check the passed triplet for greylisting.
    #
    # Return values:
    # 1 - Defer delivery
    # 0 - Allow delivery
    #
    # Usage:
    #
    # Anywhere in your exim.conf file, wherever you find a connection to be
    # suspicious, call the following:
    #
    # ${perl{greylist}{$sender_host_address}{$sender_address}{$local_part@$domain}}
    #
    # If all three pieces of information are not available do not worry, they need
    # not be.  Their use is up to you.  For instance, if used in the HELO ACL,
    # where $sender_address and $local_part are not yet known, simply calling
    # greylist with the $sender_host_address will greylist solely based on the IP
    # address of the remote host.  If used in the RCPT ACL, all three pieces of
    # information are available and may be used to defer delivery on a
    # recipient-by-recipient basis.
    #
    # Example:
    #
    # defer
    #       condition = ${if ${perl{greylist}{$sender_host_address}{$sender_address}{$local_part@$domain} } }
    #               message = Deferred: Greylisted
    #               log_message = Deferred: Greylisted: ip=$sender_host_address sender=$sender_address recipient=$local_part@$domain
    #

    #
    # When greylisting, how long do we defer delivery?  (In seconds)
    #
    $defer_timeout = 60 * 60 * 1; # 1 hour

    #
    # After passing the greylisting test, how long do we allow? (In seconds)
    #
    $allow_timeout = 60 * 60 * 6; # 6 hours

    #
    # Where we store the greylisting state information
    #
    $state_dir = "/var/cache/exim4";

    #
    # How many bits of an IP address do we want to pay attention to?
    #
    $cidr_mask = 24;

    #
    # Return Codes
    #
    $defer = 1;     # This code is returned if exim is to defer the message
    $allow = 0;     # This code is returned if exim is to allow the message
    $default = $allow;      # In case of an error, return this value.

    #
    # State Information
    #
    # $state_data{'EXPIRE'}
    #       The time that this state expires, in seconds since the epoch.
    #
    # $state_data{'STATE'}
    #   The current state: "allow" or "defer".
    #
    # $state_data{'IP'}
    #       The IP address of the remote host.
    #
    # $state_data{'SENDER'}
    #       The sender's email address.
    #
    # $state_data{'RECIPIENT'}
    #   The recipient's email address.
    #

    # sub masked_ip
    # {
    #       my $ip = shift;
    #       my $bits = shift;
    #       my @ip_array;
    #       my $num;
    #       my $count;
    #       my $mask = 0;
    #
    #       @ip_array = split(".",$ip);
    #       $num = 0;
    #       for ($count = 0; $count < $#ip_array; $count++) {
    #               $num *= 256;
    #               $num += $ip_array[$count];
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #               if ($bits >= 1) { $mask << 1; $mask &= 1; $bits--; }
    #       }
    #       $num = $num & $mask;
    #       while ($num > 0) {
    #               $mask = $num & 255;
    #               if ($ip eq "")
    #                       $ip = $mask;
    #               else
    #                       $ip = $mask.".".$ip;
    #               $num /= 256;
    #       }
    #       return($ip);
    # }

    sub masked_ip
    {
            my $ip = shift;
            my $bits = shift;
            my @ip_array;
            my $num;
            my $count;
            my $mask;

            @ip_array = split(/\./,$ip);

            $num = 0;
            $mask = 0;
            for ($count = 0; $count <= $#ip_array; $count++) {
                    $num *= 256;
                    $num += $ip_array[$count];
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
                    $mask *= 2; if ($bits >= 1) { $mask |= 1; $bits--; }
            }
            $num = $num & $mask;
            $ip = "";
            while ($num >= 1) {
                    $mask = $num & 255;
                    if (length($ip) == 0) {
                            $ip = $mask;
                    }
                    else {
                            $ip = $mask.".".$ip;
                    }
                    $num /= 256;
            }
            return($ip);
    }

    sub timestamp_microseconds
    {
            my $tv;
            my $microseconds;

            $tv = pack("LL",());
            if (syscall(&main::SYS_gettimeofday, $tv, undef) < 0) { return(undef); }
            (undef, $microseconds) = unpack("LL", $tv);
            return(sprintf("%6.6d",$microseconds));
    }

    sub timestamp_seconds
    {
            $seconds = time();
            return($seconds);
    }

    sub read_dir
    {
            my $path = shift;
            my @list;

            if (!-e($path)) { return(undef); }
            if (!-d($path)) { return(undef); }
            if (!opendir(DIR,$path)) { return(undef); }
            @list = grep { ($_ ne '.') && ($_ ne '..') } readdir(DIR);
            closedir(DIR);
            return(@list);
    }

    sub greylist
    {
            my $ip = shift;
            my $sender = shift;
            my $recipient = shift;
            my $now;
            my $timestamp;
            my $state_file;
            my @dir_list;
            my %state_data;

            # Exim::log_write("greylist(\"$ip\",\"$sender\",\"$recipient\") :: BEGIN");

            #
            # Check the state directory
            #
            if (!-e($state_dir)) {
                    Exim::log_write("greylist() :: WARNING: State directory does not exist: ".$state_dir);
                    if (!File::Path::mkpath($state_dir,0,0700)) {
                            Exim::log_write("greylist() :: ERROR: Could not create state directory: ".$state_dir);
                            # Exim::log_write("greylist(\"$ip\",\"$sender\",\"$recipient\") :: END");
                            return($default);
                    }
            }
            if (!-d($state_dir)) {
                    Exim::log_write("greylist() :: ERROR: State directory is not a directory: ".$state_dir);
                    # Exim::log_write("greylist(\"$ip\",\"$sender\",\"$recipient\") :: END");
                    return($default);
            }

            #
            # Get time and timestamp information
            #
            $now = timestamp_seconds();
            $timestamp = $now."-".timestamp_microseconds();

            # Exim::log_write("greylist() :: Time since epoch: ".$now);
            # Exim::log_write("greylist() :: Timestamp: ".$timestamp);

            #
            # Remove expired states from the state directory
            #
            # Exim::log_write("greylist() :: Updating state files...");
            @dir_list = read_dir($state_dir);
            foreach $state_file (@dir_list) {
                    if (!open(STATE_FILE, "< ".$state_dir."/".$state_file)) {
                            Exim::log_write("greylist() :: ERROR: Could not read state file: ".$state_file);
                    }
                    else {
                            undef $/;
                            eval <STATE_FILE>;
                            if ($@) {
                                    Exim::log_write("greylist() :: ERROR: Corrupted state file: ".$state_file);
                                    close(STATE_FILE);
                                    next;
                            }
                            close(STATE_FILE);
                            if ($state_data{'EXPIRE'} < $now) {
                                    if ($state_data{'STATE'} eq "defer") {
                                            # Exim::log_write("greylist() :: Promoting state file: ".$state_file);
                                            $state_data{'STATE'} = "allow";
                                            $state_data{'EXPIRE'} = $now + $allow_timeout;
                                            if (!open(STATE_FILE, "> ".$state_dir."/".$state_file)) {
                                                    Exim::log_write("greylist() :: ERROR: Could not write state file: ".$state_file);
                                            }
                                            else {
                                                    $Data::Dumper::Purity = 1;
                                                    if (!print STATE_FILE Data::Dumper->Dump([\%state_data],['*state_data'])) {
                                                            Exim::log_write("greylist() :: ERROR: Corrupted state file: ".$state_file);
                                                            close(STATE_FILE);
                                                            next;
                                                    }
                                                    close(STATE_FILE);
                                            }
                                    }
                                    else {
                                            # Exim::log_write("greylist() :: Expiring state file: ".$state_file);
                                            if (!unlink($state_dir."/".$state_file)) {
                                                    Exim::log_write("greylist() :: ERROR: Could not delete state file: ".$state_file);
                                            }
                                    }
                            }
                            #else {
                            #       Exim::log_write("greylist() :: In effect: ".$state_file." [".$state_data{'STATE'}."] (".($state_data{'EXPIRE'} - $now)." more seconds)");
                            #}
                    }
            }

            #
            # Check state files for information regarding the state of this triplet
            #
            # Exim::log_write("greylist() :: Checking state files...");
            @dir_list = read_dir($state_dir);
            foreach $state_file (@dir_list) {
                    if (!open(STATE_FILE, "< ".$state_dir."/".$state_file)) {
                            Exim::log_write("greylist() :: ERROR: Could not read state file: ".$state_file);
                    }
                    else {
                            undef $/;
                            eval <STATE_FILE>;
                            if ($@) {
                                    Exim::log_write("greylist() :: ERROR: Corrupted state file: ".$state_file);
                                    close(STATE_FILE);
                                    next;
                            }
                            close(STATE_FILE);
                            if (
                                    (masked_ip($state_data{'IP'},$cidr_mask) eq masked_ip($ip,$cidr_mask))
                                    && ($state_data{'SENDER'} eq $sender)
                                    && ($state_data{'RECIPIENT'} eq $recipient)
                                    )
                            {
                                    if ($state_data{'STATE'} eq "defer") {
                                            # Exim::log_write("greylist() :: "
                                            #       ."Deferring greylisted triplet:"
                                            #       ." ip=".$ip
                                            #       ." sender=".$sender
                                            #       ." recipient=".$recipient
                                            #       );
                                            # Exim::log_write("greylist() :: "
                                            #       ."Deferal is in effect for "
                                            #       .($state_data{'EXPIRE'} - $now)
                                            #       ." more seconds"
                                            #       );
                                            # Exim::log_write("greylist(\"$ip\",\"$sender\",\"$recipient\") :: END");
                                            return($defer);
                                    }
                                    elsif ($state_data{'STATE'} eq "allow") {
                                            # Exim::log_write("greylist() :: "
                                            #       ."Allowing greylisted triplet:"
                                            #       ." ip=".$ip
                                            #       ." sender=".$sender
                                            #       ." recipient=".$recipient
                                            #       );
                                            # Exim::log_write("greylist() :: "
                                            #       ."Allowance is in effect for "
                                            #       .($state_data{'EXPIRE'} - $now)
                                            #       ." more seconds"
                                            #       );
                                            # Exim::log_write("greylist(\"$ip\",\"$sender\",\"$recipient\") :: END");
                                            return($allow);
                                    }
                                    else {
                                            Exim::log_write("greylist() :: ERROR: Corrupted state file: ".$state_file);
                                    }
                            }
                    }
            }
            # Exim::log_write("greylist() :: New triplet discovered");
            $state_file = $timestamp.".".sprintf("%6.6d",$$);
            # Exim::log_write("greylist() :: New state file: ".$state_file);
            $state_data{'STATE'} = "defer";
            $state_data{'IP'} = $ip;
            $state_data{'SENDER'} = $sender;
            $state_data{'RECIPIENT'} = $recipient;
            $state_data{'EXPIRE'} = $now + $defer_timeout;
            if (!open(STATE_FILE, "> ".$state_dir."/".$state_file)) {
                    Exim::log_write("greylist() :: ERROR: Could not write state file: ".$state_file);
            }
            else {
                    $Data::Dumper::Purity = 1;
                    if (!print STATE_FILE Data::Dumper->Dump([\%state_data],['*state_data'])) {
                            Exim::log_write("greylist() :: ERROR: Corrupted state file: ".$state_file);
                            close(STATE_FILE);
                            next;
                    }
                    close(STATE_FILE);
            }
            # Exim::log_write("greylist() :: "
            #       ."Deferring greylisted triplet:"
            #       ." ip=".$ip
            #       ." sender=".$sender
            #       ." recipient=".$recipient
            #       );
            # Exim::log_write("greylist() :: "
            #       ."Deferal is in effect for "
            #       .($state_data{'EXPIRE'} - $now)
            #       ." more seconds"
            #       );
            # Exim::log_write("greylist(\"$ip\",\"$sender\",\"$recipient\") :: END");
            return($defer);
    }

    # vim:ts=2:shiftwidth=2:

Edit the script
---------------

In case of FreeBSD apply the attached patch:
\`attachment:FreeBSD.perl.pl.diff\`\_FreeBSD.perl.pl.diff\`attachment:None\`\_
(it can be used also for other UNIXes with Perl 5.8 or newer).

Open the script with your favorite editor. Edit the location of the perl
binary on the first line, if needed. (I don't think this is necessary
for embeded perl, but just in case...) Edit the values for
\$deny\_timeout, \$allow\_timeout, \$state\_dir, and \$cidr\_mask. There
are comments that explain what these values are for.

When choosing a directory to use as your state directory (\$state\_dir),
be sure that whatever user exim is running as owns the state directory,
and that the permissions on the directory include write by owner.
Otherwise you'll get "Could not write state file" errors.

Edit your exim config file
--------------------------

(I would recommend making a backup copy of your exim configuration file
before tampering with it.)

Take your favorite editor once more and open your exim configuration
file. At the top of the file, before you begin ACL checks or routers or
transports, add the following:

    perl_startup = do '<path-to>/perl.pl'

Where \<path-to\> is the path name of the directory in which you saved
the above script.

Next, find your RCPT acl check, and choose a place within to put
something like this:

    defer
            condition = ${if eq{1}{${perl{greylist}{$sender_host_address}{$sender_address}{$local_part@$domain} } }{true}{false}}
            message = Deferred RCPT: Temporary error, please try again later
            log_message = Deferred RCPT: Greylisted: IP=$sender_host_address, Sender=$sender_address, Rcpt=$local_part@$domain

If you have users logging in with authentication, you may want to add an
additional condition line before the one above that checks to see if the
remote host is authenticated, and fails if they are. That way
authenticated senders are not greylisted when they try to send.

If you're at all squeamish about turning this thing loose on your mail
server, then do what I did and use a test deferal similar to the
following. It has an additional condition that checks the recipient
against "greylist-test", meaning that only messages addressed to
greylist-test will be subjected to greylisting, allowing you to test
things before putting it into use full-time:

    #
    # This is the first test under the RCPT ACL
    #
    # TEST: Greylisting
    # Defer the message:
    # - If the destination is a local domain
    # - If the recipient name is greylist-test
    # - If the greylist returns 1
    defer
            domains = +local_domains
            local_parts = greylist-test
            condition = ${if eq{1}{${perl{greylist}{$sender_host_address}{$sender_address}{$local_part@$domain} } }{true}{false}}
            message = Deferred RCPT: Temporary failure
            log_message = Deferred RCPT: IP: $sender_host_address To: $local_part@$domain From: $sender_address -- greylisted

Restart Exim
------------

Last but not least, restart your exim daemon and watch the log files for
errors.

Caveat Emptor
-------------

This script was cobbled together in a feverish fit of frustration (say
that three times fast) and should be tested thoroughly by you until
you're convinced that it integrates well with your particular email
delivery system without causing problems. That said, I have been running
this script for over a year now and I've never had to touch it. Feel
free to use it, abuse it, hack and slash it, or throw it away if you
like and never think of it again -- but neither I nor my organization
will take any responsibility, explicit or implied, as to the stability
of this code or of the correctness of this approach to greylisting. Use
it at your own risk.

Maintenance
-----------

This script takes care of itself. The only place it saves information is
in the state directory, and in over a year I have never had anything go
wrong with the state information stored in this directory. It creates a
new file for each new data triplet seen; each file lives for
\$deny\_timeout + \$allow\_timeout seconds; then it is automatically
deleted. The contents of each state file is standard PERL text, meaning
that you can open it in your favorite text editor. If anything should go
wrong you can always empty out the state directory, which will force the
script to begin anew. At the time of this writing, my mail server has
144 files files in the state directory, and they only take up a total of
627KB.

Log Messages
------------

Since email is considered to be the vital life's blood of many an
organization, mine included, this script can be very chatty if you want
it to be. I have commented out many of the calls to Exim::log\_write()
that don't contain the text "ERROR", but you can uncomment them if you
like. (With *all* the comments turned on, this script increased the size
of my log files by about 30%, so consider yourself forewarned.)

Here is a comprehensive list of just what kind of malarkey this script
can spit out, and what it all means. I warned you it could be chatty...

    greylist("<IP>","<sender>","<recipient>"):: BEGIN

The greylist function has just been called.

    greylist() :: WARNING: State directory does not exist: <dir>

The directory you have set in \$state\_dir does not exist. The script
will attempt to create that directory.

    greylist() :: ERROR: Could not create state directory: <dir>

The directory you have set in \$state\_dir does not exist, and the
script was unable to create it for you. You will have to create it by
hand, or change the value of \$state\_dir to an existing directory.

    greylist() :: ERROR: State directory is not a directory: <dir>

The directory you have set in \$state\_dir is not a directory at all.
You will need to fix \<dir\> or change the value of \$state\_dir in the
script.

    greylist() :: Time since epoch: <integer>
    greylist() :: Timestamp: <timestamp>

Merely informative dribble. Pay it no mind or comment out these
Exim::log\_write() lines in the script.

    greylist() :: Updating state files...

More informative dribble. The script is combing through all the state
files in the state directory and will update their status.

    greylist() :: State file has dissappeared: <file>

Informative dribble. Most likely another instance of exim is running and
it's call to the perl greylist function has just deleted the expired
state file. This message can crop up if a file exists when greylist()
reads the directory listing, but then a file is removed by the time that
greylist() gets around to trying to open it.

(If you find proof that this is not the case, then what you have found
is a serious bug. If such an event should arise, you should probably
discontinue use of this method of greylisting until you have time to
research the cause and formulate a solution. Oh yeah, and let me know
about it!)

    greylist() :: Error: Could not read state file: <file>

The perl script could not open the state file for reading. This is
usually a bad sign that either something has gone wrong, or someone has
been tampering with the permissions on the file.

    greylist() :: ERROR: Corrupted state file: <file>

The perl script could open the state file for reading, but found that
the contents of the file was not valid perl code. This is usually a bad
sign that either something has gone wrong, or someone has been tampering
with the contents of the file.

    greylist() :: Promoting denied state file: <file>

The denial timeout on this state file has run out, and the file is being
promoted to a state of allowance. If a host connects with matching
IP/sender/recipient triplet data during the allowance timeout then it's
message will not be deferred.

    greylist() :: ERROR: Could not write state file: <file>

An error occurred while attempting to write to a state file. This could
indicate a full partition. The contents of the state file have probably
been lost.

    greylist() :: Deleting expired state file: <file>

The allowance timeout has expires on this state file, and the file is
being deleted.

    greylist() :: ERROR: Could not delete state file: <file>

For whatever reason, this state file could not be removed. This is
likely an indication that something bad has happened, or that someone
has tampered with the file's permissions.

    greylist() :: State file still in effect: <file> [<state>] (<n> more seconds)

There are \<n\> seconds remaining in \<state\> timeout on this file
before the timeout expires.

    greylist() :: Checking state files...

The greylist function has finished updating state files and is now
checking them against the data triplet given for the current message.

    greylist() :: Denying greylisted triplet: ip=<IP> sender=<sender> recipient=<recipient>
    greylist() :: Denial is in effect for <n> more seconds

The data triplet given was found to correspond to a state that is still
in the denial phase for \<n\> more seconds. After this timeout expires
the state file will be promoted to an allowance state.

    greylist() :: Allowing greylisted triplet: ip=<IP> sender=<sender> recipient=<recipient>
    greylist() :: Allowance is in effect for <n> more seconds

The data triplet given was found to correspond to a state that is still
in the acceptance phase for \<n\> more seconds. After this timeout
expires the state file will be deleted.

    greylist() :: New triplet discovered
    greylist() :: New state file: <file>

The data triplet given was not found to correspond to any of the states
recorded. A new state file is being created and the 'deny' timeout will
begin for this state file.

    greylist("<IP>","<sender>","<recipient>") :: END

The greylist function has completed it's processing.

Example Usage
-------------

Here is an example of what the script may churn out during a normal
day's use:

    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist("111.222.33.44","a@b.c","x@y.z") :: BEGIN
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Time since epoch: 1146997537
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Timestamp: 1146997537-055030
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Updating state files...
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146986716-684691 [allow] (5367 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146987481-441173 [allow] (5367 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146988532-155686 [allow] (6439 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146989576-802262 [allow] (7464 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146997376-268296 [deny] (739 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146982396-424249 [allow] (312 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146996385-846274 [allow] (14193 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146996746-542984 [deny] (109 more seconds)
    May  7 06:25:37 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Promoting denied state file: 1146996616-379466
    May  7 06:25:38 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146997330-971642 [deny] (693 more seconds)
    May  7 06:25:38 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: State file still in effect: 1146997483-232621 [deny] (846 more seconds)
    May  7 06:25:38 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Checking state files...
    May  7 06:25:38 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Allowing greylisted triplet: ip=200.105.202.82 sender=a@b.c recipient=x@y.z
    May  7 06:25:38 mail exim[17744]: 2006-05-07 06:25:37 greylist() :: Allowance is in effect for 14193 more seconds
    May  7 06:25:38 mail exim[17744]: 2006-05-07 06:25:37 greylist("111.222.33.44","a@b.c","x@y.z") :: END

Future Enhancement
------------------

If you should discover any bugs, please inform the author. If you have a
fix for this bug, please attach a patch file.
-   File locking would be nice, just in case.
-   Adaptive timeouts would be nice, as a way to deal with the
    occasional spammer who retries over and over again during the denial
    state. After some threshold is reached, the denial timeout could be
    extended.

Have any other bright ideas? The author is looking for ways to improve
this script.
