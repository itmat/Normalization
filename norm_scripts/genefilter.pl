#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl genefilter.pl <samfile> <sam2genes output> <outputfile>

<samfile> input samfile
<sam2gene output> output file from sam2gene.pl script
<output file> name of output file

options:

  -se :  set this if the data is single end, otherwise by default it will assume it's a paired end data.

* Only keeps a read pair/read when both forward and reverse read maps to gene.

";

if (@ARGV<3){
    die $USAGE;
}
my $pe = "true";
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
my $samfile = $ARGV[0];
my $genesfile = $ARGV[1];
my $output = $ARGV[2];

my %ID;
open(GENE, $genesfile) or die "cannot find '$genesfile'\n";
my $header = <GENE>;
my ($nf, $nr);
while (my $forward = <GENE>){
    if ($pe eq "true"){
	chomp($forward);
	my $reverse = <GENE>;
	chomp($reverse);
	my @f = split(/\t/, $forward);
	my $size_f = @f;
	my @r = split(/\t/, $reverse);
	my $size_r = @r;
	my $id_f = $f[0];
	my $index_f = $f[4];
	my $id_r = $r[0];
	my $index_r = $r[4];
	my $geneid_f = $f[2];
	my $geneid_r = $r[2];
	if (($geneid_f =~ /^$/) | ($geneid_r =~ /^$/)){
	    next;
	}
	push (@{$ID{$id_f}}, $index_f);
    }
    else{
	chomp($forward);
	my @f = split(/\t/, $forward);
        my $id_f = $f[0];
	my $geneid_f = $f[2];
	my $index_f = $f[4];
	if ($geneid_f =~ /^$/){
            next;
        }
	push (@{$ID{$id_f}}, $index_f);
    }
}
close(GENE);

open(IN, $samfile) or die "cannot find '$samfile'\n";
my $linecount = $output;
my $lc = 0;
open(OUT, ">$output");
while(my $read = <IN>){
    chomp($read);
    my @r = split(/\t/, $read);
    my $id = $r[0];
    $read =~ /HI:i:(\d+)/;
    my $index = $1;
    if (exists $ID{$id}){
	if ($pe eq "true"){
	    for (my $i=0; $i<@{$ID{$id}};$i++){
		if ("$ID{$id}[$i]" eq "$index"){
		    print OUT "$read\n";
		    $lc++;
		}
	    }
	}
	else{
	    print OUT "$read\n";
	    $lc++;
	}
    }
}
close(IN);
close(OUT);
$linecount =~ s/sam/linecount.txt/g;
open(LC, ">$linecount");
print LC "$output\t$lc\n";
close(LC);
print "got here\n";
