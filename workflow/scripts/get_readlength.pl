#!/usr/bin/env perl
use warnings;
use strict;

my $usage = "perl get_readlength.pl <samtools> <sample dir file> <unaligned sample_dir> [option]

[options]
    -h : print usage
    ";

if (@ARGV<3){
    die $usage;
}

my $samtools = $ARGV[0];
my $sample_dirs = $ARGV[1];
my $unaligned_file = $ARGV[2];
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $usage;
    }
}

my $tot_length = 0;
my $avg_length = 0;
my $tot_cnt = 0;
open(IN, $sample_dirs);
while(my $sample_dir = <IN>){
    chomp($sample_dir);
    if ($tot_cnt > 30000){
        last;
    }
    my $file_path = $sample_dir . "/" . $aligned_file
    # SAMTOOLS view exclude secondary alignments (-F 256) and second reads in pair (-F 128)
    # totals to -F 384
    my $reads = `$samtools view -F 384 $file_path | head -n 3000 | cut -f 10`;
    my @lines = split(/\n/, $reads);
    foreach my $line (@reads) {
        $tot_length += length($line);
        $tot_cnt++;
    }
}
$avg_length = int($tot_length/$tot_cnt);
print "$avg_length\n";

