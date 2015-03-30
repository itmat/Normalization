#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<4) {
    die "Usage: perl get_exon_intron_percents.pl <sample directory> <cutoff> <outfile_exon> <outfile_intron> [options]

<sample directory> 
<cutoff> cutoff %
<outfile_exon> output exonpercents file with full path
<outfile_intron> output intronpercents file with full path

option:
  -nu :  set this if you want to return only non-unique exonpercents and intronpercents, 
         otherwise by default it will return unique exonpercents and intronpercents.

  -stranded : set this if your data are strand-specific.

";
}

my $U = "true";
my $NU = "false";
my $stranded = "false";
for(my $i=4; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$NU = "true";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}


my $sampledir = $ARGV[0];
my @a = split("/", $sampledir);
my $dirname = $a[@a-1];
my $id = $dirname;
#non-stranded
##exon
my $total_u = 0;
my $total_nu = 0;
my $quantsfile_u = "$sampledir/EIJ/Unique/$id.filtered_u.exonquants";
my $quantsfile_nu = "$sampledir/EIJ/NU/$id.filtered_nu.exonquants";
my $outfile = $ARGV[2];
my $highfile = $outfile;
$highfile =~ s/.exonpercents.txt/.high_expressers_exon.txt/;
my (%UNIQUE, %NU);
##intron
my $total_u_i = 0;
my $total_nu_i = 0;
my $quantsfile_u_i = $quantsfile_u;
$quantsfile_u_i =~ s/exonquants$/intronquants/;
my $quantsfile_nu_i = $quantsfile_nu;
$quantsfile_nu_i =~ s/exonquants$/intronquants/;
my $outfile_i = $ARGV[3];
my $highfile_i = $outfile_i;
$highfile_i =~ s/.intronpercents.txt/.high_expressers_intron.txt/;
my (%UNIQUE_I, %NU_I);

#stranded
##exon
my $total_u_sense = 0;
my $total_u_antisense = 0;
my $total_nu_sense = 0;
my $total_nu_antisense = 0;
my $quantsfile_u_sense = "$sampledir/EIJ/Unique/$id.filtered_u.sense.exonquants";
my $quantsfile_u_antisense = "$sampledir/EIJ/Unique/$id.filtered_u.antisense.exonquants";
my $quantsfile_nu_sense = "$sampledir/EIJ/NU/$id.filtered_nu.sense.exonquants";
my $quantsfile_nu_antisense = "$sampledir/EIJ/NU/$id.filtered_nu.antisense.exonquants";
my $outfile_sense = $outfile;
$outfile_sense =~ s/.txt$/_sense.txt/;
my $outfile_antisense = $outfile;
$outfile_antisense =~ s/.txt$/_antisense.txt/;
my $highfile_sense = $highfile;
$highfile_sense =~ s/.txt$/_sense.txt/;
my $highfile_antisense = $highfile;
$highfile_antisense =~ s/.txt$/_antisense.txt/;
my (%UNIQUE_S, %NU_S, %UNIQUE_A, %NU_A);
##intron
my $total_u_sense_i = 0;
my $total_u_antisense_i = 0;
my $total_nu_sense_i = 0;
my $total_nu_antisense_i = 0;
my $quantsfile_u_sense_i = "$sampledir/EIJ/Unique/$id.filtered_u.sense.intronquants";
my $quantsfile_u_antisense_i = "$sampledir/EIJ/Unique/$id.filtered_u.antisense.intronquants";
my $quantsfile_nu_sense_i = "$sampledir/EIJ/NU/$id.filtered_nu.sense.intronquants";
my $quantsfile_nu_antisense_i = "$sampledir/EIJ/NU/$id.filtered_nu.antisense.intronquants";
my $outfile_sense_i = $outfile_i;
$outfile_sense_i =~ s/.txt$/_sense.txt/;
my $outfile_antisense_i = $outfile_i;
$outfile_antisense_i =~ s/.txt$/_antisense.txt/;
my $highfile_sense_i = $highfile_i;
$highfile_sense_i =~ s/.txt$/_sense.txt/;
my $highfile_antisense_i = $highfile_i;
$highfile_antisense_i =~ s/.txt$/_antisense.txt/;
my (%UNIQUE_S_I, %NU_S_I, %UNIQUE_A_I, %NU_A_I);
my $cutoff = $ARGV[1];

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if ((0 > $cutoff) || (100 < $cutoff)){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}


