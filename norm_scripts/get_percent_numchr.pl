use warnings;
use strict;

my $USAGE = "perl get_percent_numchr.pl <samfile> <outfile>

<samfile> input samfile (full path)
<outfile> output file (full path)

";

if (@ARGV < 2){
    die $USAGE;
}

my $samfile = $ARGV[0];
my $outfile = $ARGV[1];

my %CHR;
my $TOTAL = 0;
open(IN, $samfile) or die "cannot find $samfile\n";
while(my $line = <IN>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my @a = split(/\t/, $line);
    my $chr = $a[2];
    if ($chr eq "*"){
	next;
    }
    $CHR{$chr}++;
    $TOTAL++
}
close(IN);

open(OUT, ">$outfile");
print OUT "TOTAL:$TOTAL\n";
print OUT "chr\treads\t%\n";
foreach my $key (keys %CHR){
    my $percent = ($CHR{$key}/$TOTAL) * 100;
    print OUT "$key\t$CHR{$key}\t";
    printf OUT "%.2f\n", $percent;
}
print "got here\n";
