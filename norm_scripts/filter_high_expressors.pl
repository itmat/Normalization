#!/usr/bin/env perl
if(@ARGV < 3) {
    die  "usage: perl filter_high_expressors.pl <sample dirs> <loc> <exons>

where
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<exons> the study specific master list of exons or master list of exons file

";
}

$LOC = $ARGV[1];
$exons = $ARGV[2];
$new_exons = $exons;
$new_exons =~ s/master_list/filtered_master_list/;
$annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;

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
	if (@a > 3){
	    $list = $a[4];
	    @b = split(',', $list);
	    for ($i=0; $i<@b; $i++){
		$HIGH_GENE{$b[$i]} = $b[$i];
	    }
	}
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
    $list = $l[2];
    $exon = $l[0];
    $exon =~ s/exon://;
    $MASTER_EXON{$exon} = $exon;
    @b = split(',', $list);
    for ($i=0; $i<@b; $i++){
	foreach $g (keys %HIGH_GENE){
	    if ($g eq $b[$i]){
		$flag = 1;
	    }
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
print "got here\n";
