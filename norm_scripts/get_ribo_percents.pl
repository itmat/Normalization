#!/usr/bin/env perl
use warnings;
use strict;

$|=1;


my $USAGE =  "Usage: perl get_ribo_percents.pl <sample dirs> <loc> 

<sample dirs> is a file with the names of the sample directories
<loc> is the location where the sample directories are

-alt_stats <s>

";
if(@ARGV<2) {
    die $USAGE;
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";

for(my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
	die $USAGE;
    }
}
for (my $i=2;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-alt_stats'){
	$option_found = "true";
	$stats_dir = $ARGV[$i+1];
	$i++;
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

unless (-d $stats_dir){
    `mkdir -p $stats_dir`;}

if (-e "$LOC/ribosomal_counts.txt"){
    `rm "$LOC/ribosomal_counts.txt"`;
}

open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
my $i=0;
my @filename;
while(my $dir = <IN>){
    chomp($dir);
    my $a = `grep -vwc total $LOC/$dir/*ribosomalids.txt >> $LOC/ribosomal_counts.txt`;
    my $X = $dir;
    $filename[$i] = $X;
    $i++;
}


my $total_num_file = "$stats_dir/total_num_reads.txt";
unless (-e $total_num_file){
    `cp $study_dir/STATS/total_num_reads.txt $stats_dir/`;
}
open(INFILE, "$LOC/ribosomal_counts.txt") or die "file '$LOC/ribosomal_counts.txt' cannot open for reading.\n";
open(OUTFILE, ">$stats_dir/ribo_percents.txt") or die "file '$stats_dir/ribo_percents.txt' cannot open for writing.\n";
print OUTFILE "#ribo\ttotal_num_reads\t\%ribo\tname\n";
$i=0;
while(my $line = <INFILE>) {
    chomp($line);
    my $cnt = $line;
    my $sample_name = $filename[$i];
    $i++;
    my $x = `grep -w $sample_name $total_num_file`;
    my @x_s = split(" ", $x);
    my $total = $x_s[1];
    chomp($total);
    my $ratio = int($cnt / $total * 10000) / 10000 * 100;
    $ratio = sprintf("%.2f", $ratio);
    $x = &format_large_int($total);
    $cnt = &format_large_int($cnt);
    print OUTFILE "$cnt\t$x\t$ratio\t$sample_name\n";
}
close(INFILE);
close(OUTFILE);

`rm $LOC/ribosomal_counts.txt`;

sub format_large_int () {
    (my $int) = @_;
    my @a = split(//,"$int");
    my $j=0;
    my $newint = "";
    my $n = @a;
    for(my $i=$n-1;$i>=0;$i--) {
	$j++;
	$newint = $a[$i] . $newint;
	if($j % 3 == 0) {
	    $newint = "," . $newint;
	}
    }
    $newint =~ s/^,//;
    return $newint;
}
print "got here\n";
