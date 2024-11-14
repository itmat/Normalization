#!/usr/bin/perl
use strict;

my $USAGE = "perl fastq2fasta.pl <fastq> <fasta> [options]

<fastq> full path 
<fasta> full path

option:
 -gz: set this if your fastq file is in .gz format

";

if (@ARGV<2){
    die $USAGE;
}

my $gz = "false";
for(my $i=2;$i<@ARGV;$i++){
    my $option_found= "false";
    if ($ARGV[$i] eq '-gz'){
	$gz = "true";
	$option_found = "true";
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $fq = $ARGV[0];
my $fa = $ARGV[1];
if ($gz eq "false"){
    `awk 'NR%4==1||NR%4==2' $fq | tr '^\@' '>' > $fa`;
}
else{
    `gunzip -c $fq | awk 'NR%4==1||NR%4==2' | tr '^\@' '>' | gzip > $fa`;
}

