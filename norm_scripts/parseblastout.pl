#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl parseblastout.pl <inputfile>

";

if (@ARGV<1){
    die $USAGE;
}

my %IDs;

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while(my $line = <INFILE>) {
    chomp($line);
    if($line =~ /^\>\ (.*)/) {
        my $id = $1;
	$line = <INFILE>;
	$line = <INFILE>;
	$line = <INFILE>;
	if ($line =~ /Expect\ =\ \d+e-(\d+)/){
	    my $exp = $1;
	    if($exp >= 8) {
                $id =~ s/a$//;
                $id =~ s/b$//;
		my @a = split(" ", $id);
		my $id_only = $a[0];
                if(!(exists $IDs{$id_only})) {
                    $IDs{$id_only}=1;
                    print "$id_only\n";
                }
            }
	}
    }
}
close(INFILE);
