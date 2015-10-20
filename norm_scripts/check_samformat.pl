#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl check_samformat.pl <samfile> 

option:
 -se: set this for single end data

";

if (@ARGV<1){
    die $USAGE;
}
my $pe = "true";
for (my $i=1; $i<@ARGV;$i++){
    my $option_found ="false";
    if ($ARGV[$i] eq "-se"){
	$pe = "false";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
my $cnt = 0;
open(SAM, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
while (!eof SAM){
    my $first = <SAM>;
    if ($first =~ /^@/){
	next;
    }
    if ($cnt > 100000){
	last;
    }
    $cnt++;
    my @a = split(/\t/,$first);
    my $chr = $a[2];
    #check (N|H)I and IH tag
    if ($chr ne "*"){
	unless ($first =~ /HI:i:/){
	    die "\nINPUT FORMAT ERROR: SAM file \"$ARGV[0]\" must have the HI tag.\n\n$first\n";
	}
	unless ($first =~ /(N|I)H:i:/){
	    die "\nINPUT FORMAT ERROR: SAM file \"$ARGV[0]\" must have the NH or IH tag.\n\n$first\n";
	}
    }
    #make sure SAM is sorted by readname+pair (for paired end data)
    if ($pe eq "true"){
	chomp($first);
	my @f = split(/\t/,$first);
	my $f_read_id = $f[0];
	my $f_bitflag = $f[1];
	$chr = $f[2];
	my $f_tag = 0;
	unless ($chr eq "*"){
	    if ($first =~ /HI:i:(\d+)/){
		$first =~ /HI:i:(\d+)/;
		$f_tag = $1;
	    }
	    else{
		die "\nINPUT FORMAT ERROR: SAM file \"$ARGV[0]\" must have the HI tag.\n\n$first\n";
	    }
	}
	my $second = <SAM>;
	chomp($second);
	my @s = split(/\t/,$second);
	my $s_read_id = $s[0];
	my $s_bitflag = $s[1];
	$chr = $s[2];
	my $s_tag = 0;
	unless ($chr eq "*"){
            if ($second =~ /HI:i:(\d+)/){
		$second =~ /HI:i:(\d+)/;
		$s_tag = $1;
	    }
	    else{
                die "\nINPUT FORMAT ERROR: SAM file \"$ARGV[0]\" must have the HI tag.\n\n$second\n";
            }
	}
	if ($f_read_id ne $s_read_id){
	    die "\nINPUT FORMAT ERROR:\nPaired End data -- mated alignments need to be in adjacent lines.\n\n$first\n$second\n";
	}
	unless (($f_tag eq 0) || ($s_tag eq 0)){
	    if (($f_read_id ne $s_read_id) || ($f_tag ne $s_tag)){
		die "\nINPUT FORMAT ERROR:\nPaired End data -- mated alignments need to be in adjacent lines.\n\n$first\n$second\n";
	    }
	}
    }
}
close(SAM);
print "got here\n";
