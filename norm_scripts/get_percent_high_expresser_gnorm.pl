#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_percent_high_expresser_gnorm.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -stranded : set this if the data are strand-specific.

";
}
my $U = "true";
my $option_found = "false";
my $stranded = "false";
for(my $i=2; $i<@ARGV; $i++) {
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found ="true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
unless (-d "$stats_dir/GENE/"){
    `mkdir -p $stats_dir/GENE`;}
my $outfileU = "$stats_dir/GENE/percent_high_expresser_gene.txt";
my $outfileU_A;
if ($stranded eq "true"){
    $outfileU = "$stats_dir/GENE/percent_high_expresser_gene_sense.txt";
    $outfileU_A = "$stats_dir/GENE/percent_high_expresser_gene_antisense.txt";
}
my %HIGH_GENE;
my %HIGH_GENE_A;
open(INFILE, "<$ARGV[0]");
my @dirs = <INFILE>;
close(INFILE);
foreach my $dir (@dirs){
    chomp($dir);
    my $id = $dir;
    my $file = "$LOC/$dir/$id.high_expressers_gene.txt";
    if ($stranded eq "true"){
	$file = "$LOC/$dir/$id.high_expressers_gene.sense.txt";
    }
    open(IN, "<$file") or die "cannot find \"$file\"\n";
    my @genes = <IN>;
    close(IN);
    foreach my $gene (@genes){
	chomp($gene);
	if ($gene =~ /^ens/){
	    next;
	}
	my @g = split(" ", $gene);
	my $name = $g[0];
	my $symbol = $g[2];
	$HIGH_GENE{$name} = $symbol;
    }
    if ($stranded eq "true"){
	my $file_a = "$LOC/$dir/$id.high_expressers_gene.antisense.txt";
	open(IN, "<$file_a") or die "cannot find \"$file_a\"\n";
	my @genes = <IN>;
	close(IN);
	foreach my $gene (@genes){
	    chomp($gene);
	    if ($gene =~ /^ens/){
		next;
	    }
	    my @g = split(" ", $gene);
	    my $name = $g[0];
	    my $symbol = $g[2];
	    $HIGH_GENE_A{$name} = $symbol;
	}
    }
}

my $high_genes_file = "$LOC/high_expressers_gene.txt";
my $high_genes_file_a;
if ($stranded eq "true"){
    $high_genes_file = "$LOC/high_expressers_gene_sense.txt";
    $high_genes_file_a = "$LOC/high_expressers_gene_antisense.txt";
}
open(HIGH, ">$high_genes_file");
foreach my $gene (keys %HIGH_GENE){
    print HIGH "$gene\n";
}
close(HIGH);
if ($stranded eq "true"){
    open(HIGH_A, ">$high_genes_file_a");
    foreach my $gene (keys %HIGH_GENE_A){
        print HIGH_A "$gene\n";
    }
    close(HIGH_A);
}

my $firstrow = "ensGene";
my $lastrow = "geneSymbol";
while (my ($key, $value) = each (%HIGH_GENE)){
    $firstrow = $firstrow . "\t$key";
    $lastrow = $lastrow . "\t$value";
}
my $firstrow_a = "ensGene";
my $lastrow_a = "geneSymbol";
if ($stranded eq "true"){
    while (my ($key, $value) = each (%HIGH_GENE_A)){
	$firstrow_a = $firstrow_a . "\t$key";
	$lastrow_a = $lastrow_a . "\t$value";
    }
}

if(-e $outfileU){
    `rm $outfileU`;
}
open(OUTU, ">>$outfileU") or die "file '$outfileU' cannot open for writing.\n";
print OUTU "$firstrow\n";	
if ($stranded eq "true"){
    if(-e $outfileU_A){
	`rm $outfileU_A`;
    }
    open(OUTU_A, ">>$outfileU_A") or die "file '$outfileU_A' cannot open for writing.\n";
    print OUTU_A "$firstrow_a\n";
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $rowU = "$id\t";
    my $rowU_A = "$id\t";
    foreach my $gene (keys %HIGH_GENE){
	chomp($gene);
	my $genepercent = "$LOC/$dir/$id.genepercents.txt";
	if ($stranded eq "true"){
	    $genepercent = "$LOC/$dir/$id.genepercents.sense.txt";
	}
	my $value = `grep -w $gene $genepercent`;
	my @v = split(" ", $value);
	my $val = $v[1];
	$rowU = $rowU . "$val\t";
    }
    print OUTU "$rowU\n";
    if ($stranded eq "true"){
	foreach my $gene (keys %HIGH_GENE_A){
	    chomp($gene);
	    my $genepercent = "$LOC/$dir/$id.genepercents.antisense.txt";
	    my $value = `grep -w $gene $genepercent`;
	    my @v = split(" ", $value);
	    my $val = $v[1];
	    $rowU_A = $rowU_A . "$val\t";
	}
	print OUTU_A "$rowU_A\n";
    }
}
print OUTU "$lastrow\n";
close(OUTU);
if ($stranded eq "true"){
    print OUTU_A "$lastrow_a\n";
    close(OUTU_A);
}
close(INFILE);
print "got here\n";
