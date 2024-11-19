#!/usr/bin/env perl
use warnings;
use strict;

my $usage = "perl get_readlength.pl <aligned files> [option]

[options]
    -h : print usage
";

if (@ARGV<1){
    die $usage;
}

my $tot_length = 0;
my $avg_length = 0;
my $tot_cnt = 0;
for my $line (@ARGV) {
    my $cnt = 0;
    if ($tot_cnt > 30000){
        last;
    }
    my $rownum = 2;
    my @reads = split /\n/, `samtools view $line | cut -f 10 | head -n 3000`;
    for my $read (@reads) {
        chomp($read);
        my $read_len = length($read);
        $tot_length += $read_len;
        if ($read_len eq 0){
            last;
        }
        $cnt++;
        $tot_cnt++;
    }
}
$avg_length = int($tot_length/$tot_cnt);
print "$avg_length\n";

