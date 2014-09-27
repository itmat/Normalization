#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl get_master_list_of_genes.pl <ensGenes file> <loc>

<ensGene file> ensembl table must contain columns with the following suffixes: name, chrom, txStart, txEnd, e\
xonStarts, exonEnds, name2, ensemblToGeneName.value
<loc> is where the sample directories are

";

if (@ARGV <2 ){
    die $USAGE;
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my $ensFile = $ARGV[0];
my (%ID, %GENECHR, %GENEST, %GENEEND);
open(ENS, $ensFile) or die "cannot find file \"$ensFile\"\n";
my $header = <ENS>;
chomp($header);
my @ENSHEADER = split(/\t/, $header);
my ($genenamecol, $genesymbolcol, $txchrcol, $txstartcol, $txendcol);
for(my $i=0; $i<@ENSHEADER; $i++){
    if ($ENSHEADER[$i] =~ /.name2$/){
        $genenamecol = $i;
    }
    if ($ENSHEADER[$i] =~ /.ensemblToGeneName.value$/){
        $genesymbolcol = $i;
    }
    if ($ENSHEADER[$i] =~ /.chrom/){
        $txchrcol = $i;
    }
    if ($ENSHEADER[$i] =~ /.txStart/){
        $txstartcol = $i;
    }
    if ($ENSHEADER[$i] =~ /.txEnd/){
        $txendcol = $i;
    }
}

if (!defined($genenamecol) || !defined($genesymbolcol) || !defined($txchrcol) || !defined($txstartcol)|| !defined($txendcol)){
    die "Your header must contain columns with the following suffixes: chrom, txStart, txEnd, name2, ensemblToGeneName.value\n";
}
while(my $line = <ENS>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $txchr = $a[$txchrcol];
    my $txst = $a[$txstartcol];
    my $txend = $a[$txendcol];
    my $geneid = $a[$genenamecol];
    my $genesym = $a[$genesymbolcol];
    $ID{$geneid}= $genesym;
    $GENECHR{$geneid} = $txchr;
    push (@{$GENEST{$geneid}}, $txst);
    push (@{$GENEEND{$geneid}}, $txend);
}
close(ENS);

my $master_list_of_genes = "$LOC/master_list_of_ensGeneIDs.txt";
open(MAS, ">$master_list_of_genes");
foreach my $key (keys %ID){
    my $chr = $GENECHR{$key};
    my $min_st = &get_min(@{$GENEST{$key}});
    my $max_end = &get_max(@{$GENEEND{$key}});
    print MAS "$key\t$ID{$key}\t$chr:$min_st-$max_end\n";
}
close(MAS);

print "got here\n";

sub get_min(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[0];
}

sub get_max(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[@sorted_array-1];
}
