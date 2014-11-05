#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<3) {
    die "Usage: perl get_genepercents.pl <sample directory> <cutoff> <outfile> [options]

<sample directory> 
<cutoff> cutoff %
<outfile> output genepercents file with full path

option:
  -nu :  set this if you want to return only non-unique genepercents, otherwise by default
         it will return unique genepercents.

  -stranded : set this if the data are strand specific.
";
}

my $U = "true";
my $NU = "false";
my $stranded = "false";
for(my $i=3; $i<@ARGV; $i++) {
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

my $total_u = 0;
my $total_nu = 0;
my $total_u_a = 0;
my $total_nu_a = 0;
my $sampledir = $ARGV[0];
my @a = split("/", $sampledir);
my $dirname = $a[@a-1];
my $id = $dirname;
my $quantsfile_u = "$sampledir/GNORM/Unique/$id.filtered_u.genefilter.genequants";
my $quantsfile_nu = "$sampledir/GNORM/NU/$id.filtered_nu.genefilter.genequants";
my ($quantsfile_u_a, $quantsfile_nu_a);
if ($stranded eq "true"){
    $quantsfile_u = "$sampledir/GNORM/Unique/$id.filtered_u.genefilter.sense.genequants";
    $quantsfile_u_a = "$sampledir/GNORM/Unique/$id.filtered_u.genefilter.antisense.genequants";
    $quantsfile_nu = "$sampledir/GNORM/NU/$id.filtered_nu.genefilter.sense.genequants";
    $quantsfile_nu_a = "$sampledir/GNORM/NU/$id.filtered_nu.genefilter.antisense.genequants";
}
my $temp_u = $quantsfile_u . ".temp";
my $temp_nu = $quantsfile_nu . ".temp";
my ($temp_u_a, $temp_nu_a);
if ($stranded eq "true"){
    $temp_u_a = $quantsfile_u_a . ".temp";
    $temp_nu_a = $quantsfile_nu_a . ".temp";
}
my $cutoff = $ARGV[1];
my $outfile = $ARGV[2];
my $outfile_a;
if ($stranded eq "true"){
    $outfile_a = $outfile;
    $outfile_a =~ s/.txt$/.antisense.txt/;
    $outfile =~ s/.txt$/.sense.txt/;
}
my $highfile = $outfile;
$highfile =~ s/.genepercents.txt/.high_expressers_gene.txt/;
my $highfile_a;
if ($stranded eq "true"){
    $highfile_a = $outfile_a;
    $highfile_a =~ s/.genepercents.antisense.txt$/.high_expressers_gene.antisense.txt/;
    $highfile =~ s/.genepercents.sense.txt$/.high_expressers_gene.sense.txt/;
}

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if ((0 > $cutoff) || (100 < $cutoff)){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}
if ($U eq "true"){
    open(INFILE_U, $quantsfile_u) or die "cannot find file '$quantsfile_u'\n";
    open(temp_u, ">$temp_u");
    while(my $line = <INFILE_U>){
	chomp($line);
	if ($line !~ /^ENS/){
	    next;
	}
	print temp_u "$line\n";
	my @a = split(/\t/, $line);
	my $quant = $a[1];
	$total_u = $total_u + $quant;
    }
    close(INFILE_U);
    close(temp_u);
    if ($stranded eq "true"){
	open(INFILE_U_A, $quantsfile_u_a) or die "cannot find file '$quantsfile_u_a'\n";
	open(temp_u_a, ">$temp_u_a");
	while(my $line = <INFILE_U_A>){
	    chomp($line);
	    if ($line !~ /^ENS/){
		next;
	    }
	    print temp_u_a "$line\n";
	    my @a = split(/\t/, $line);
	    my $quant_a = $a[1];
	    $total_u_a = $total_u_a + $quant_a;
	}
	close(INFILE_U_A);
	close(temp_u_a);
    }
}
if ($NU eq "true"){
    open(INFILE_NU, $quantsfile_nu) or die "cannot find file '$quantsfile_nu'\n";
    open(temp_nu, ">$temp_nu");
    while(my $line = <INFILE_NU>){
	chomp($line);
	if ($line !~ /^ENS/){
	    next;
	}
	print temp_nu "$line\n";
	my @a = split(/\t/, $line);
	my $quant = $a[2];
	$total_nu = $total_nu + $quant;
    }
    close(INFILE_NU);
    close(temp_nu);
    if ($stranded eq "true"){
	open(INFILE_NU_A, $quantsfile_nu_a) or die "cannot find file '$quantsfile_nu_a'\n";
	open(temp_nu_a, ">$temp_nu_a");
	while(my $line = <INFILE_NU_A>){
	    chomp($line);
	    if ($line !~ /^ENS/){
		next;
	    }
	    print temp_nu_a "$line\n";
	    my @a = split(/\t/, $line);
	    my $quant = $a[2];
	    $total_nu_a = $total_nu_a + $quant;
	}
	close(INFILE_NU_A);
	close(temp_nu_a);
    }
}

if($U eq "true"){
    open(IN_U, $temp_u);
    open(OUT, ">$outfile");
    open(OUT2, ">$highfile");
    print OUT "ensGene\t%min\tgeneSymbol\tgeneCoordinates\n";
    print OUT2 "ensGene\t%min\tgeneSymbol\tgeneCoordinates\n";
    while(my $line_U = <IN_U>){
	chomp($line_U);
	my @au = split(/\t/, $line_U);
	my $geneu = $au[0];
	my $quantu = $au[1];
	my $sym = $au[3];
	my $coord = $au[4];
	my $percent_u = int(($quantu / $total_u)* 10000 ) / 100;
	print OUT "$geneu\t$percent_u\t$sym\t$coord\n";
	if ($percent_u >= $cutoff){
	    print OUT2 "$geneu\t$percent_u\t$sym\t$coord\n";
	}
    }
    close(IN_U);
    close(OUT);
    close(OUT2);
    `rm $temp_u`;
    if ($stranded eq "true"){
	open(IN_U_A, $temp_u_a);
	open(OUT, ">$outfile_a");
	open(OUT2, ">$highfile_a");
	print OUT "ensGene\t%min\tgeneSymbol\tgeneCoordinates\n";
	print OUT2 "ensGene\t%min\tgeneSymbol\tgeneCoordinates\n";
	while(my $line_U_A = <IN_U_A>){
	    chomp($line_U_A);
	    my @au = split(/\t/, $line_U_A);
	    my $geneu = $au[0];
	    my $quantu = $au[1];
	    my $sym = $au[3];
	    my $coord = $au[4];
	    my $percent_u = int(($quantu / $total_u_a)* 10000 ) / 100;
	    print OUT "$geneu\t$percent_u\t$sym\t$coord\n";
	    if ($percent_u >= $cutoff){
		print OUT2 "$geneu\t$percent_u\t$sym\t$coord\n";
	    }
	}
	close(IN_U_A);
	close(OUT);
	close(OUT2);
	`rm $temp_u_a`;
    }
}

if($NU eq "true"){
    open(IN_NU, $temp_nu);
    open(OUT, ">$outfile");
    open(OUT2, ">$highfile");
    print OUT "ensGene\t%max\tgeneSymbol\tgeneCoordinates\n";
    print OUT2 "ensGene\t%max\tgeneSymbol\tgeneCoordinates\n";
    while(my $line_NU = <IN_NU>){
	chomp($line_NU);
	my @anu = split(/\t/, $line_NU);
	my $genenu = $anu[0];
	my $quantnu = $anu[2];
	my $sym = $anu[3];
	my $coord = $anu[4];
	my $percent_nu = int(($quantnu / $total_nu)* 10000 ) / 100;	
	print OUT "$genenu\t$percent_nu\t$sym\t$coord\n";
	if ($percent_nu >= $cutoff){
	    print OUT2 "$genenu\t$percent_nu\t$sym\t$coord\n";
	}
    }
    close(IN_NU);
    close(OUT);
    close(OUT2);
    `rm $temp_nu`;
    if ($stranded eq "true"){
	open(IN_NU_A, $temp_nu_a);
	open(OUT, ">$outfile_a");
	open(OUT2, ">$highfile_a");
	print OUT "ensGene\t%max\tgeneSymbol\tgeneCoordinates\n";
	print OUT2 "ensGene\t%max\tgeneSymbol\tgeneCoordinates\n";
	while(my $line_NU_A = <IN_NU_A>){
	    chomp($line_NU_A);
	    my @anu = split(/\t/, $line_NU_A);
	    my $genenu = $anu[0];
	    my $quantnu = $anu[2];
	    my $sym = $anu[3];
	    my $coord = $anu[4];
	    my $percent_nu = int(($quantnu / $total_nu_a)* 10000 ) / 100;
	    print OUT "$genenu\t$percent_nu\t$sym\t$coord\n";
	    if ($percent_nu >= $cutoff){
		print OUT2 "$genenu\t$percent_nu\t$sym\t$coord\n";
	    }
	}
	close(IN_NU_A);
	close(OUT);
	close(OUT2);
	`rm $temp_nu_a`;
    }
}

print "got here\n";