if($U eq "true"){
    if ($stranded eq "false"){
	#exon
	open(INFILE_U, $quantsfile_u) or die "cannot find file '$quantsfile_u'\n";
	while(my $line = <INFILE_U>){
	    chomp($line);
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	    my @a = split(/\t/, $line);
	    my $exon = $a[0];
	    my $quant = $a[1];
	    $total_u = $total_u + $quant;
	    $UNIQUE{$exon} = $quant;
	}
	close(INFILE_U);
	#intron
        open(INFILE_U_I, $quantsfile_u_i) or die "cannot find file '$quantsfile_u_i'\n";
        while(my $line = <INFILE_U_I>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            my $quant = $a[1];
            $total_u_i = $total_u_i + $quant;
            $UNIQUE_I{$intron} = $quant;
        }
        close(INFILE_U_I);
    }
    if ($stranded eq "true"){
	#exon
	open(INFILE_U_S, $quantsfile_u_sense) or die "cannot find file '$quantsfile_u_sense'\n";
        while(my $line = <INFILE_U_S>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
	    }
            my @a = split(/\t/, $line);
	    my $exon = $a[0];
            my $quant = $a[1];
	    $UNIQUE_S{$exon} = $quant;
            $total_u_sense = $total_u_sense + $quant;
        }
        close(INFILE_U_S);
	open(INFILE_U_A, $quantsfile_u_antisense) or die "cannot find file '$quantsfile_u_antisense'\n";
        while(my $line = <INFILE_U_A>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
	    }
            my @a = split(/\t/, $line);
	    my $exon = $a[0];
            my $quant = $a[1];
	    $UNIQUE_A{$exon} = $quant;
            $total_u_antisense = $total_u_antisense + $quant;
        }
        close(INFILE_U_A);
	#intron
        open(INFILE_U_S_I, $quantsfile_u_sense_i) or die "cannot find file '$quantsfile_u_sense_i'\n";
        while(my $line = <INFILE_U_S_I>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            my $quant = $a[1];
            $UNIQUE_S_I{$intron} = $quant;
            $total_u_sense_i = $total_u_sense_i + $quant;
        }
	close(INFILE_U_S_I);
        open(INFILE_U_A_I, $quantsfile_u_antisense_i) or die "cannot find file '$quantsfile_u_antisense_i'\n";
        while(my $line = <INFILE_U_A_I>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            my $quant = $a[1];
            $UNIQUE_A_I{$intron} = $quant;
            $total_u_antisense_i = $total_u_antisense_i + $quant;
        }
        close(INFILE_U_A_I);
    }
}
if ($NU eq "true"){
    if ($stranded eq "false"){
	#exon
	open(INFILE_NU, $quantsfile_nu) or die "cannot find file '$quantsfile_nu'\n";
	while(my $line = <INFILE_NU>){
	    chomp($line);
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	    my @a = split(/\t/, $line);
	    my $exon = $a[0];
	    my $quant = $a[2];
	    $total_nu = $total_nu + $quant;
	    $NU{$exon} = $quant;
	}
	close(INFILE_NU);
	#intron
        open(INFILE_NU_I, $quantsfile_nu_i) or die "cannot find file '$quantsfile_nu_i'\n";
        while(my $line = <INFILE_NU_I>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            my $quant = $a[2];
            $total_nu_i = $total_nu_i + $quant;
            $NU_I{$intron} = $quant;
        }
        close(INFILE_NU_I);
    }
    if ($stranded eq "true"){
	#exon
	open(INFILE_NU_S, $quantsfile_nu_sense) or die "cannot find file '$quantsfile_nu_sense'\n";
        while(my $line = <INFILE_NU_S>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
	    my @a = split(/\t/, $line);
	    my $exon = $a[0];
            my $quant = $a[2];
	    $NU_S{$exon} = $quant;
            $total_nu_sense = $total_nu_sense + $quant;
        }
        close(INFILE_NU_S);
	open(INFILE_NU_A, $quantsfile_nu_antisense) or die "cannot find file '$quantsfile_nu_antisense'\n";
	while(my $line = <INFILE_NU_A>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
	    }
            my @a = split(/\t/, $line);
	    my $exon = $a[0];
            my $quant = $a[2];
	    $NU_A{$exon} = $quant;
            $total_nu_antisense = $total_nu_antisense + $quant;
        }
        close(INFILE_NU_A);
	#intron
        open(INFILE_NU_S_I, $quantsfile_nu_sense_i) or die "cannot find file '$quantsfile_nu_sense_i'\n";
        while(my $line = <INFILE_NU_S_I>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            my $quant = $a[2];
            $NU_S_I{$intron} = $quant;
            $total_nu_sense_i = $total_nu_sense_i + $quant;
        }
        close(INFILE_NU_S_I);
        open(INFILE_NU_A_I, $quantsfile_nu_antisense_i) or die "cannot find file '$quantsfile_nu_antisense_i'\n";
        while(my $line = <INFILE_NU_A_I>){
            chomp($line);
            if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
                next;
            }
            my @a = split(/\t/, $line);
            my $intron = $a[0];
            my $quant = $a[2];
            $NU_A_I{$intron} = $quant;
            $total_nu_antisense_i = $total_nu_antisense_i + $quant;
        }
        close(INFILE_NU_A);
    }
}

