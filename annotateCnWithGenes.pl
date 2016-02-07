#!/gsc/bin/perl

#takes two files:
#arg0 = copy number file - standard 5-column CBS output (chr, start, stop, num.probes, seg.mean)
#arg1 = bed file containing "blocked" gene names and positions (chr, start, stop, geneName)
#       where blocked means one line per gene - start of gene to end of gene

#outputs original CN calls with comma-separated gene names appended
#
#assumes that bedtools is installed

use warnings;
use strict;
use IO::File;

`intersectBed -a $ARGV[0] -b $ARGV[1] -wao >$ARGV[0].geneint`;


my %cnHash;

my $inFh = IO::File->new( "$ARGV[0].geneint" ) || die "can't open file\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    my @F = split("\t",$line);

    my @gene = split(/:/,$F[8]);
    $cnHash{join("\t",@F[0..4])}{$gene[0]} = 1;
}
close($inFh);

foreach my $k (keys(%cnHash)){
    my @genes;
    foreach my $g (keys(%{$cnHash{$k}})){
        push(@genes,$g)
    }
    print $k . "\t" . join(",",@genes) . "\n";
}
