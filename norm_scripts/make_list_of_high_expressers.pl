#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE = "\nUsage: perl make_list_of_high_expressers.pl <sample dirs> <loc> <exons> [options]

where:
<sample dirs> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<exons> the study specific master list of exons or master list of exons file

option:
 -stranded : set this if your data is strand-specific.

";

if(@ARGV < 3) {
    die $USAGE;
}

my $stranded = "false";
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $LOC = $ARGV[1];
my $exons = $ARGV[2];
my $annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;

#non-stranded
my %HIGH_GENE;
my $highexp_exons = "$LOC/high_expressers_exon.txt";
my $highexp_introns = "$LOC/high_expressers_intron.txt";
my %EXON_REMOVE;
my %INTRON_REMOVE;
#stranded
my $highexp_exons_s = "$LOC/high_expressers_exon_sense.txt";
my $highexp_exons_a = "$LOC/high_expressers_exon_antisense.txt";
my $highexp_introns_s = "$LOC/high_expressers_intron_sense.txt";
my $highexp_introns_a = "$LOC/high_expressers_intron_antisense.txt";
my %HIGH_GENE_S;
my %EXON_REMOVE_S;
my %INTRON_REMOVE_S;
my %EXON_REMOVE_A;
my %INTRON_REMOVE_A;
my %STR;

open(INFILE, $ARGV[0]) or die "cannot find \"$ARGV[0]\"\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $dir = $line;
    if ($stranded eq "false"){
	#exon
	my $file = "$LOC/$dir/$id.high_expressers_exon_annot.txt"; #exon
	open(IN, $file) or die "cannot find \"$file\"\n";
	my $header = <IN>;
	while (my $gene = <IN>){
	    chomp($gene);
	    my @a = split(/\t/, $gene);
	    my $exon = $a[0];
	    my $list = $a[3];
	    my @b = split(',', $list);
	    if ($list =~ /^[a-z]?$/){ #gene symbol not available
		$EXON_REMOVE{$exon} = 1;
	    }
	    else{
		if (@b eq 0){
		    $EXON_REMOVE{$exon} = 1;
		}
	    }
	    for (my $i=0; $i<@b; $i++){
		if ($b[$i] =~ /^[a-z]?$/){
		    $EXON_REMOVE{$exon} = 1;
		}
		else{
		    push(@{$HIGH_GENE{$b[$i]}},$exon);
		}
	    }
	}
	close(IN);
	#intron
	my $file_i = "$LOC/$dir/$id.high_expressers_intron.txt"; #intron
	open(IN_I, $file_i) or die "cannot find \"$file_i\"\n";
	$header = <IN_I>;
	while(my $line = <IN_I>){
	    chomp($line);
	    my @a = split(/\t/, $line);
	    my $intron = $a[0];
	    $INTRON_REMOVE{$intron} = 1;
	}
	close(IN_I);
    }
    if ($stranded eq "true"){
	#sense exon
        my $file_s = "$LOC/$dir/$id.high_expressers_exon_annot_sense.txt"; #exon
        open(IN_S, $file_s) or die "cannot find \"$file_s\"\n";
        my $header = <IN_S>;
        while (my $gene = <IN_S>){
            chomp($gene);
            my @a = split(/\t/, $gene);
            my $exon = $a[0];
            my $list = $a[3];
            my @b = split(',', $list);
            if ($list =~ /^[a-z]?$/){ #gene symbol not available
                $EXON_REMOVE_S{$exon} = 1;
            }
            else{
                if (@b eq 0){
                    $EXON_REMOVE_S{$exon} = 1;
                }
            }
	    for (my $i=0; $i<@b; $i++){
                if ($b[$i] =~ /^[a-z]?$/){
                    $EXON_REMOVE_S{$exon} = 1;
                }
                else{
                    push(@{$HIGH_GENE_S{$b[$i]}},$exon);
                }
            }
	}
	close(IN_S);

        #antisense exon
        my $file_a = "$LOC/$dir/$id.high_expressers_exon_antisense.txt"; 
        open(IN_A, $file_a) or die "cannot find \"$file_a\"\n";
        $header = <IN_A>;
        while(my $line = <IN_A>){
            chomp($line);
            my @a = split(/\t/, $line);
            my $exon = $a[0];
            $EXON_REMOVE_A{$exon} = 1;
	}
	close(IN_A);

	#sense intron
        my $file_i_s = "$LOC/$dir/$id.high_expressers_intron_sense.txt"; 
        open(IN_I_S, $file_i_s) or die "cannot find \"$file_i_s\"\n";
        $header = <IN_I_S>;
        while(my $line = <IN_I_S>){
            chomp($line);
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            $INTRON_REMOVE_S{$intron} = 1;
	}
	close(IN_I_S);

	#antisense intron
	my $file_i_a = "$LOC/$dir/$id.high_expressers_intron_antisense.txt";
	open(IN_I_A, $file_i_a) or die "cannot find \"$file_i_a\"\n";
        $header = <IN_I_A>;
        while(my $line = <IN_I_A>){
            chomp($line);
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            $INTRON_REMOVE_A{$intron} = 1;
	}
	close(IN_I_A);
    }
}
close(INFILE);

