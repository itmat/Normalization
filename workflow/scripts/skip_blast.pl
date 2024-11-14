#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: perl skip_blast.pl <sample_dirs> <loc> 

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

";

my $dirs = $ARGV[0];
my $loc = $ARGV[1];
open(IN,$dirs) or die "cannot find '$dirs'\n";
while(my $id = <IN>){
    chomp($id);
    my $ribofile = "$loc/$id/$id.ribosomalids.txt";
    my $x = `touch $ribofile`;
}
close(IN);

print "got here\n";

