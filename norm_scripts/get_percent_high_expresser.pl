#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<3) {
    die "Usage: perl get_percent_high_expresser.pl <sample dirs> <loc> <exons file> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are
<master list of exons> master list of exons file

options:
 -stranded : set this if your data are strand-specific

";
}
my $stranded = "false";
my $option_found = "false";
for(my $i=3; $i<@ARGV; $i++) {
    if($ARGV[$i] eq '-stranded') {
        $stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
unless (-d "$stats_dir/EXON_INTRON_JUNCTION/"){
    `mkdir -p $stats_dir/EXON_INTRON_JUNCTION`;}

my $exons = $ARGV[2];
my $annotated = $exons;
$annotated =~ s/master_list_of_/annotated_master_list_of_/;
unless (-e "$annotated"){
    die "\"$annotated\" file does  not exist...\n";
}
my $outfileE = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expresser_exon.txt";
my $outfileI = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expresser_intron.txt";
my $outfileE_S = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expresser_exon_sense.txt";
my $outfileI_S = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expresser_intron_sense.txt";
my $outfileE_A = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expresser_exon_antisense.txt";
my $outfileI_A = "$stats_dir/EXON_INTRON_JUNCTION/percent_high_expresser_intron_antisense.txt";

my %HIGH_EXON;
my %HIGH_INTRON;
my %HIGH_EXON_S;
my %HIGH_EXON_A;
my %HIGH_INTRON_S;
my %HIGH_INTRON_A;

if ($stranded eq "false"){
    my $file = "$LOC/high_expressers_exon.txt";
    my $file_i = "$LOC/high_expressers_intron.txt";
    #exon
    if (-e $file){
	my $wc = `wc -l $file`;
	my @w =split(" ", $wc);
	my $wcl= $w[0];
	if ($wcl >0){
	    open(IN, $file);
	    while(my $line = <IN>){
		chomp($line);
		if ($line =~ /^exon/){
		    next;
		}
		my @i = split(/\t/, $line);
		my $exon = $i[0];
		$HIGH_EXON{$exon} = 1;
	    }
	    close(IN);
	}
    }
    #intron
    if (-e $file_i){
	my $wc = `wc -l $file_i`;
	my @w =split(" ", $wc);
	my $wcl= $w[0];
	if ($wcl>0){
	    open(IN_I, $file_i);
	    while(my $line = <IN_I>){
		chomp($line);
		if ($line =~ /^intron/){
		    next;
		}
		my @i = split(/\t/, $line);
		my $intron = $i[0];
		$HIGH_INTRON{$intron} = 1;
	    }
	    close(IN_I);
	}
    }
}
if ($stranded eq "true"){
    my $file_s = "$LOC/high_expressers_exon_sense.txt";
    my $file_a = "$LOC/high_expressers_exon_antisense.txt";
    my $file_i_s = "$LOC/high_expressers_intron_sense.txt";
    my $file_i_a = "$LOC/high_expressers_intron_antisense.txt";
    #sense exon
    if(-e $file_s){
	my $wc = `wc -l $file_s`;
	my @w = split(" ", $wc);
	my $wcl = $w[0];
	if ($wcl>0){
	    open(IN_S, "<$file_s");
	    while(my $line = <IN_S>){
		chomp($line);
		if ($line =~ /^exon/){
		    next;
		}
		my @i = split(/\t/, $line);
		my $exon = $i[0];
		$HIGH_EXON_S{$exon} = 1;
	    }
	    close(IN_S);
	}
    }
    #antisense exon
    if(-e $file_a){
	my $wc = `wc -l $file_a`;
	my @w =split(" ", $wc);
	my $wcl= $w[0];
        if ($wcl>0){
	    open(IN_A, $file_a);
	    while(my $line = <IN_A>){
		chomp($line);
		if ($line =~ /^exon/){
		    next;
		}
		my @i = split(/\t/, $line);
		my $exon = $i[0];
		$HIGH_EXON_A{$exon} = 1;
	    }
	    close(IN_A);
	}
    }
    #sense intron
    if(-e $file_i_s){
	my $wc = `wc -l $file_i_s`;
	my @w =split(" ", $wc);
	my $wcl= $w[0];
        if ($wcl>0){
	    open(IN_I_S, $file_i_s);
	    while(my $line = <IN_I_S>){
		chomp($line);
		if ($line =~ /^intron/){
		    next;
		}
		my @i = split(/\t/, $line);
		my $intron = $i[0];
		$HIGH_INTRON_S{$intron} = 1;
	    }
	    close(IN_I_S);
	}
    }
    #antisense intron
    if(-e $file_i_a){
	my $wc = `wc -l $file_i_a`;
	my @w =split(" ", $wc);
	my $wcl= $w[0];
        if ($wcl>0){
	    open(IN_I_A, $file_i_a);
	    while(my $line = <IN_I_A>){
		chomp($line);
		if ($line =~ /^intron/){
		    next;
		}
		my @i = split(/\t/, $line);
		my $intron = $i[0];
		$HIGH_INTRON_A{$intron} = 1;
	    }
	    close(IN_I_A);
	}
    }
}
my ($lastrow, $lastrow_s);

#exon
if ($stranded eq "false"){
    if(-e $outfileE){
	`rm $outfileE`;
    }
    my $size = keys( %HIGH_EXON );
    if ($size > 0){
	my $firstrow = "exon";
	$lastrow = "gene";
	foreach my $exon (keys %HIGH_EXON){
	    $firstrow = $firstrow . "\t$exon";
	    my $anot = `grep -w $exon $annotated`;
	    my @a = split(/\t/, $anot);
	    my $symlist = "";
	    if (@a > 3){
		my $symbols = $a[2];
		my @b = split(",",$symbols);
		my @uniqueSymbols = &uniq(@b);
		$symlist = join(',',@uniqueSymbols);
	    }
	    $lastrow = $lastrow . "\t$symlist";
	}
	open(OUTE, ">>$outfileE") or die "file '$outfileE' cannot open for writing.\n";
	print OUTE "$firstrow\n";	
    }
}
if ($stranded eq "true"){
    #sense exon
    if(-e $outfileE_S){
        `rm $outfileE_S`;
    }
    my $size = keys( %HIGH_EXON_S );
    if ($size > 0){
	my $firstrow_s = "exon";
	$lastrow_s = "gene";
	foreach my $exon (keys %HIGH_EXON_S){
            $firstrow_s = $firstrow_s . "\t$exon";
            my $anot = `grep -w $exon $annotated`;
            my @a = split(/\t/, $anot);
            my $symlist = "";
            if (@a > 4){
                my $symbols = $a[3];
                my @b = split(",",$symbols);
                my @uniqueSymbols = &uniq(@b);
                $symlist = join(',',@uniqueSymbols);
            }
            $lastrow_s = $lastrow_s . "\t$symlist";
	}
	open(OUTE_S, ">>$outfileE_S") or die "file '$outfileE_S' cannot open for writing.\n";
	print OUTE_S "$firstrow_s\n";
    }

    #antisense exon
    if(-e $outfileE_A){
        `rm $outfileE_A`;
    }
    $size = keys( %HIGH_EXON_A );
    if ($size > 0){
	my $firstrow_a = "exon";
	foreach my $exon (keys %HIGH_EXON_A){
	    $firstrow_a = $firstrow_a . "\t$exon";
	}
	open(OUTE_A, ">>$outfileE_A") or die "file '$outfileE_A' cannot open for writing.\n";
	print OUTE_A "$firstrow_a\n";
    }
}
#intron
if ($stranded eq "false"){
    if (-e $outfileI){
	`rm $outfileI`;
    }
    my $size = keys( %HIGH_INTRON );
    if ($size > 0){
	my $firstrow_i = "intron";
	foreach my $intron (keys %HIGH_INTRON){
	    $firstrow_i = $firstrow_i . "\t$intron";
	}
	open(OUTI, ">>$outfileI") or die "file '$outfileI' cannot open for writing.\n";
	print OUTI "$firstrow_i\n";	
    }
}
if ($stranded eq "true"){
    #sense intron
    if (-e $outfileI_S){
        `rm $outfileI_S`;
    }
    my $size = keys( %HIGH_INTRON_S );
    if ($size > 0){
	my $firstrow_i_s = "intron";
	foreach my $intron (keys %HIGH_INTRON_S){
	    $firstrow_i_s = $firstrow_i_s . "\t$intron";
	}
	open(OUTI_S, ">>$outfileI_S") or die "file '$outfileI_S' cannot open for writing.\n";
	print OUTI_S "$firstrow_i_s\n";
    }
    #antisense intron
    if (-e $outfileI_A){
        `rm $outfileI_A`;
    }
    $size = keys( %HIGH_INTRON_A );
    if ($size > 0){
	my $firstrow_i_a = "intron";
	foreach my $intron (keys %HIGH_INTRON_A){
	    $firstrow_i_a = $firstrow_i_a . "\t$intron";
	}
	open(OUTI_A, ">>$outfileI_A") or die "file '$outfileI_A' cannot open for writing.\n";
	print OUTI_A "$firstrow_i_a\n";
    }
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $row = "$id\t";
    if ($stranded eq "false"){
	#exon
	my $size = keys( %HIGH_EXON );
	if ($size > 0){
	    foreach my $exon (keys %HIGH_EXON){
		chomp($exon);
		$exon =~ s/exon://;
		my $exonpercent = "$LOC/$dir/$id.exonpercents.txt";
		my $value = `grep -w $exon $exonpercent`;
		my @v = split(" ", $value);
		my $val = $v[1];
		$row = $row . "$val\t";
	    }
	    print OUTE "$row\n";
	    print OUTE "$lastrow\n";
	}
	#intron
	$size = keys( %HIGH_INTRON );
	if ($size > 0){
	    foreach my $intron (keys %HIGH_INTRON){
		chomp($intron);
		$intron =~ s/intron://;
		my $intronpercent = "$LOC/$dir/$id.intronpercents.txt";
		my $value = `grep -w $intron $intronpercent`;
		my @v = split(" ", $value);
		my $val = $v[1];
		$row = $row . "$val\t";
	    }
	    print OUTI "$row\n";
	}
    }
    if ($stranded eq "true"){
	#sense exon
	my $size = keys( %HIGH_EXON_S );
	if ($size > 0){
	    foreach my $exon (keys %HIGH_EXON_S){
		chomp($exon);
		$exon =~ s/exon://;
		my $exonpercent = "$LOC/$dir/$id.exonpercents_sense.txt";
		my $value = `grep -w $exon $exonpercent`;
		my @v = split(" ", $value);
		my $val = $v[1];
		$row = $row . "$val\t";
	    }
	    print OUTE_S "$row\n";
	    print OUTE_S "$lastrow_s\n";
	}
        #antisense exon
	$size = keys( %HIGH_EXON_A );
	if ($size > 0){
	    foreach my $exon (keys %HIGH_EXON_A){
		chomp($exon);
		$exon =~ s/exon://;
		my $exonpercent = "$LOC/$dir/$id.exonpercents_antisense.txt";
		my $value = `grep -w $exon $exonpercent`;
		my @v = split(" ", $value);
		my $val = $v[1];
		$row = $row . "$val\t";
	    }
	    print OUTE_A "$row\n";
	}

	#sense intron
	$size = keys( %HIGH_INTRON_S );
	if ($size > 0){
	    foreach my $intron (keys %HIGH_INTRON_S){
		chomp($intron);
		$intron =~ s/intron://;
		my $intronpercent = "$LOC/$dir/$id.intronpercents_sense.txt";
		my $value = `grep -w $intron $intronpercent`;
		my @v = split(" ", $value);
		my $val = $v[1];
		$row = $row . "$val\t";
	    }
	    print OUTI_S "$row\n";
	}
	#antisense intron
	$size = keys( %HIGH_INTRON_A );
	if ($size > 0){
	    foreach my $intron (keys %HIGH_INTRON_A){
		chomp($intron);
		$intron =~ s/intron://;
		my $intronpercent = "$LOC/$dir/$id.intronpercents_antisense.txt";
		my $value = `grep -w $intron $intronpercent`;
		my @v = split(" ", $value);
		my $val = $v[1];
		$row = $row . "$val\t";
	    }
	    print OUTI_A "$row\n";
	}
    }
}
close(INFILE);
if ($stranded eq "false"){
    close(OUTE);
    close(OUTI);
}
if ($stranded eq "true"){
    close(OUTE_S);
    close(OUTE_A);
    close(OUTI_S);
    close(OUTI_A);
}

print "got here\n";

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
