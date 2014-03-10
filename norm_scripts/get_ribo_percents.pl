$|=1;

if(@ARGV<2) {
    die "Usage: perl get_ribo_percents.pl <sample dirs> <loc> 

<sample dirs> is a file with the names of the sample directories
<loc> is the location where the sample directories are

";
}

$LOC = $ARGV[1];
if (-e "$LOC/ribosomal_counts.txt"){
    `rm "$LOC/ribosomal_counts.txt"`;
}

open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
$i=0;
while($dir = <IN>){
    chomp($dir);
    `sort -u $LOC/$dir/*ribosomalids.txt | wc -l | grep -vw total >> $LOC/ribosomal_counts.txt`;
    $X = $dir;
#    $X =~ s/Sample_//;
    $filename[$i] = $X;
    $i++;
}

$total_num_file = "$LOC/total_num_reads.txt";
open(INFILE, "$LOC/ribosomal_counts.txt") or die "file '$LOC/ribosomal_counts.txt' cannot open for reading.\n";
open(OUTFILE, ">$LOC/ribo_percents.txt") or die "file '$LOC/ribo_percents.txt'\
 cannot open for writing.\n";
print OUTFILE "#ribo\t#reads\t\%ribo\tname\n";
$i=0;
while($line = <INFILE>) {
    chomp($line);
    $cnt = $line;
    $sample_name = $filename[$i];
    $i++;
    $x = `grep -w $sample_name $total_num_file`;
    @x_s = split(" ", $x);
    $total = $x_s[1];
    chomp($total);
    $ratio = int($cnt / $total * 10000) / 10000;
    $x = &format_large_int($total);
    $cnt = &format_large_int($cnt);
    print OUTFILE "$cnt\t$total\t$ratio\t$sample_name\n";
}
close(INFILE);
close(OUTFILE);


sub format_large_int () {
    ($int) = @_;
    @a = split(//,"$int");
    $j=0;
    $newint = "";
    $n = @a;
    for(my $i=$n-1;$i>=0;$i--) {
	$j++;
	$newint = $a[$i] . $newint;
	if($j % 3 == 0) {
	    $newint = "," . $newint;
	}
    }
    $newint =~ s/^,//;
    return $newint;
}
