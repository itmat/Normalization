#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<4){
    my $USAGE = "\nUsage: perl run_shuf_gnorm.pl <file> <line count> <lines wanted> <output>

where:
<file> is a file to be shuffled (full path)
<line count> total number of lines
<lines wanted> number of lines wanted
<output> output full path

";
    die $USAGE;
}

my $filePath = $ARGV[0];
my $line_count = $ARGV[1];
my $min_num = $ARGV[2];
my $output = $ARGV[3];

my $min_readpair = $min_num / 2;

my @array = (1..$line_count);
my @odd;
for(@array){
    push @odd, $_ if $_ % 2;
}

&fisher_yates_shuffle(\@odd);

my %lineWanted;

for (my $i=0;$i<$min_readpair;$i++){
    my $num = $odd[$i];
    $num =~ s/\//_/g;
    chomp($num);
    my $pair = $num + 1;
    $lineWanted{$num} = 1;
    $lineWanted{$pair} = 1;
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