if($U eq "true"){
    if ($stranded eq "false"){
	#exon
	open(OUT, ">$outfile");
	open(OUT2, ">$highfile");
	print OUT "exon\t%unique\n";
	print OUT2 "exon\t%unique\n";
	foreach my $exon (keys %UNIQUE){
	    my $quant = $UNIQUE{$exon};
	    my $percent = int(($quant / $total_u) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
	    print OUT "$exon\t$percent\n";
	    
	    if ($percent >= $cutoff){
		print OUT2 "$exon\t$percent\n";
	    }
	}
	close(OUT);
	close(OUT2);
	#intron
        open(OUT_I, ">$outfile_i");
        open(OUT2_I, ">$highfile_i");
        print OUT_I "intron\t%unique\n";
        print OUT2_I "intron\t%unique\n";
        foreach my $intron (keys %UNIQUE_I){
            my $quant = $UNIQUE_I{$intron};
            my $percent = int(($quant / $total_u_i) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
            print OUT_I "$intron\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_I "$intron\t$percent\n";
            }
        }
        close(OUT_I);
        close(OUT2_I);
    }
    if ($stranded eq "true"){
	#exon
	open(OUT_S, ">$outfile_sense");
	open(OUT2_S, ">$highfile_sense");
	print OUT_S "exon\t%unique\n";
        print OUT2_S "exon\t%unique\n";
        foreach my $exon (keys %UNIQUE_S){
            my $quant = $UNIQUE_S{$exon};
            my $percent = int(($quant / $total_u_sense) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
            print OUT_S "$exon\t$percent\n";

            if ($percent >= $cutoff){
		print OUT2_S "$exon\t$percent\n";
            }
	}
        close(OUT_S);
        close(OUT2_S);

	open(OUT_A, ">$outfile_antisense");
	open(OUT2_A, ">$highfile_antisense");
	print OUT_A "exon\t%unique\n";
        print OUT2_A "exon\t%unique\n";
        foreach my $exon (keys %UNIQUE_A){
            my $quant = $UNIQUE_A{$exon};
            my $percent = int(($quant / $total_u_antisense) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
	    print OUT_A "$exon\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_A "$exon\t$percent\n";
            }
        }
        close(OUT_A);
        close(OUT2_A);
	#intron
        open(OUT_S_I, ">$outfile_sense_i");
        open(OUT2_S_I, ">$highfile_sense_i");
        print OUT_S_I "intron\t%unique\n";
	print OUT2_S_I "intron\t%unique\n";
        foreach my $intron (keys %UNIQUE_S_I){
            my $quant = $UNIQUE_S_I{$intron};
            my $percent = int(($quant / $total_u_sense_i) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
            print OUT_S_I "$intron\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_S_I "$intron\t$percent\n";
            }
        }
        close(OUT_S_I);
        close(OUT2_S_I);
	#antisense
        open(OUT_A_I, ">$outfile_antisense_i");
        open(OUT2_A_I, ">$highfile_antisense_i");
        print OUT_A_I "intron\t%unique\n";
        print OUT2_A_I "intron\t%unique\n";
        foreach my $intron (keys %UNIQUE_A_I){
            my $quant = $UNIQUE_A_I{$intron};
            my $percent = int(($quant / $total_u_antisense_i) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
            print OUT_A_I "$intron\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_A_I "$intron\t$percent\n";
            }
        }
        close(OUT_A);
        close(OUT2_A);
    }
}
if($NU eq "true"){
    if ($stranded eq "false"){
	#exon
	open(OUT, ">$outfile");
	open(OUT2, ">$highfile");
	print OUT "exon\t%non-unique\n";
	print OUT2 "exon\t%non-unique\n";
	foreach my $exon (keys %NU){
	    my $quant = $NU{$exon};
	    my $percent = int(($quant / $total_nu) * 10000)/100;
	    $percent = sprintf("%.2f",  $percent);
	    print OUT "$exon\t$percent\n";
	    
	    if ($percent >= $cutoff){
		print OUT2 "$exon\t$percent\n";
	    }
	}
	close(OUT);
	close(OUT2);
	#intron
        open(OUT_I, ">$outfile_i");
        open(OUT2_I, ">$highfile_i");
        print OUT_I "intron\t%non-unique\n";
        print OUT2_I "intron\t%non-unique\n";
        foreach my $intron (keys %NU_I){
            my $quant = $NU_I{$intron};
            my $percent = int(($quant / $total_nu_i) * 10000)/100;
	    $percent = sprintf("%.2f",  $percent);
            print OUT_I "$intron\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_I "$intron\t$percent\n";
            }
        }
        close(OUT_I);
        close(OUT2_I);
    }
    if ($stranded eq "true"){
	#exon
	open(OUT_S, ">$outfile_sense");
	open(OUT2_S, ">$highfile_sense");
        print OUT_S "exon\t%non-unique\n";
        print OUT2_S "exon\t%non-unique\n";
        foreach my $exon (keys %NU_S){
            my $quant = $NU_S{$exon};
            my $percent = int(($quant / $total_nu_sense) * 10000)/100;
	    $percent = sprintf("%.2f",  $percent);
            print OUT_S "$exon\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_S "$exon\t$percent\n";
            }
        }
        close(OUT_S);
        close(OUT2_S);

        open(OUT_A, ">$outfile_antisense");
        open(OUT2_A, ">$highfile_antisense");
        print OUT_A "exon\t%non-unique\n";
        print OUT2_A "exon\t%non-unique\n";
        foreach my $exon (keys %NU_A){
            my $quant = $NU_A{$exon};
            my $percent = int(($quant / $total_nu_antisense) * 10000)/100;
	    $percent = sprintf("%.2f", $percent);
            print OUT_A "$exon\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_A "$exon\t$percent\n";
            }
        }
	#intron
        open(OUT_S_I, ">$outfile_sense_i");
        open(OUT2_S_I, ">$highfile_sense_i");
        print OUT_S_I "intron\t%non-unique\n";
        print OUT2_S_I "intron\t%non-unique\n";
        foreach my $intron (keys %NU_S_I){
            my $quant = $NU_S_I{$intron};
            my $percent = int(($quant / $total_nu_sense_i) * 10000)/100;
	    $percent = sprintf("%.2f",  $percent);
            print OUT_S_I "$intron\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_S_I "$intron\t$percent\n";
            }
        }
        close(OUT_S_I);
        close(OUT2_S_I);

        open(OUT_A_I, ">$outfile_antisense_i");
        open(OUT2_A_I, ">$highfile_antisense_i");
        print OUT_A_I "intron\t%non-unique\n";
        print OUT2_A_I "intron\t%non-unique\n";
        foreach my $intron (keys %NU_A_I){
            my $quant = $NU_A_I{$intron};
            my $percent = int(($quant / $total_nu_antisense_i) * 10000)/100;
	    $percent = sprintf("%.2f",  $percent);
            print OUT_A_I "$intron\t$percent\n";

            if ($percent >= $cutoff){
                print OUT2_A_I "$intron\t$percent\n";
            }
        }
	close(OUT_A_I);
	close(OUT2_A_I);
    }
}
#print "got here\n";

