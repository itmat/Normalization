#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE = "\nUsage: perl filter_high_expressors.pl <sample dirs> <loc> <exons> [options]

where:
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<exons> the study specific master list of exons or master list of exons file

[option]
 -nu : set this if you want to filter only non-unique expressors, otherwise by default it will only filter the unique.\n";

if(@ARGV < 3) {
    die $USAGE;
}

my $LOC = $ARGV[1];
my $exons = $ARGV[2];
my $new_exons = $exons;
$new_exons =~ s/master_list/filtered_master_list/;
my $annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;
my $highexp_exons = "$LOC/highexp_exons.txt";

my $U = "true";
my $NU = "false";
for(my $i=3; $i<@ARGV; $i++){
    my $option_found = 'false';
    if($ARGV[$i] eq '-nu') {
        $NU = "true";
        $U = "false";
        $option_found = "true";
    }
    if($option_found eq 'false') {
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}

my %HIGH_GENE;
my %EXON_REMOVE;
open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $dir = $line;
    my $file = "$LOC/$dir/$id.high_expressors_exon_annot.txt";
    open(IN, "$file");
    my $header = <IN>;
    while (my $gene = <IN>){
	chomp($gene);
	my @a = split(/\t/, $gene);
        my $exon = $a[0];
	my $list = $a[3];
        my @b = split(',', $list);
        if ($list =~ /^[a-z]?$/){
	   $EXON_REMOVE{$exon} = $exon;
        }
        else{
	   if (@b eq 0){
	      $EXON_REMOVE{$exon} = $exon;
	   }
        }
	for (my $i=0; $i<@b; $i++){
	    if ($b[$i] =~ /^[a-z]?$/){
    	        $EXON_REMOVE{$exon} = $exon;
	    }
            else{
	        $HIGH_GENE{$b[$i]} = $exon;
            }
	}
    }
}
close(INFILE);

my %MASTER_EXON;
open(INFILE, "<$annotated_exons") or die "cannot find \"$annotated_exons\"\n";
open(OUT, ">$highexp_exons");
while(my $line = <INFILE>){
    chomp($line);
    my $flag = 0;
    my @l = split(/\t/, $line);
    my $exon = $l[0];
    $exon =~ s/exon://;
    $MASTER_EXON{$exon} = $exon;
    if (@l > 3){
        my $list2 = $l[2];
        my @b = split(',', $list2);
        for (my $i=0; $i<@b; $i++){
            foreach my $g (keys %HIGH_GENE){
                if ($g eq $b[$i]){
	            $flag = 1;
                } 
            }
        } 
    }
    if (($flag == 1) || (exists $EXON_REMOVE{$exon})){
	delete $MASTER_EXON{$exon};
        print OUT "$exon\n";
    }
}
close(OUT);
open(NEW, ">$new_exons");
foreach my $exon (keys %MASTER_EXON){
    print NEW "$exon\n";
}
close(NEW);
print "got here\n";
