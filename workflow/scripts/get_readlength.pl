#!/usr/bin/env perl
use warnings;
use strict;

my $usage = "perl get_readlength.pl <unaligned> [option]

[options]
    -fa : set this if the input files are in fasta format
    -fq : set this if the input files are in fastq format
    -gz : set this if your input files are compressed
    -h : print usage
    
    ";

if (@ARGV<1){
    die $usage;
}

my $files = $ARGV[0];
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $usage;
    }
}
my $fa = "false";
my $fq = "false";
my $gz = "false";
my $numargs = 0;
for (my $i=1; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-fa'){
        $fa = "true";
        $numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-fq'){
        $fq = "true";
        $numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-gz'){
        $gz = "true";
        $option_found = "true";
    }
    if ($option_found eq "false"){
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

if($numargs ne '1'){
    die "you have to specify an input file type. use either '-fa' or '-fq'\n";
}
my $tot_length = 0;
my $avg_length = 0;
my $tot_cnt = 0;
open(IN, $files);
while(my $line = <IN>){
    chomp($line);
    my $cnt = 0;
    if ($tot_cnt > 30000){
        last;
    }
    if ($fq eq "true"){
	my $x;
        my $rownum = 2;
        while ($cnt < 3000){
            if ($gz eq "true"){
		$x = "zcat $line | sed -n '$rownum" . "{p;q;}'";
	    }
	    else{
                $x = "sed -n '$rownum"."{p;q;}' $line";
	    }
            my $y = `$x`;
            chomp($y);
            my $y_len = length($y);
            if ($y_len eq 0){
                last;
            }
            $tot_length += $y_len;
            unless ($tot_length == 0){
                $cnt++;
                $tot_cnt++;
                $rownum += 4;
            }
        }
    }
    if ($fa eq "true"){
        my $x;
        my $rownum = 2;
        while($cnt < 3000){
            if ($gz eq "true"){
                $x = "zcat $line | sed -n '$rownum" . "{p;q;}'";
	    }
            else{
                $x = "sed -n '$rownum"."{p;q;}' $line";
	    }
            my $y = `$x`;
            chomp($y);
            my $y_len = length($y);
            if ($y_len eq 0){
                last;
            }
            $tot_length += $y_len;
	    unless ($tot_length == 0){
	        $cnt++;
	        $tot_cnt++;
                $rownum += 2;
            }
        }
    }
}
$avg_length = int($tot_length/$tot_cnt);
print "$avg_length\n";

