#!/gsc/bin/perl

#takes one argument, file with the first 5 columns in one-based 'annotation' format
#converts those columns to zero-based bed format, preserving any trailing columns

use warnings;
use strict;
use IO::File;

my $inFh = IO::File->new( $ARGV[0] ) || die "can't open file\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    my @F = split("\t",$line);
    my @rest = @F[5..$#F];

    next if $line =~/^chromosome_name/;

    #also handle files that have slash-delim alleles (G/T) in 4th column
    if($F[3] =~ /\//){
        my @alleles = split("/",$F[3]);
        #don't lose contents of 4th column
        @rest = @F[4..$#F];

        $F[3] = $alleles[0];
        $F[4] = $alleles[1];        
    }
    
    $F[3] =~ s/\*/-/g; #convert all indels to "-"
    $F[4] =~ s/\*/-/g;
    $F[3] =~ s/0/-/g;
    $F[4] =~ s/0/-/g;

    
    if ($F[3] =~ /\-/){ #indel INS
        $F[2] = $F[2]-1;
        print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));

    } elsif ($F[4] =~ /\-/){ #indel DEL
        $F[1] = $F[1]-1;
        print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));

    } else { #SNV
        $F[1] = $F[1]-1;
        print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));
    }

    if(@rest > 0){
        print "\t" . join("\t",@rest);
    }
    print "\n";

}
close($inFh);
