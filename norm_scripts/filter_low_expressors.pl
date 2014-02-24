if(@ARGV < 3) {
    die  "usage: perl filter_low_expressions.pl <file> <number_of_samples> <cutoff>

where
<file> is quants file without path
<number_of_samples> is number of samples
<cutoff> cutoff value

";
}

$col_num = $ARGV[1];
$cutoff = $ARGV[2];

open(INFILE, $ARGV[0]);
$line = <INFILE>;
print $line;
while($line = <INFILE>) {
    chomp($line);
    @a = split(/\t/,$line);
    $flag = 0;
    $sum = 0;
    for($i=1; $i<=$col_num; $i++) {
	$sum = $sum + $a[$i];
	if($a[$i] > 0) {
	    $flag = 1;
	}
    }
    if($flag == 1 && $sum >= $cutoff) {
	print "$line\n";
    }
}
close(INFILE);
