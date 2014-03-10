if(@ARGV<5) {
    die "usage: perl runblast.pl <dir> <loc> <samfile name> <blast dir> <db>

where:

<dir> is the sample dir (without path)
<loc> is the location where the sample dir is
<samfile name> is the name of the sam file (without path)
<blast dir> is the blast dir (full path)
<db> database (full path)
";
}

$dir = $ARGV[0];  # the sample dir (without path)
$LOC = $ARGV[1];  # the location where the sample dirs are
$samfile = $ARGV[2]; # the name of the sam file (without path)
$blastdir = $ARGV[3];
$db = $ARGV[4];
$str = $dir;
$str =~ s/Sample_//;
$str =~ s/\//_/g;

$idsfile = "$LOC/$dir/$str.ribosomalids.txt";
if (-e $idsfile){
    `rm $idsfile`;}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runblast.pl//;

open(INFILE, "$LOC/$dir/$samfile");
while($line = <INFILE>) {
    chomp($line);
    @a = split(/\t/,$line);
    $x = @a;
    if(@a < 8) {
	next;
    } else {
	$len = -1 * (1 + length($line));
	seek(INFILE, $len, 1);
	last;
    }
}
#$cnt_total = 0;
while($line = <INFILE>) {
    open(OUTFILE, ">$LOC/$dir/temp.1");
    @a = split(/\t/,$line);
    $seqnum = $a[0];
    undef %hash;
    $hash{$seqnum} = 1;
    if($hash{$seqnum} == 1) {
	print OUTFILE ">$a[0]";
	print OUTFILE "a\n";
	print OUTFILE "$a[9]\n";
    }  elsif($hash{$seqnum} == 2) {
	print OUTFILE ">$a[0]";
	print OUTFILE "b\n";
	print OUTFILE "$a[9]\n";
    }
    $cnt = 0;
    
    while($cnt < 2000000) {
	$line = <INFILE>;
	chomp($line);
	if($line =~ /\S/) {
	    @a = split(/\t/,$line);
	    $seqnum = $a[0];
	    if(!(exists $hash{$seqnum})) {
		undef %hash;
		$hash{$seqnum} = 0;
	    }
	    $hash{$seqnum}++;
	    if($hash{$seqnum} == 1) {
		$cnt++;
#		$cnt_total++;
		print OUTFILE ">$a[0]";
		print OUTFILE "a\n";
		print OUTFILE "$a[9]\n";
	    }  elsif($hash{$seqnum} == 2) {
		print OUTFILE ">$a[0]";
		print OUTFILE "b\n";
		print OUTFILE "$a[9]\n";
	    }
	} else {
	    last;
	}
    }
    close(OUTFILE);
    $x = `$blastdir/bin/blastn -task blastn -db $db -query $LOC/$dir/temp.1 > $LOC/$dir/blast.out.1 2> $LOC/$dir/blast.out.1_stderr`;
    $x = `perl $path/parseblastout.pl $LOC/$dir/blast.out.1 >> $LOC/$dir/$str.ribosomalids.txt`;
    close(OUT);
}
#$total_num_reads = "$LOC/$dir/total_num_reads.txt";
#open(OUT, ">$total_num_reads");
#print OUT "total = $cnt_total\n";

