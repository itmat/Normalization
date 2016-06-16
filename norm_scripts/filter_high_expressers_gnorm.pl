#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE = "\nUsage: perl filter_high_expressers_gnorm.pl <sample dirs> <loc> <genes> <dir> [options]

where:
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<genes> master list of genes file
<dir> name of the sample directory

[option]
 -stranded : set this if the data are strand-specific.

 -u : set this if you want to filter the high expressers from the unique reads, otherwise by default if will filter from both unique and non-unique.

 -nu : set this if you want to filter the high expressers from the non-unique reads, otherwise by default if will filter from both unique and non-unique.
 
 -se : set this if your data are single end.

";

if(@ARGV < 4) {
    die $USAGE;
}
my $stranded = "false";
my $LOC = $ARGV[1];
my $genes = $ARGV[2];
my $se = "false";
my $U = "true";
my $NU = "true";
for(my $i=4; $i<@ARGV; $i++){
    my $option_found = "false";
    if($ARGV[$i] eq '-stranded'){
        $stranded = "true";
        $option_found = "true";
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
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
my %HIGH_GENE_A;
open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $dir = $line;
    my $file = "$LOC/$dir/$id.high_expressers_gene.txt";
    if ($stranded eq "true"){
        $file = "$LOC/$dir/$id.high_expressers_gene.sense.txt";
    }
    open(IN, "$file") or die "cannot find file '$file'\n";
    my $header = <IN>;
    while (my $line2 = <IN>){
	chomp($line2);
	my @a = split(/\t/, $line2);
        my $geneid = $a[0];
        $HIGH_GENE{$geneid} = 1;
    }
    close(IN);
    if ($stranded eq "true"){
        my $file_a = "$LOC/$dir/$id.high_expressers_gene.antisense.txt";
        open(IN, "$file_a") or die "cannot find file '$file_a'\n";
        my $header = <IN>;
        while (my $line2 = <IN>){
            chomp($line2);
            my @a = split(/\t/, $line2);
            my $geneid = $a[0];
            $HIGH_GENE_A{$geneid} = 1;
        }
        close(IN);
    }
}
close(INFILE);
my %FILENAMES = ();
my $sampleid = $ARGV[3];
if ($U eq "true"){
    my $geneu = "$LOC/$sampleid/GNORM/Unique/$sampleid.filtered_u.genefilter.txt";
    if ($stranded eq "true"){
        $geneu = "$LOC/$sampleid/GNORM/Unique/$sampleid.filtered_u.genefilter.sense.txt";
    }
    foreach my $key (keys %HIGH_GENE){
        my $highfile = $geneu;
        $highfile =~ s/.txt$/.$key.txt/;
        open $FILENAMES{$highfile}, ">", $highfile or die "Can't open $highfile for output: $!";
        print {$FILENAMES{$highfile}} "header\n";
    }
    my $filteredu = $geneu;
    $filteredu =~ s/.txt$/.filter_highexp.txt/;
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
                my $highfile = $geneu;
                $highfile =~ s/.txt$/.$key.txt/;
                if (($forward =~ /$key/) || ($reverse =~ /$key/)){
                    $flag = 1;
                    print {$FILENAMES{$highfile}} "$forward\n$reverse\n";
                }
            }
            if ($flag eq '0'){
                print OUT "$forward\n$reverse\n";
            }
        }
        if ($se eq "true"){
            foreach my $key (keys %HIGH_GENE){
                my $highfile = $geneu;
                $highfile =~ s/.txt$/.$key.txt/;
                if ($forward =~ /$key/){
                    $flag = 1;
                    print {$FILENAMES{$highfile}} "$forward\n";
                }
            } 
            if ($flag eq '0'){
                print OUT "$forward\n";
            }
        }
    }
    close(OUT);
    close(IN);
    foreach my $filename (keys %FILENAMES){
        close($FILENAMES{$filename});
    }
    if ($stranded eq "true"){
        %FILENAMES = ();
        my $geneu_a = "$LOC/$sampleid/GNORM/Unique/$sampleid.filtered_u.genefilter.antisense.txt";
        foreach my $key (keys %HIGH_GENE_A){
            my $highfile = $geneu_a;
            $highfile =~ s/.txt$/.$key.txt/;
            open $FILENAMES{$highfile}, ">", $highfile or die "Can't open $highfile for output: $!";
            print {$FILENAMES{$highfile}} "header\n";
        }
        my $filteredu_a = $geneu_a;
        $filteredu_a =~ s/.txt$/.filter_highexp.txt/;
        open(IN, $geneu_a);
        my $header = <IN>;
        open(OUT, ">$filteredu_a");
        print OUT $header;
        while(my $forward = <IN>){
            my $flag = 0;
            chomp($forward);
            if ($se eq "false"){
                my $reverse = <IN>;
                chomp($reverse);
                foreach my $key (keys %HIGH_GENE_A){
                    my $highfile = $geneu_a;
                    $highfile =~ s/.txt$/.$key.txt/;
                    if (($forward =~ /$key/) || ($reverse =~ /$key/)){
                        $flag = 1;
                        print {$FILENAMES{$highfile}} "$forward\n$reverse\n";
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n$reverse\n";
                }
            }
            if ($se eq "true"){
                foreach my $key (keys %HIGH_GENE_A){
                    my $highfile = $geneu_a;
                    $highfile =~ s/.txt$/.$key.txt/;
                    if ($forward =~ /$key/){
                        $flag = 1;
                        print {$FILENAMES{$highfile}} "$forward\n";
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n";
                }
            }
        }
        close(OUT);
        close(IN);
        foreach my $filename (keys %FILENAMES){
            close($FILENAMES{$filename});
        }
    } 
}
if ($NU eq "true"){
    %FILENAMES = ();
    my $genenu = "$LOC/$sampleid/GNORM/NU/$sampleid.filtered_nu.genefilter.txt";
    if ($stranded eq "true"){
        $genenu = "$LOC/$sampleid/GNORM/NU/$sampleid.filtered_nu.genefilter.sense.txt";
    }
    foreach my $key (keys %HIGH_GENE){
        my $highfile = $genenu;
        $highfile =~ s/.txt$/.$key.txt/;
        open $FILENAMES{$highfile}, ">", $highfile or die "Can't open $highfile for output: $!";
        print {$FILENAMES{$highfile}} "header\n";
    }
    my $filterednu = $genenu;
    $filterednu =~ s/.txt$/.filter_highexp.txt/;
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
                my $highfile = $genenu;
                $highfile =~ s/.txt$/.$key.txt/;
                if (($forward =~ /$key/) || ($reverse =~ /$key/)){
                    $flag = 1;
                    print {$FILENAMES{$highfile}} "$forward\n$reverse\n";
                }
            }
            if ($flag eq '0'){
                print OUT "$forward\n$reverse\n";
            }
        }
        if ($se eq "true"){
            foreach my $key (keys %HIGH_GENE){
                my $highfile = $genenu;
                $highfile =~ s/.txt$/.$key.txt/;
                if ($forward =~ /$key/){
                    $flag = 1;
                    print {$FILENAMES{$highfile}} "$forward\n";
                }
            }
            if ($flag eq '0'){
                print OUT "$forward\n";
            }
        }
    }
    close(IN);
    close(OUT);
    foreach my $filename (keys %FILENAMES){
        close($FILENAMES{$filename});
    }
    if ($stranded eq "true"){
        %FILENAMES = ();
        my $genenu_a = "$LOC/$sampleid/GNORM/NU/$sampleid.filtered_nu.genefilter.antisense.txt";
        foreach my $key (keys %HIGH_GENE_A){
            my $highfile = $genenu_a;
            $highfile =~ s/.txt$/.$key.txt/;
            open $FILENAMES{$highfile}, ">", $highfile or die "Can't open $highfile for output: $!";
            print {$FILENAMES{$highfile}} "header\n";
        }
        my $filterednu_a = $genenu_a;
        $filterednu_a =~ s/.txt$/.filter_highexp.txt/;
        open(IN, $genenu_a);
        my $header = <IN>;
        open(OUT, ">$filterednu_a");
        print OUT $header;
        while(my $forward = <IN>){
            my $flag = 0;
            chomp($forward);
            if ($se eq "false"){
                my $reverse = <IN>;
                chomp($reverse);
                foreach my $key (keys %HIGH_GENE_A){
                    my $highfile = $genenu_a;
                    $highfile =~ s/.txt$/.$key.txt/;
                    if (($forward =~ /$key/) || ($reverse =~ /$key/)){
                        $flag = 1;
                        print {$FILENAMES{$highfile}} "$forward\n$reverse\n";
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n$reverse\n";
                }
            }
            if ($se eq "true"){
                foreach my $key (keys %HIGH_GENE_A){
                    my $highfile = $genenu_a;
                    $highfile =~ s/.txt$/.$key.txt/;
                    if ($forward =~ /$key/){
                        $flag = 1;
                        print {$FILENAMES{$highfile}} "$forward\n";
                    }
                }
                if ($flag eq '0'){
                    print OUT "$forward\n";
                }
            }
        }
        close(OUT);
        close(IN);
        foreach my $filename (keys %FILENAMES){
            close($FILENAMES{$filename});
        }
    }
}
print "got here\n";
