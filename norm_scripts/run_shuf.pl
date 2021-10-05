#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<4){
    my $USAGE = "\nUsage: perl run_shuf.pl <file> <line count> <lines wanted> <output>

where:
<file> is a file to be shuffled (full path)
<line count> total number of lines
<lines wanted> number of lines wanted
<outfile>

";
    die $USAGE;
}

my $filePath = $ARGV[0];
my $line_count = $ARGV[1];
my $min_num = $ARGV[2];
my $output = $ARGV[3];

my @shuffled = (1..$line_count);
&fisher_yates_shuffle(\@shuffled);

my %lineWanted;

# HACK TO AVOID ARRAY INDEX OUT OF BOUNDS PROBLEMS
if($min_num > $line_count) {
    $min_num = $line_count;
}

for (my $i=0;$i<$min_num;$i++){
    my $num = $shuffled[$i];
    $num =~ s/\//_/g;
    chomp($num);
    $lineWanted{$num} = 1;
}
my $pipecmd = "zcat $filePath";
open(my $fh, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
open(my $OUT, "| /bin/gzip -c > $output") or die "error starting gzip $!";
my $num_lines = keys %lineWanted;
while (<$fh>) {
    if ($lineWanted{$.}) {
	print $OUT $_;
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


