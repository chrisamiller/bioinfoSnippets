#!/gsc/bin/perl

use warnings;
use strict;
use IO::File;


#transposes a tab-delimited matrix

my @rows = ();
my @transposed = ();


my $inFh = IO::File->new( $ARGV[0] ) || die "can't open file\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    my @F = split("\t",$line);    
    push(@rows,\@F);
}

for my $row (@rows) {
    for my $column (0 .. $#{$row}) {
        push(@{$transposed[$column]}, $row->[$column]);
    }
}

for my $new_row (@transposed) {
    print join("\t", @{$new_row}) . "\n";
}
