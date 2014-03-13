if(@ARGV<2) {
    die "Usage: perl get_novel_exons.pl <junctions_all.rum file> <output file>[options]

where
<junctions_all.rum file> input junctions file (needs to be sorted by id)
<output file> output file (full path)

options: -min <n> : min is set at 10 by default
        
         -max <n> : max is set at 2000 by default

";
}

$min = 10;
$max = 2000;
%EXON_START;
$current_n = "1";
$outfile = $ARGV[1];

for($i=2; $i<@ARGV; $i++) {
    $argument_recognized = 0;
    if($ARGV[$i] eq '-min') {
	$min = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-max') {
	$max = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($argument_recognized == 0) {
	die "ERROR: command line arugument '$ARGV[$i]' not recognized.\n";
    }
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
open(OUTFILE, ">$outfile");
$line = <INFILE>;
while($line = <INFILE>){
    chomp($line);
    @a = split(/\t/, $line);
    $intron = $a[0];
    $score = $a[2];
    ($chr, $start, $end) = $intron =~  /^(.*):(\d*)-(\d*)$/g;
    $chr_n = $chr;
    $chr_n =~ s/chr//;
    if ($current_n ne $chr_n){
	for (keys %EXON_START){
	    delete $EXON_START{$_};
	}
    }
    if ($score > 5){
	foreach $exon_start (keys %EXON_START){
	    $diff = $start - $exon_start;
	    if ($diff > $min && $diff < $max){
		print OUTFILE "$chr:$exon_start-$start\n";
	    }
	    if ($diff > $max){
		delete $EXON_START{$exon_start};
	    }
	}
	$EXON_START{$end} = 1;
    }
    $current_n = $chr_n;
}
close(INFILE);
close(OUTFILE);




=comment
foreach $exon_start (keys %EXON_START){
    print "$exon_start\n";
}
