#!/gsc/bin/perl


#takes one argument, a zero-based bed file
#outputs one-based 5-col lines in 'annotation' format

use warnings;
use strict;
use IO::File;

my $inFh = IO::File->new( $ARGV[0] ) || die "can't open file\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    my @F = split("\t",$line);

    if($F[3] =~ /\//){ #slashed bed file:  1  123   456   A/T

        $F[3] =~ s/\*/-/g; #handle multiple indel markers, change them all to "-:
        $F[3] =~ s/0/-/g;

        my @a = split(/\//,$F[3]);
        
        if (($F[3] =~ /^0/) || ($F[3] =~ /^\-/)){ #indel INS
            $F[2] = $F[2]+1;
            print join("\t",($F[0],$F[1],$F[2],$a[0],$a[1]));
        } elsif (($F[3] =~ /0$/) || ($F[3] =~ /\-$/)){ #indel DEL
            $F[1] = $F[1]+1;
            print join("\t",($F[0],$F[1],$F[2],$a[0],$a[1]));
        } else { #SNV
            $F[1] = $F[1]+1;
            print join("\t",($F[0],$F[1],$F[2],$a[0],$a[1],));
        }
    
        if(@F > 3){
            print "\t" . join("\t",@F[4..$#F])
        }
        print "\n";
    } else { #tabbed bed file:  1  123   456   A  T

        $F[3] =~ s/\*/-/g; #handle multiple indel markers, change them all to "-:
        $F[4] =~ s/\*/-/g;
        $F[3] =~ s/0/-/g;
        $F[4] =~ s/0/-/g;

        if ($F[3] =~ /^\-/){ #indel INS
            $F[2] = $F[2]+1;
            print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));
        } elsif ($F[4] =~ /\-$/){ #indel DEL
            $F[1] = $F[1]+1;
            print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));
        } else { #SNV
            $F[1] = $F[1]+1;
            print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));
        }
    
        if(@F > 4){
            print "\t" . join("\t",@F[5..$#F])
        }
        print "\n";
    }
}
close($inFh);
