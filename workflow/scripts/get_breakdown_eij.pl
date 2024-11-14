#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_breakdown_eij.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -stranded : set this if your data are strand-specific.

 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -alt_stats <s>


";
}
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $stranded = "false";
my $footer_U = "----------\n";
my $footer_NU = "----------\n";
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";

for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$option_found = "true";
	$numargs++;
    }
    if ($ARGV[$i] eq '-alt_stats'){
	$option_found = "true";
	$stats_dir = $ARGV[$i+1];
	$i++;
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
	$numargs++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-stranded') {
        $stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

unless (-d "$stats_dir/EXON_INTRON_JUNCTION"){
    `mkdir -p $stats_dir/EXON_INTRON_JUNCTION`;
}
my $outfileU = "$stats_dir/EXON_INTRON_JUNCTION/breakdown_Unique.txt";
my $outfileNU = "$stats_dir/EXON_INTRON_JUNCTION/breakdown_NU.txt";
my $header = "";
if ($stranded eq "false"){
    $header = "sample\t%ex-only\t%int-only\t%ex-int\t%ig-only\t%ex-inc-only\n";
}
else{
    $header = "sample\t%ex-only-s\t%int-only-s\t%ex-int-s\t%ex-only-a\t%int-only-a\t%ex-int-a\t%ig-only\t%ex-inc-only\n";
}
if ($U eq "true"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    print OUTU $header;
    if ($stranded eq "false"){
	$footer_U .= "# %ex-only : % exonmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %int-only : % intronmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ex-int : % exon-and-intronmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ig-only : % intergenicmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ex-inc-only : % exon inconsistent reads out of all unique-mappers (to standard chrs)\n";
    }
    else{
	$footer_U .= "# %ex-only-s : % sense exonmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %int-only-s : % sense intronmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ex-int-s : % sense exon-and-intronmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ex-only-a : % antisense exonmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %int-only-a : % antisense intronmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ex-int-a : % antisense exon-and-intronmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ig-only : % intergenicmappers out of all unique-mappers (to standard chrs)\n";
	$footer_U .= "# %ex-inc-only : % exon inconsistent reads out of all unique-mappers (to standard chrs)\n";
    }
}
if ($NU eq "true"){
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    print OUTNU $header;
    if ($stranded eq "false"){
        $footer_NU .= "# %ex-only : % exonmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %int-only : % intronmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ex-int : % exon-and-intronmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ig-only : % intergenicmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ex-inc-only : % exon inconsistent reads out of all non-unique-mappers (to standard chrs)\n";
    }
    else{
        $footer_NU .= "# %ex-only-s : % sense exonmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %int-only-s : % sense intronmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ex-int-s : % sense exon-and-intronmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ex-only-a : % antisense exonmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %int-only-a : % antisense intronmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ex-int-a : % antisense exon-and-intronmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ig-only : % intergenicmappers out of all non-unique-mappers (to standard chrs)\n";
        $footer_NU .= "# %ex-inc-only : % exon inconsistent reads out of all non-unique-mappers (to standard chrs)\n";
    }
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $dirU = $dir . "/EIJ/Unique";
    my $dirNU = $dir . "/EIJ/NU";
    my $id = $line;
    my $fileU = "$LOC/$dirU/stats.txt";
    my $fileNU = "$LOC/$dirNU/stats.txt";
    if ($U eq "true"){
	unless (-e $fileU){
	    die "cannot find $fileU\n";
	}
	print OUTU "$dir\t";
	my $xU = `grep total-linecount-standard-chr $fileU`;
	my @x = split(/\t/,$xU);
	my $total_lc = $x[1];
#	print "$total_lc\n";
	#ex-only
	if ($stranded eq "false"){
	    $xU = `grep exon-only $fileU`;
	}
	else{
	    $xU = `grep sense-exon-only $fileU | grep -v anti`;
	}
	@x =split(/\t/,$xU);
	my $ex_only = $x[1];
	my $ratio = int(($ex_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTU "$ratio\t";
	#int-only
	if ($stranded eq "false"){
            $xU= `grep intron-only $fileU`;
	}
	else{
	    $xU= `grep sense-intron-only $fileU | grep -v anti`;
	}
	@x =split(/\t/,$xU);
	my $int_only = $x[1];
	$ratio =int(($int_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTU "$ratio\t";
	#ex-int
	if ($stranded eq "false"){
	    $xU= `grep -w exon-intron $fileU | grep -v intergenic`;
	}
	else{
	    $xU= `grep -w sense-exon-intron $fileU | grep -v intergenic | grep -v anti`;
	}
	@x =split(/\t/,$xU);
	my $ex_int = $x[1];
	$ratio =int(($ex_int/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTU "$ratio\t";
	if ($stranded eq "true"){
	    #antisense-ex-only
            $xU = `grep antisense-exon-only $fileU`;
	    @x =split(/\t/,$xU);
	    my $a_ex_only = $x[1];
	    $ratio = int(($a_ex_only/$total_lc) * 10000)/100;
	    $ratio = sprintf("%.2f", $ratio);
	    print OUTU "$ratio\t";
            #antisense-int-only
	    $xU = `grep antisense-intron-only $fileU`;
            @x =split(/\t/,$xU);
            my $a_int_only = $x[1];
            $ratio = int(($a_int_only/$total_lc) * 10000)/100;
            $ratio = sprintf("%.2f", $ratio);
	    print OUTU "$ratio\t";
	    #antisense-ex-int
            $xU = `grep antisense-exon-intron $fileU | grep -v intergenic`;
            @x =split(/\t/,$xU);
            my $a_ex_int = $x[1];
            $ratio = int(($a_ex_int/$total_lc) * 10000)/100;
            $ratio = sprintf("%.2f", $ratio);
            print OUTU "$ratio\t";
	}
	#ig-only
	$xU= `grep intergenic-only $fileU`;
	@x =split(/\t/,$xU);
	my $ig_only = $x[1];
	$ratio =int(($ig_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTU "$ratio\t";
	#ex-inc-only
	$xU= `grep -w exon-inconsistent-only $fileU`;
	@x =split(/\t/,$xU);
	my $ex_inc_only = $x[1];
	$ratio =int(($ex_inc_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTU "$ratio\t";
	print OUTU "\n";
    }
    if ($NU eq "true"){
	unless (-e $fileNU){
	    die "cannot find $fileNU\n";
	}
	print OUTNU "$dir\t";
	my $xNU = `grep total-linecount-standard-chr $fileNU`;
	my @x = split(/\t/,$xNU);
	my $total_lc = $x[1];
	#ex-only
	if ($stranded eq "false"){
	    $xNU = `grep exon-only $fileNU`;
	}
	else{
	    $xNU = `grep sense-exon-only $fileNU | grep -v anti`;
	}
	@x =split(/\t/,$xNU);
	my $ex_only = $x[1];
	my $ratio = int(($ex_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTNU "$ratio\t";
	#int-only
	if ($stranded eq "false"){
            $xNU= `grep intron-only $fileNU`;
	}
	else{
	    $xNU= `grep sense-intron-only $fileNU | grep -v anti`;
	}
	@x =split(/\t/,$xNU);
	my $int_only = $x[1];
	$ratio =int(($int_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTNU "$ratio\t";
	#ex-int
	if ($stranded eq "false"){
	    $xNU= `grep -w exon-intron $fileNU | grep -v intergenic`;
	}
	else{
	    $xNU= `grep -w sense-exon-intron $fileNU | grep -v intergenic | grep -v anti`;
	}
	@x =split(/\t/,$xNU);
	my $ex_int = $x[1];
	$ratio =int(($ex_int/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTNU "$ratio\t";
	if ($stranded eq "true"){
	    #antisense-ex-only
            $xNU = `grep antisense-exon-only $fileNU`;
	    @x =split(/\t/,$xNU);
	    my $a_ex_only = $x[1];
	    $ratio = int(($a_ex_only/$total_lc) * 10000)/100;
	    $ratio = sprintf("%.2f", $ratio);
	    print OUTNU "$ratio\t";

            #antisense-int-only
	    $xNU = `grep antisense-intron-only $fileNU`;

            @x =split(/\t/,$xNU);
            my $a_int_only = $x[1];
            $ratio = int(($a_int_only/$total_lc) * 10000)/100;
            $ratio = sprintf("%.2f", $ratio);
	    print OUTNU "$ratio\t";

	    #antisense-ex-int
            $xNU = `grep antisense-exon-intron $fileNU | grep -v intergenic`;
            @x =split(/\t/,$xNU);
            my $a_ex_int = $x[1];
            $ratio = int(($a_ex_int/$total_lc) * 10000)/100;
            $ratio = sprintf("%.2f", $ratio);
            print OUTNU "$ratio\t";
	}
	#ig-only
	$xNU= `grep intergenic-only $fileNU`;
	@x =split(/\t/,$xNU);
	my $ig_only = $x[1];
	$ratio =int(($ig_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTNU "$ratio\t";
	#ex-inc-only
	$xNU= `grep -w exon-inconsistent-only $fileNU`;
	@x =split(/\t/,$xNU);
	my $ex_inc_only = $x[1];
	$ratio =int(($ex_inc_only/$total_lc) * 10000)/100;
	$ratio = sprintf("%.2f", $ratio);
	print OUTNU "$ratio\t";
	print OUTNU "\n";
    }
}
close(INFILE);
if ($U eq "true"){
    print OUTU $footer_U;
    close(OUTU);
}
if ($NU eq "true"){
    print OUTNU $footer_NU;
    close(OUTNU);
}
print "got here\n";
