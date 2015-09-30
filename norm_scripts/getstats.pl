#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: perl getstats.pl <dirs> <loc> [option]
where 
<dirs> is a file of directory names (without path)
<loc> is where the sample directories are

[option]
  -mito \"<name>, <name>, ... ,<name>\": name(s) of mitochondrial chromosomes

This will parse the mapping_stats.txt files for all dirs
and output a table with summary info across all samples.

";

if(@ARGV<2) {
    die $USAGE;
}
my %MITO;
my $count = 0;
for(my $i=2;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-mito'){
        my $argv_all = $ARGV[$i+1];
        chomp($argv_all);
        unless ($argv_all =~ /^$/){
            $count=1;
        }
        $option_found = "true";
        my @a = split(",", $argv_all);
        for(my $i=0;$i<@a;$i++){
            my $name = $a[$i];
            chomp($name);
            $name =~ s/^\s+|\s+$//g;
            $MITO{$name}=1;
        }
        $i++;
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($count == 0){
   die "please provide mitochondrial chromosome name using -mito \"<name>\" option.\n";
}
my $dirs = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
my (%total, %uniqueandFRconsistently, %uniqueandAtLeastOneMapped, %NUandAtLeastOneMapped, %TotalMapped, %TotalMapped_cons, %NUandFRconsistently, %Overlap, %NOverlap, %Pover, %min_chrm, %max_chrm, %UchrM);
my ($min_total, $min_total_frcons, $min_utotal_f_or_r_cons, $min_nutotal_f_or_r, $min_total_UorNU, $min_total_UandNU, $min_nutotal, $min_pover);
my ($max_total,$max_total_frcons,$max_total_UorNU,$max_utotal_f_or_r_cons,$max_pover,$max_nutotal,$max_nutotal_f_or_r,$max_total_UandNU) = (0,0,0,0,0,0,0,0);

open(DIRS, $dirs) or die "cannot find file '$dirs'\n";
while(my $dir = <DIRS>) {
    chomp($dir);
    my $id = $dir;
    my $filename = "$LOC/$dir/$id.mappingstats.txt";
    if(!(-e "$filename")) {
	next;
    }
    my $x = `head -1 $filename`;
    chomp($x);
    $x =~ s/[^\d,]//g;
    $total{$dir} = $x;
    my $TOTAL = $x;
    $TOTAL =~ s/,//g;
    if ($TOTAL =~ /^$/){
        $TOTAL = 0;
    }
    $min_total = $TOTAL;

    $x = `grep "Both forward and reverse mapped consistently" $filename`;
    chomp($x);
    $x =~ /([\d,]+)/;
    my $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    my $TOTAL_FRCONS = $1;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $uniqueandFRconsistently{$dir} = "$y ($x)";
    if ($TOTAL_FRCONS =~ /^$/){
        $TOTAL_FRCONS = 0;
        $uniqueandFRconsistently{$dir} = "0 (0.00%)";
    }
    $min_total_frcons = $TOTAL_FRCONS;

    $x = `grep "At least one of forward or reverse mapped" $filename | head -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    my $UTOTAL_F_or_R_CONS = $1;
    $UTOTAL_F_or_R_CONS =~ s/,//g;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $uniqueandAtLeastOneMapped{$dir} = "$y ($x)";
    if ($UTOTAL_F_or_R_CONS =~ /^$/){
        $UTOTAL_F_or_R_CONS = 0;
        $uniqueandAtLeastOneMapped{$dir} = "0 (0.00%)";
    }
    $min_utotal_f_or_r_cons = $UTOTAL_F_or_R_CONS;
    $min_utotal_f_or_r_cons =~ s/,//g;

    $x = `grep "At least one of forward or reverse mapped" $filename | head -2 | tail -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    my $NUTOTAL_F_or_R = $1;
    $NUTOTAL_F_or_R =~ s/,//g;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $NUandAtLeastOneMapped{$dir} = "$y ($x)";
    if ($NUTOTAL_F_or_R =~ /^$/){
        $NUTOTAL_F_or_R = 0;
        $NUandAtLeastOneMapped{$dir} = "0 (0.00%)";
    }
    $min_nutotal_f_or_r = $NUTOTAL_F_or_R;
    $min_nutotal_f_or_r =~ s/,//g;

    $x = `grep "At least one of forward or reverse mapped" $filename | tail -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    my $TOTALMAPPED = $1;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $TotalMapped{$dir} = "$y ($x)";
    if ($TOTALMAPPED =~ /^$/){
        $TOTALMAPPED = 0;
        $TotalMapped{$dir} = "0 (0.00%)";
    }
    $min_total_UorNU = $TOTALMAPPED;
    $min_total_UorNU =~ s/,//g;

    $x = `grep "Total number consistent:" $filename | tail -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    my $TOTALMAPPED_CONS = $1;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $TotalMapped_cons{$dir} = "$y ($x)";
    if ($TOTALMAPPED_CONS =~ /^$/){
        $TOTALMAPPED_CONS = 0;
        $TotalMapped_cons{$dir} = "0 (0.00%)";
    }
    $min_total_UandNU = $TOTALMAPPED_CONS;
    $min_total_UandNU =~ s/,//g;

    $x = `grep "Total number consistent ambiguous" $filename`;
    chomp($x);
    $x =~ s/^.*: //;
    $x =~ /^(.*) /;
    my $NUTOTAL_F_and_R = $1;
    $NUTOTAL_F_and_R =~ s/,//g;
    if ($NUTOTAL_F_and_R =~ /^$/){
        $NUTOTAL_F_and_R = 0;
        $x = "0 (0.00%)";
    }
    $NUandFRconsistently{$dir} = $x;
    $min_nutotal = $NUTOTAL_F_and_R;
    $min_nutotal =~ s/,//g;

    $x = `grep "do overlap" $filename | head -1`;
    chomp($x);
    $x =~ s/[^\d,]//g;
    my $overlap = $x;
    $overlap =~ s/,//;
    $Overlap{$dir} = "$x";

    my $noverlap = 0;
    $x = `grep "don.t overlap" $filename | head -1`;
    chomp($x);
    $x =~ s/[^\d,]//g;
    $noverlap = $x;
    $noverlap =~ s/,//;
    $NOverlap{$dir} = "$x";

    if($overlap =~ /^$/){
        $overlap = 0;
    }
    if ($noverlap =~ /^$/){
        $noverlap = 0;
    }
    if($overlap + $noverlap > 0) {
        $Pover{$dir} = int($overlap / ($overlap+$noverlap) * 1000) / 10;
    }
    else{
        $Pover{$dir} = 0;
    }
    $Pover{$dir} = sprintf("%.2f", $Pover{$dir});
    $min_pover = $Pover{$dir};
    $min_pover =~ s/,//g;
    foreach my $key (sort keys %MITO){
        $x = `grep -w $key $filename | head -1`;
        my @a1 = split(" ",$x);
        $a1[1] =~ s/[^\d]//g;
        $x = $a1[1];
        if ($x eq ''){
	    $x = '0';
        }
        $y = int($x / $TOTALMAPPED * 1000) / 10;
        $y = sprintf("%.2f",$y);
        $min_chrm{$key} = $x;
        $max_chrm{$key} = $x;
        my $x2 = &format_large_int($x);
        if ($x2 eq ''){
	    $x2 = '0';
        }
        $UchrM{$dir}{$key} = "$x2 ($y%)";
    }
}
close(DIRS);

my $outfile = "$stats_dir/mappingstats_summary.txt"; 
my $mitofile = "$stats_dir/mitochondrial_percents.txt";
open(OUT, ">$outfile");
open(MITO, ">$mitofile");
#print OUT "id\ttotal\t!<>\t!<|>\t!chrM(%!)\t\%overlap\t~!<>\t~!<|>\t<|>\n";
print OUT "id\ttotalreads\tUniqueFWDandREV\tUniqueFWDorREV\t%overlap\tNon-UniqueFWDandREV\tNon-UniqueFWDorREV\tFWDandREVmapped\tFWDorREVmapped\n";
print MITO "id\t";
foreach my $key (sort keys %MITO){
    print MITO "Unique_$key\t";
}
print MITO "\n";
foreach my $dir (sort keys %UchrM) {
    print OUT "$dir\t$total{$dir}\t$uniqueandFRconsistently{$dir}\t$uniqueandAtLeastOneMapped{$dir}\t$Pover{$dir}%\t$NUandFRconsistently{$dir}\t$NUandAtLeastOneMapped{$dir}\t$TotalMapped_cons{$dir}\t$TotalMapped{$dir}\n";
    print MITO "$dir\t";
    foreach my $key (sort keys %{$UchrM{$dir}}){
        print MITO "$UchrM{$dir}{$key}\t";
    }
    print MITO "\n";
    my $x = $total{$dir};
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_total) {
	$min_total = $x;
    }
    if($x > $max_total) {
	$max_total = $x;
    }

    $x = $uniqueandFRconsistently{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_total_frcons) {
	$min_total_frcons = $x;
    }
    if($x > $max_total_frcons) {
	$max_total_frcons = $x;
    }

    $x = $TotalMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_total_UorNU) {
	$min_total_UorNU = $x;
    }
    if($x > $max_total_UorNU) {
	$max_total_UorNU = $x;
    }

    $x = $uniqueandAtLeastOneMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_utotal_f_or_r_cons) {
	$min_utotal_f_or_r_cons = $x;
    }
    if($x > $max_utotal_f_or_r_cons) {
	$max_utotal_f_or_r_cons = $x;
    }

    $x = $TotalMapped_cons{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_total_UandNU) {
        $min_total_UandNU = $x;
    }
    if($x > $max_total_UandNU) {
        $max_total_UandNU = $x;
    }

    $x = $uniqueandAtLeastOneMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_utotal_f_or_r_cons) {
        $min_utotal_f_or_r_cons = $x;
    }
    if($x > $max_utotal_f_or_r_cons) {
        $max_utotal_f_or_r_cons = $x;
    }


    foreach my $key (sort keys %{$UchrM{$dir}}){
        $x = $UchrM{$dir}{$key};
        $x =~ s/ \(.*//;
        $x =~ s/,//g;
        if ($x =~ /^$/){
          $x = 0;
        }
        if($x < $min_chrm{$key}) {
            $min_chrm{$key} = $x;
        }
        if($x > $max_chrm{$key}) {
            $max_chrm{$key} = $x;
        }
    }

    $x = $Pover{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_pover) {
	$min_pover = $x;
    }
    if($x > $max_pover) {
	$max_pover = $x;
    }

    $x = $NUandFRconsistently{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
        $x = 0;
    }
    if($x < $min_nutotal) {
	$min_nutotal = $x;
    }
    if($x > $max_nutotal) {
	$max_nutotal = $x;
    }

    $x = $NUandAtLeastOneMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if ($x =~ /^$/){
      $x = 0;
    }
    if($x < $min_nutotal_f_or_r) {
	$min_nutotal_f_or_r = $x;
    }
    if($x > $max_nutotal_f_or_r) {
	$max_nutotal_f_or_r = $x;
    }

}
$min_total = &format_large_int($min_total);
$min_total_frcons = &format_large_int($min_total_frcons);
$min_utotal_f_or_r_cons = &format_large_int($min_utotal_f_or_r_cons);
$min_nutotal = &format_large_int($min_nutotal);
$min_total_UorNU = &format_large_int($min_total_UorNU);
$min_total_UandNU = &format_large_int($min_total_UandNU);
$min_nutotal_f_or_r = &format_large_int($min_nutotal_f_or_r);
print OUT "mins\t$min_total\t$min_total_frcons\t$min_utotal_f_or_r_cons\t$min_pover\%\t$min_nutotal\t$min_nutotal_f_or_r\t$min_total_UandNU\t$min_total_UorNU\n";
print MITO "mins\t";
foreach my $key (sort keys %min_chrm){
    $min_chrm{$key} = &format_large_int($min_chrm{$key});
    print MITO "$min_chrm{$key}\t";
}
print MITO "\n";
$max_total = &format_large_int($max_total);
$max_total_frcons = &format_large_int($max_total_frcons);
$max_utotal_f_or_r_cons = &format_large_int($max_utotal_f_or_r_cons);
$max_nutotal = &format_large_int($max_nutotal);
$max_nutotal_f_or_r = &format_large_int($max_nutotal_f_or_r);
$max_total_UandNU = &format_large_int($max_total_UandNU);
$max_total_UorNU = &format_large_int($max_total_UorNU);
print OUT "maxs\t$max_total\t$max_total_frcons\t$max_utotal_f_or_r_cons\t$max_pover\%\t$max_nutotal\t$max_nutotal_f_or_r\t$max_total_UandNU\t$max_total_UorNU\n";
print MITO "maxs\t";
foreach my $key (sort keys %max_chrm){
    $max_chrm{$key} = &format_large_int($max_chrm{$key});
    print MITO "$max_chrm{$key}\t";
}
print MITO "\n";
print MITO "----------\n# (%) : %reads uniquely mapping to mitochondrial chromosome out of all mapped reads\n";
close(OUT);
close(MITO);
sub format_large_int () {
    my ($int) = @_;
    my @a = split(//,"$int");
    my $j=0;
    my $newint = "";
    my $n = @a;
    for(my $i=$n-1;$i>=0;$i--) {
	$j++;
	$newint = $a[$i] . $newint;
	if($j % 3 == 0) {
	    $newint = "," . $newint;
	}
    }
    $newint =~ s/^,//;
    return $newint;

}


print "got here\n";
