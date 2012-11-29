#!/opt/perl/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Slurp;
use File::Spec;
use IO::Dir;
use IO::File;

# -------------------------------------------------------------------
sub rewrite_file_content {
    my $fn   = shift;
    my $hash = shift;

    my $fh     = IO::File->new( $fn, 'r' ) || die;
    my $outstr = '';
    my $state  = 0;
    while (<$fh>) {
        if ( $state == 0 ) {
            next unless (/^Q/);
            $state++;
        }
        $outstr .= $_;
        if ( $state == 1 ) {
            chomp;
            next unless (/^[A-Za-z0-9]/);
            next if (/^Q\d/);
            next if (/^(?:Question|Answer)/);
            $hash->{ basename( $fn, '.md' ) } = $_;
            $state++;
        }
        if ( $state == 2 ) {
            last if (/\* \* \* \* \*/);
        }
    }
    write_file( $fn, $outstr );
}

# -------------------------------------------------------------------
sub process_dir {
    my $dirname = shift;

    my $hash = {};
    my $dh = IO::Dir->new($dirname) || die;
    my $de;
    while ( defined( $de = $dh->read ) ) {
        next unless ( $de =~ /^Q/ );
        my $fp = File::Spec->catfile( $dirname, $de );
        rewrite_file_content( $fp, $hash );
    }
    my $title = $dirname;
    $title =~ s/_/ /g;
    my $fhs = IO::File->new( File::Spec->catfile( $dirname, '_Sidebar.md' ), 'w' ) || die;
    my $fht = IO::File->new( $dirname . '.md', 'w' ) || die;
    $fht->printf( "%s\n====\n\n", $title );
    foreach ( sort keys %{$hash} ) {
        $fhs->printf( "- [%s](%s)\n",  $hash->{$_},$_ );
        $fht->printf( "- [%s - %s](%s)\n", $_, $hash->{$_},$_ );
    }
}

# -------------------------------------------------------------------
sub process_set {

    my $dh = IO::Dir->new('.') || die;
    my $de;
    while ( defined( $de = $dh->read ) ) {
        next unless ( $de =~ /^[A-Za-z0-9]/ );
        next unless ( -d $de );
        process_dir($de);
    }
}

# -------------------------------------------------------------------

process_set
