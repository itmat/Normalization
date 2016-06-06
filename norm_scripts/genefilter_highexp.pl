#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl genefilter_highexp.pl <samfile> <sam2genes output> <outputfile>

<samfile> input samfile
<sam2gene output> output file from sam2gene.pl script
<output file> name of output file

options:
  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.
 
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
while (my $forward = <GENE>){
    if ($pe eq "true"){
	chomp($forward);
	my $reverse = <GENE>;
	chomp($reverse);
	my @f = split(" ", $forward);
	my @r = split(" ", $reverse);
	my $id_f = $f[0];
	my $ih_hi_f = $f[4];
	my $id_r = $r[0];
	my $ih_hi_r = $r[4];
	my $geneid_f = $f[2];
	my $geneid_r = $r[2];
	if (($id_f ne $id_r) | ($ih_hi_f ne $ih_hi_r)){
	    die "$id_f\t$id_r\t$ih_hi_f\t$ih_hi_r\n\"$genesfile\" is not in the right format.\n\n";
	}
	if (($geneid_f =~ /^$/) | ($geneid_r =~ /^$/)){
	    next;
	}
	push (@{$ID{$id_f}}, $ih_hi_f);
    }
    else{
	chomp($forward);
	my @f = split(" ", $forward);
	my $id_f = $f[0];
	my $geneid_f = $f[2];
	my $ih_hi_f = $f[4];
	if ($geneid_f =~ /^$/){
	    next;
	}
	push (@{$ID{$id_f}}, $ih_hi_f);
    }
}
close(GENE);

open(IN, $samfile) or die "cannot find '$samfile'\n";
my $linecount = $output;
my $lc = 0;
open(OUT, ">$output");
while(my $read = <IN>){
    chomp($read);
    if ($read =~ /^@/){
	next;
    }
    my @r = split(/\t/, $read);
    my $id = $r[0];
    $read =~ /HI:i:(\d+)/;
    my $hi_tag = $1;
    $read =~ /(N|I)H:i:(\d+)/;
    my $ih_tag = $2;
    my $ih_hi = "$ih_tag:$hi_tag";
    if (exists $ID{$id}){
	for (my $i=0; $i<@{$ID{$id}};$i++){
	    if ("$ID{$id}[$i]" eq "$ih_hi"){
		print OUT "$read\n";
		$lc++;
	    }
	}
    }
}
close(IN);
close(OUT);
$linecount =~ s/sam$/linecount.txt/;
open(LC, ">$linecount");
print LC "$output\t$lc\n";
close(LC);
#`rm $genesfile`;
print "got here\n";
