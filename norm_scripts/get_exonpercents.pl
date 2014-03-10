if(@ARGV<1) {
    die "Usage: perl get_exonpercents.pl <exonquants file>

<exonquants file> input file with full path

";
}
$total = 0;
$LOC = $ARGV[1];
$quantsfile = $ARGV[0];
$percentfile = $quantsfile;
$percentfile =~ s/quants/percents/;
open(INFILE, $quantsfile);
while($line = <INFILE>){
    chomp($line);
    @a = split(/\t/, $line);
    $quant = $a[2];
    $total = $total + $quant unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
}
close(INFILE);

open(INFILE, $quantsfile);
open(OUTFILE, ">$percentfile");
print OUTFILE "feature\texon%\n";
while($line = <INFILE>){
    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
    }
    else{
	chomp($line);
	@a = split(/\t/, $line);
	$exon = $a[0];
	$quant = $a[2];
	$percent = int(($quant / $total)* 10000 ) / 100;
	print OUTFILE "$exon\t$percent\n";
    }
}
close(INFILE);
close(OUTFILE);

