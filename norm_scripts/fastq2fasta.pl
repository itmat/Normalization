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
    `awk 'BEGIN {id=1; seq=2;} NR==id{ sub(/^@/,">",\$0); print \$0; id += 4;} NR==seq{ print \$0; seq += 4}' $fq > $fa`;
}
else{
    `zcat $fq | awk 'BEGIN {id=1; seq=2;} NR==id{ sub(/^@/,">",\$0); print \$0; id += 4;} NR==seq{ print \$0; seq += 4}' | gzip > $fa`;
}

