#!/usr/bin/env perl
use warnings;
use strict;

$|=1;

if(@ARGV<2) {
    die "Usage: perl get_ribo_percents.pl <sample dirs> <loc> 

<sample dirs> is a file with the names of the sample directories
<loc> is the location where the sample directories are

";
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}

if (-e "$LOC/ribosomal_counts.txt"){
    `rm "$LOC/ribosomal_counts.txt"`;
}

open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
my $i=0;
my @filename;
while(my $dir = <IN>){
    chomp($dir);
    my $a = `sort -u $LOC/$dir/*ribosomalids.txt | wc -l | grep -vw total >> $LOC/ribosomal_counts.txt`;
    my $X = $dir;
    $filename[$i] = $X;
    $i++;
}

open(INFILE, "$LOC/ribosomal_counts.txt") or die "file '$LOC/ribosomal_counts.txt' cannot open for reading.\n";
open(OUTFILE, ">$stats_dir/ribo_percents.txt") or die "file '$stats_dir/ribo_percents.txt' cannot open for writing.\n";
print OUTFILE "#ribo\t#all_mapped\t\%ribo\tname\n";
$i=0;
while(my $line = <INFILE>) {
    chomp($line);
    my $cnt = $line;
    my $sample_name = $filename[$i];
    $i++;
    my $mappingstats_file = "$LOC/$sample_name/$sample_name.mappingstats.txt";
    my $x = `grep "At least one of forward or reverse mapped" $mappingstats_file | tail -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    my $total = $1;
    $total =~ s/,//g;
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
