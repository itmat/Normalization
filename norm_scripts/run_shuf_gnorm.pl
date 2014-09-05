#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<3){
    my $USAGE = "\nUsage: perl run_shuf.pl <file> <line count> <lines wanted>

where:
<file> is a file to be shuffled (full path)
<line count> total number of lines
<lines wanted> number of lines wanted

";
    die $USAGE;
}

my $filePath = $ARGV[0];
my $line_count = $ARGV[1];
my $min_num = $ARGV[2];

my @shuffled = (1..$line_count);
&fisher_yates_shuffle(\@shuffled);

my %lineWanted;

for (my $i=0;$i<$min_num;$i++){
    my $num = $shuffled[$i];
    $num =~ s/\//_/g;
    chomp($num);
    $lineWanted{$num} = 1;
}

open (my $fh, "<$filePath") or die "Unable to open file \"$filePath\": $!\n";
my $num_lines = keys %lineWanted;
while (<$fh>) {
    if ($lineWanted{$.}) {
	print;
	last unless --$num_lines;
    }
}

# randomly permutate @array in place
sub fisher_yates_shuffle{
    my $array = shift;
    my $i = @$array;
    while ( --$i ){
        my $j = int rand( $i+1 );
        @$array[$i,$j] = @$array[$j,$i];
    }
}


