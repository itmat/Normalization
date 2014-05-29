#!/usr/bin/env perl
if(@ARGV<2) {
    die "Usage: perl predict_num_reads.pl <sample dirs> <loc> [options]

This will provide a rough estimate of number of reads you'll have after normalization.
You can remove unwanted samples from your <sample dirs> file.

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

option:

 -se  :  set this if the data is single end, otherwise by default it will assume it's a paired end data

";
}

$pe = "true";
for($i=2; $i<@ARGV; $i++) {
    $option_found = 'false';
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$stats_dir = $study_dir . "STATS";


$mappingstats = "$stats_dir/mappingstats_summary.txt";
unless (-e $mappingstats){
    die "\"$mappingstats\" file does not exist\n";
}
$ribo = "$stats_dir/ribo_percents.txt";
unless (-e $ribo){
    die "\"$ribo\" file does not exist\n";
}
$x = 10000000000000000;
$y = 10000000000000000;

$outfile = "$stats_dir/expected_num_reads.txt";

open(IN, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
while($line = <IN>){
    chomp($line);
    $id = $line;
    $m = `grep $id $mappingstats`;
    @a = split(/\t/, $m);
    #unique
    if ($pe eq "true"){
	$u_f_and_r = $a[2];
    }
    if ($pe eq "false"){
	$u_f_and_r = $a[3];
    }
    $u_f_and_r =~ m/(.*)\(.*\)/;
    $u_f_and_r = $1;
    $u_f_and_r =~ s/\,//g;
    $chrM = $a[4];
    $chrM =~ m/(.*)\(.*\)/;
    $chrM = $1;
    $chrM =~ s/,//g;
    $ribo_info = `grep $id $ribo`;
    @r = split(/\t/, $ribo_info);
    $ribo_percent = $r[2];
    $unique_R = $u_f_and_r * $ribo_percent ;
    $u_noM_noR = int($u_f_and_r - $chrM - $unique_R);
    if ($u_noM_noR < $x){
	$min_u = $u_noM_noR;
    }
    $x = $min_u;
    #non-unique
    if ($pe eq "true"){
	$nu_f_and_r = $a[6];
    }
    if ($pe eq "false"){
	$nu_f_and_r = $a[7];
    }
    $nu_f_and_r =~ m/(.*)\(.*\)/;
    $nu_f_and_r = $1;
    $nu_f_and_r =~ s/\,//g;
    $nu_R = $nu_f_and_r * $ribo_percent ;
    $nu_noR = int($nu_f_and_r - $nu_R);
    if ($nu_noR < $y){
	$min_nu = $nu_noR;
    }
    $y = $min_nu;
    $total_after_filter = $u_noM_noR + $nu_noR;
    $total_after_filter = &format_large_int($total_after_filter);
    $u_noM_noR = &format_large_int($u_noM_noR);
    $nu_noR = &format_large_int($nu_noR);
    $string = "$total_after_filter\t$u_noM_noR\t$nu_noR";
    #$TOTAL{$id} = $total_after_filter;
    $TOTAL{$id} = $string;
}
#print "Unique : $min_u\n";
#print "NU : $min_nu\n";
open(OUT, ">$outfile");
$total = $min_u + $min_nu;
$total = &format_large_int($total);
print OUT "\nExpected number of reads after normalization (rough estimate): $total\n";
print OUT "\nid\ttotal_reads\ttotal_after_filter\tunique_after_filter\tnu_after_filter\n";
foreach $key (sort keys %TOTAL){
    $total = `grep -w $key "$stats_dir/total_num_reads.txt"`;
    chomp($total);
    @a = split(/\t/, $total);
    $total_before = $a[1];
    $total_before = &format_large_int($total_before);
    print OUT "$key\t$total_before\t$TOTAL{$key}\n";
}
close(OUT);
print "got here\n";
sub format_large_int () {
    ($int) = @_;
    @a = split(//,"$int");
    $j=0;
    $newint = "";
    $n = @a;
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
