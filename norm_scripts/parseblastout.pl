#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl parseblastout.pl <id> <loc>
";

if (@ARGV<2){
    die $USAGE;
}


my $id = $ARGV[0];
my $LOC = $ARGV[1];
my $IDS = "$LOC/$id/$id.ribosomalids.txt";
my $database1 = "blastdb1.$id";
my $database2 = "blastdb2.$id";
my %RIBO = ();
open(OUT, ">$IDS");
my @g = glob("$LOC/$id/$database1*blastout*");
if (@g > 0){
    foreach my $file (@g){
	open(IN, $file);
	while(my $line = <IN>) {
	    chomp($line);
                if($line =~ /\s\d+e-(\d+)/) {
                    my $exp = $1;
                    if (($line =~ /Score/) && ($line =~ /Expect/)){
                        next;
                    }
                    my @a = split(" " ,$line);
                    my $id = $a[0];
                    if($exp >= 8) {
			if(!(exists $RIBO{$id})) {
			    print OUT "$id\n";
                            $RIBO{$id}=1;
			}
                    }
		}
	}
	close(IN);
    }
}
my @g2 = glob("$LOC/$id/$database2*blastout*");    
if (@g2 > 0){
    foreach my $file (@g2){
	open(IN, $file);
	while(my $line = <IN>) {
	    chomp($line);
	    if($line =~ /\s\d+e-(\d+)/) {
		my $exp = $1;
		if (($line =~ /Score/) && ($line =~ /Expect/)){
		    next;
		}
		my @a = split(" " ,$line);
		my $id = $a[0];
		if($exp >= 8) {
		    if(!(exists $RIBO{$id})) {
			print OUT "$id\n";
			$RIBO{$id}=1;
		    }
		}
	    }
	}
	close(IN);
    }
}
close(OUT);
my @t = glob("$LOC/$id/$database1*");
if (@t>0){
    `rm $LOC/$id/$database1*`;
}
my @t2 = glob("$LOC/$id/$database2*");
if (@t2>0){
    `rm $LOC/$id/$database2*`;
}
my $tempq = "$LOC/$id/query.temp";
my @tqfiles = glob("$tempq*");
if (@tqfiles > 0){
    `rm $tempq*`;
}

print "got here\n";

