#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE = "\nUsage: perl filter_high_expressors_gnorm.pl <sample dirs> <loc> <genes> [options]

where:
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<genes> master list of genes file

[option]
 -nu : set this if you want to filter only non-unique expressors, otherwise by default it will return unique.
 -se : set this if your data is single end.

";

if(@ARGV < 3) {
    die $USAGE;
}

my $LOC = $ARGV[1];
my $genes = $ARGV[2];
my $new_genes = $genes;
$new_genes =~ s/master_list/filtered_master_list/;
my $se = "false";
my $U = "true";
my $NU = "false";
for(my $i=3; $i<@ARGV; $i++){
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $NU = "true";
        $option_found = "true";
    }
    if($ARGV[$i] eq '-se') {
        $se = "true";
        $option_found = "true";
    }
    if($option_found eq 'false') {
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}

my %HIGH_GENE;
open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $dir = $line;
    my $file = "$LOC/$dir/$id.high_expressors_gene.txt";
    open(IN, "$file") or die "cannot find file '$file'\n";
    my $header = <IN>;
    while (my $line2 = <IN>){
	chomp($line2);
	my @a = split(/\t/, $line2);
        my $geneid = $a[0];
        $HIGH_GENE{$geneid} = 1;
    }
}
close(INFILE);

open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while (my $line = <INFILE>){
    chomp($line);
    if (-d "$LOC/$line/GNORM/Unique/"){
        my $geneu = "$LOC/$line/GNORM/Unique/$line.filtered_u.genes.txt";
        my $filteredu = "$LOC/$line/GNORM/Unique/$line.filtered_u.genes2.txt";
        open(IN, $geneu);
        my $header = <IN>;
        open(OUT, ">$filteredu");
        print OUT $header;
        while(my $forward = <IN>){
            my $flag = 0;
            chomp($forward);
            if ($se eq "false"){
                my $reverse = <IN>;
                chomp($reverse);
                foreach my $key (keys %HIGH_GENE){
                    if (($forward =~ /$key/) || ($reverse =~ /$key/)){
                        $flag = 1;
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n$reverse\n";
                }
            }
            if ($se eq "true"){
                foreach my $key (keys %HIGH_GENE){
                    if ($forward =~ /$key/){
                        $flag = 1;
                    }
                } 
                if ($flag eq '0'){
                    print OUT "$forward\n";
                }
            }
        }
    }
    close(IN);
    close(OUT);
    if (-d "$LOC/$line/GNORM/NU/"){
        my $genenu = "$LOC/$line/GNORM/NU/$line.filtered_nu.genes.txt";
        my $filterednu = "$LOC/$line/GNORM/NU/$line.filtered_nu.genes2.txt";
        open(IN, $genenu);
        my $header = <IN>;
        open(OUT, ">$filterednu");
        print OUT $header;
        while(my $forward = <IN>){
            my $flag = 0;
            chomp($forward);
            if ($se eq "false"){
                my $reverse = <IN>;
                chomp($reverse);
                foreach my $key (keys %HIGH_GENE){
                    if (($forward =~ /$key/) || ($reverse =~ /$key/)){
                        $flag = 1;
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n$reverse\n";
                }
            }
            if ($se eq "true"){
                foreach my $key (keys %HIGH_GENE){
                    if ($forward =~ /$key/){
                        $flag = 1;
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n";
                }
            }
        }
    }
    close(IN);
    close(OUT);
}

open(INFILE, "<$genes") or die "cannot find \"$genes\"\n";
open(NEW, ">$new_genes");
while(my $line = <INFILE>){
    chomp($line);
    my @l = split(/\t/, $line);
    my $geneid = $l[0];
    if (exists $HIGH_GENE{$geneid}){
        next;
    }
    print NEW "$line\n";
}
close(INFILE);
close(NEW);
print "got here\n";
