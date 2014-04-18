#!/usr/bin/env perl
if(@ARGV < 3) {
    die  "usage: perl filter_high_expressors.pl <sample dirs> <loc> <exons>

where
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<exons> the merged master list of exons or master list of exons file

";
}

$LOC = $ARGV[1];
$exons = $ARGV[2];
$new_exons = $exons;
$new_exons =~ s/master_list/filtered_master_list/;
$new_exons =~ s/merged_list/filtered_master_list/;
$annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;
$annotated_exons =~ s/merged_list/annotated_master_list/;

open(INFILE, $ARGV[0]);
while ($line = <INFILE>){
    chomp($line);
    $id = $line;
    $id =~ s/Sample_//;
    $dir = $line;
    $file = "$LOC/$dir/$id.high_expressors_annot.txt";
    open(IN, "<$file");
    @genes = <IN>;
    close(IN);
    foreach $gene (@genes){
	chomp($gene);
	@a = split(/\t/, $gene);
	$symbol = $a[3];
	$HIGH_GENE{$symbol} = $symbol if (@a > 3);
    }
}
close(INFILE);

open(INFILE, "<$annotated_exons");
@lines = <INFILE>;
close(INFILE);
foreach $line (@lines){
    chomp($line);
    $flag = 0;
    @l = split(/\t/, $line);
    $symbol = $l[1];
    $exon = $l[0];
    $exon =~ s/exon://;
    $MASTER_EXON{$exon} = $exon;
    foreach $g (keys %HIGH_GENE){
	if ($g eq $symbol){
	    $flag = 1;
	}
    }
    if ($flag == 1){
	delete $MASTER_EXON{$exon};
    }
}

open(NEW, ">$new_exons");
foreach $exon (keys %MASTER_EXON){
    print NEW "$exon\n";
}
close(NEW);