#non-stranded 
if ($stranded eq "false"){
    ###exon
    open(INFILE, "<$annotated_exons") or die "cannot find \"$annotated_exons\"\n";
    open(OUT, ">$highexp_exons");
    while(my $line = <INFILE>){
	chomp($line);
	my $flag = 0;
	my @l = split(/\t/, $line);
	my $exon = $l[0];
	$exon =~ s/exon://;
	(my $chr, my $exonstart, my $exonend) = $exon =~  /^(.*):(\d*)-(\d*)/;
	if (@l > 3){
	    my $list2 = $l[2];
	    my @b = split(',', $list2);
	    for (my $i=0; $i<@b; $i++){
		foreach my $g (keys %HIGH_GENE){
		    my $size = @{$HIGH_GENE{$g}};
		    for (my $j=0; $j<$size;$j++){
			my $high_exon = $HIGH_GENE{$g}[$j];
			(my $high_chr, my $high_exonstart, my $high_exonend) = $high_exon =~ /^(.*):(\d*)-(\d*)/;
			if (($g eq $b[$i]) && ($chr eq $high_chr)){ #check gene symbol and chr
			    $flag = 1;
			}
		    }
		}
	    }
	}
	if (($flag == 1) || (exists $EXON_REMOVE{$exon})){
	    print OUT "$exon\n";
	}
    }
    close(INFILE);
    close(OUT);
    ###intron
    open (OUT_I, ">$highexp_introns");
    foreach my $intron (keys %INTRON_REMOVE){
	print OUT_I "$intron\n";
    }
    close(OUT_I);
}

#stranded
if ($stranded eq "true"){
    ### sense exon
    open(INFILE, "<$annotated_exons") or die "cannot find \"$annotated_exons\"\n";
    open(OUT_S, ">$highexp_exons_s");
    while(my $line = <INFILE>){
        chomp($line);
        my $flag = 0;
        my @l = split(/\t/, $line);
        my $exon = $l[0];
        $exon =~ s/exon://;
        (my $chr, my $exonstart, my $exonend) = $exon =~  /^(.*):(\d*)-(\d*)/;
        if (@l > 4){
            my $list2 = $l[3];
            my @b = split(',', $list2);
            for (my $i=0; $i<@b; $i++){
                foreach my $g (keys %HIGH_GENE_S){
                    my $size = @{$HIGH_GENE_S{$g}};
                    for (my $j=0; $j<$size;$j++){
                        my $high_exon = $HIGH_GENE_S{$g}[$j];
                        (my $high_chr, my $high_exonstart, my $high_exonend) = $high_exon =~ /^(.*):(\d*)-(\d*)/;
                        if (($g eq $b[$i]) && ($chr eq $high_chr)){ #check gene symbol and chr
                            $flag = 1;
                        }
                    }
                }
            }
        }
        if (($flag == 1) || (exists $EXON_REMOVE_S{$exon})){
            print OUT_S "$exon\n";
        }
    }
    close(INFILE);
    close(OUT_S);
    # antisense exon
    open(OUT_A, ">$highexp_exons_a");
    foreach my $exon (keys %EXON_REMOVE_A){
        print OUT_A "$exon\n";
    }
    close(OUT_A);
    # sense intron
    open (OUT_I_S, ">$highexp_introns_s");
    foreach my $intron (keys %INTRON_REMOVE_S){
        print OUT_I_S "$intron\n";
    }
    close(OUT_I_S);
    # antisense intron
    open (OUT_I_A, ">$highexp_introns_a");
    foreach my $intron (keys %INTRON_REMOVE_A){
        print OUT_I_A "$intron\n";
    }
    close(OUT_I_A);
}

print "got here\n";
