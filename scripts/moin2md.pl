#!/opt/perl/bin/perl

use strict;
use warnings;
use File::Slurp;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->cookie_jar( {} );
$ua->agent(
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11'
);

while (<>) {
    chomp;
    next unless ($_);
    my $url = sprintf( 'http://wiki.exim.org/%s?action=format&mimetype=text/x-rst', $_ );
    my $out = sprintf( '%s.md', $_ );
    next if ( -f $out );
    my $response = $ua->get($url);

    if ( $response->is_success ) {
        write_file( $out, { binmode => ':utf8' }, $response->decoded_content );
        print $out, "\n";

        # sleep(1);
    }
    else {
        warn $out, ' ', $response->status_line;
        sleep(4);
    }

}
