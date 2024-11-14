if(@ARGV<2) {
    die "Usage: perl sam2readsfa.pl <sam file> <output file>

<sam file> input sam file with full path
<output file> output file name with full path

";}

open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
open(OUTFILE, ">$ARGV[1]") or die "cannot find file \"$ARGV[1]\"\n";

while($line = <INFILE>) {
    chomp($line);
    @a = split(/\t/,$line);
    if(@a < 8) {
	next;
    }
    $a[0] =~ /seq.(\d+)/;
    $seqnum = $1;
    if(!(exists $hash{$seqnum})) {
	undef %hash;
	undef %OUT1;
	undef %OUT2;
	undef %strand1;
	undef %strand2;
	undef %start1;
	undef %start2;
	$hash{$seqnum} = 0;
    }
    $hash{$seqnum}++;
    if($hash{$seqnum} == 1) {
	$OUT1{$seqnum} = $a[9];
	$start1{$seqnum} = $a[3];
	if($a[1] & 32) {
	    $strand1{$seqnum} = "+";
	} else {
	    $strand1{$seqnum} = "-";
	}
	if ($strand1{$seqnum} eq "-"){
	    $temp1 = &reversecomplement($OUT1{$seqnum});
	    $OUT1{$seqnum} = $temp1;
	}
    } elsif($hash{$seqnum} == 2) {
	$OUT2{$seqnum} = $a[9];
	$start2{$seqnum} = $a[3];
	if($a[1] & 32) {
	    $strand2{$seqnum} = "+";
	} else {
	    $strand2{$seqnum} = "-";
	}
	if ($strand2{$seqnum} eq "-"){
            $temp2 = &reversecomplement($OUT2{$seqnum});
            $OUT2{$seqnum} = $temp2;
	}
	$FLAG_x = 0;
	if($strand1{$seqnum} eq "+" && $strand2{$seqnum} eq "-" && $start1{$seqnum} <= $start2{$seqnum}) {
#	    print "$seqnum\t1\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "a\n$OUT1{$seqnum}\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "b\n$OUT2{$seqnum}\n";
	    $FLAG_x = 1;
	}
	if($strand1{$seqnum} eq "+" && $strand2{$seqnum} eq "-" && $start1{$seqnum} > $start2{$seqnum}) {
#	    print "$seqnum\t2\n";
	    $temp1 = &reversecomplement($OUT1{$seqnum});
	    $temp2 = &reversecomplement($OUT2{$seqnum});
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "a\n$temp1\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "b\n$temp2\n";
	    $FLAG_x = 1;
	}
	if($strand1{$seqnum} eq "-" && $strand2{$seqnum} eq "+" && $start1{$seqnum} >= $start2{$seqnum}) {
#	    print "$seqnum\t3\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "a\n$OUT1{$seqnum}\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "b\n$OUT2{$seqnum}\n";
	    $FLAG_x = 1;
	}
	if($strand1{$seqnum} eq "-" && $strand2{$seqnum} eq "+" && $start1{$seqnum} < $start2{$seqnum}) {
#	    print "$seqnum\t4\n";
	    $temp1 = &reversecomplement($OUT1{$seqnum});
	    $temp2 = &reversecomplement($OUT2{$seqnum});
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "a\n$temp1\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "b\n$temp2\n";
	    $FLAG_x = 1;
	}
	if($FLAG_x == 0) {
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "a\n$OUT1{$seqnum}\n";
	    print OUTFILE ">seq.$seqnum";
	    print OUTFILE "b\n$OUT2{$seqnum}\n";
	}
    }
}
close(INFILE);
close(OUTFILE);

sub reversecomplement () {
    ($sq) = @_;
    @A = split(//,$sq);
    $rev = "";
    for($i=@A-1; $i>=0; $i--) {
        $flag = 0;
        if($A[$i] eq 'A') {
            $rev = $rev . "T";
            $flag = 1;
        }
        if($A[$i] eq 'T') {
            $rev = $rev . "A";
            $flag = 1;
        }
        if($A[$i] eq 'C') {
            $rev = $rev . "G";
            $flag = 1;
        }
        if($A[$i] eq 'G') {
            $rev = $rev . "C";
            $flag = 1;
        }
        if($flag == 0) {
            $rev = $rev . $A[$i];
        }
    }
    return $rev;
}
