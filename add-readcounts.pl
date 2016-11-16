#!/gsc/bin/perl

use warnings;
use strict;
use IO::File;

# arg 0 = input SNVs (5 col - chr, pos, pos, ref_allele, var_allele)
# arg 1 = bam-readcount output for those sites


my %refHash;
my %varHash;


#read in all the snvs and hash both the ref and var allele by position
my $inFh = IO::File->new( $ARGV[0] ) || die "can't open file\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    my @fields = split("\t",$line);
    $refHash{$fields[0] . "|" . $fields[1]} = $fields[3];
    $varHash{$fields[0] . "|" . $fields[1]} = $fields[4]
}


#convert weird bases to lists
sub convertIub{
    my ($base) = @_;

    #deal with cases like "A/T" or "C/W"
    if ($base =~/\//){
	my @bases=split(/\//,$base);
	my %baseHash;
	foreach my $b (@bases){
	    my $res = convertIub($b);
	    my @bases2 = split(",",$res);
	    foreach my $b2 (@bases2){
		$baseHash{$b2} = 0;
	    }
	}
	return join(",",keys(%baseHash));
    }

    # use a lookup table to return the correct base
    # there's a more efficient way than defining this, \
    # every time, but meh.
    my %iub_codes;
    $iub_codes{"A"}="A";
    $iub_codes{"C"}="C";
    $iub_codes{"G"}="G";
    $iub_codes{"T"}="T";
    $iub_codes{"U"}="T";
    $iub_codes{"M"}="A,C";
    $iub_codes{"R"}="A,G";
    $iub_codes{"W"}="A,T";
    $iub_codes{"S"}="C,G";
    $iub_codes{"Y"}="C,T";
    $iub_codes{"K"}="G,T";
    $iub_codes{"V"}="A,C,G";
    $iub_codes{"H"}="A,C,T";
    $iub_codes{"D"}="A,G,T";
    $iub_codes{"B"}="C,G,T";
    $iub_codes{"N"}="A,C,G,T";

    return $iub_codes{$base}
}

#
sub matchIub{
    my ($allele,$ref,$var) = @_;
    my @variubs = split(",",convertIub($var));
    my @refiubs = split(",",convertIub($ref));
    foreach my $i (@variubs){
	unless (grep {$_ eq $i} @refiubs) {
	    if ($allele eq $i){
		return 1;
	    }
	}
    }
    return 0;
}


#read in the bam-readcount file
my $inFh2 = IO::File->new( $ARGV[1] ) || die "can't open file\n";
while( my $line = $inFh2->getline )
{
    chomp($line);
    my ($chr, $pos, $ref, $depth, @counts) = split("\t",$line);

    my $ref_count = 0;
    my $var_count = 0;
    my $knownRef;
    my $knownVar;
    my $var_freq = 0;
    
    # skip if it's not in our list of snvs
    next unless (exists($refHash{$chr . "|" . $pos}) && exists($varHash{$chr . "|" . $pos}));

    #for each base at that pos
    foreach my $count_stats (@counts) {
	my ($allele, $count, $mq, $bq) = split /:/, $count_stats;
	
	#look up the snv calls at this position
	$knownRef = $refHash{$chr . "|" . $pos};
	$knownVar = $varHash{$chr . "|" . $pos};

        #handle snvs first
        if($knownRef ne "-" && $knownVar ne "-"){
            # assume that the ref call is ACTG, not iub 
            # (assumption looks valid in my files)
            if ($allele eq $knownRef){
                $ref_count += $count;
            }
            
            # if this base is included in the IUB code for
            # for the variant, (but doesn't match the ref)
            if (matchIub($allele,$knownRef,$knownVar)){
                $var_count += $count;
            }

            if ($depth ne '0') {
                $var_freq = $var_count/$depth * 100;
            }            

        } else { #is an indel, skip it
            $ref_count = "NA";
            $var_count = "NA";
            $var_freq = "NA";
        }
    }


    #output
    print "$chr\t$pos\t$knownRef\t$knownVar\t$ref_count\t$var_count\t";
    if ($var_freq eq "NA"){
        print $var_freq;
    } else {
        printf("%.2f",$var_freq);
    }
    print "\n";
}
