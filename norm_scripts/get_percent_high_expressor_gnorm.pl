#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_percent_high_expressor_gnorm.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return unique stats.

";
}
my $U = "true";
my $NU = "false";
my $option_found = "false";
for(my $i=2; $i<@ARGV; $i++) {
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $NU = "true";
	$option_found = "true";
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
my $outfileU = "$stats_dir/GENE/percent_high_expressor_gene_Unique.txt";
my $outfileNU = "$stats_dir/GENE/percent_high_expressor_gene_NU.txt";
my %HIGH_GENE;
open(INFILE, "<$ARGV[0]");
my @dirs = <INFILE>;
close(INFILE);
foreach my $dir (@dirs){
    chomp($dir);
    my $id = $dir;
    my $file = "$LOC/$dir/$id.high_expressors_gene.txt";
    open(IN, "<$file");
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
}

my $firstrow = "ensGene";
my $lastrow = "geneSymbol";
while (my ($key, $value) = each (%HIGH_GENE)){
    $firstrow = $firstrow . "\t$key";
    $lastrow = $lastrow . "\t$value";
}

if ($U eq "true"){
    if(-e $outfileU){
	`rm $outfileU`;
    }
    open(OUTU, ">>$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    print OUTU "$firstrow\n";	
}
if ($NU eq "true"){
    if(-e $outfileNU){
	`rm $outfileNU`;
    }
    open(OUTNU, ">>$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    print OUTNU "$firstrow\n";
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $rowU = "$id\t";
    my $rowNU = "$id\t";
    foreach my $gene (keys %HIGH_GENE){
	chomp($gene);
	my $genepercent = "$LOC/$dir/$id.genepercents.txt";
	my $value = `grep -w $gene $genepercent`;
	my @v = split(" ", $value);
	my $val = $v[1];
	if ($U eq "true"){
	    $rowU = $rowU . "$val\t";
	}
	if ($NU eq "true"){
	    $rowNU = $rowNU . "$val\t";
	}
    }
    if($U eq "true") {
	print OUTU "$rowU\n";
    }
    if ($NU eq "true"){
	print OUTNU "$rowNU\n";
    }
}
if ($U eq "true"){
    print OUTU "$lastrow\n";
    close(OUTU);
}
if ($NU eq "true"){
    print OUTNU "$lastrow\n";
    close(OUTNU);
}
close(INFILE);
print "got here\n";
