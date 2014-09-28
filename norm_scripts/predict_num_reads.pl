#!/usr/bin/env perl
use warnings;
use strict;
if(@ARGV<2) {
    die "Usage: perl predict_num_reads.pl <sample dirs> <loc> [options]

This will provide a rough estimate of number of reads you'll have after normalization.
You can remove unwanted samples from your <sample dirs> file.

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

options:

 -u  :  set this if you want to return number of unique reads only, otherwise by default it will return number of unique and non-unique reads

 -nu  :  set this if you want to return number of non-unique reads only, otherwise by default it will return number of unique and non-unique reads

 -depthE <n> : This is the number of exonmappers file used for normalization.
               By default, <n> = 20.

 -depthI <n> : This is the number of intronmappers file used for normalization.
               By default, <n> = 10.

";
}
my $U = 'true';
my $NU = 'true';
my $numargs_u_nu = 0;
my $i_exon = 20;
my $i_intron = 10;
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-depthE'){
	$i_exon = $ARGV[$i+1];
	if ($i_exon !~ /(\d+$)/ ){
	    die "-depthE <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthI'){
	$i_intron = $ARGV[$i+1];
	if ($i_intron !~ /(\d+$)/ ){
	    die "-depthI <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-u'){
	$NU = "false";
	$option_found = "true";
	$numargs_u_nu++;
    }
    if ($ARGV[$i] eq '-nu'){
	$U = "false";
	$option_found = "true";
	$numargs_u_nu++;
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
unless (-d "$stats_dir"){
    `mkdir $stats_dir`;
}
unless (-d "$stats_dir/EXON_INTRON_JUNCTION/"){
    `mkdir $stats_dir/EXON_INTRON_JUNCTION/`;
}
my $outfile = "$stats_dir/EXON_INTRON_JUNCTION/expected_num_reads.txt";
if (-e $outfile){
    my $temp = $outfile;
    $temp =~ s/.txt$/.filter_highexp.txt/;
    $outfile = $temp;
}
my $tempfile = "$stats_dir/EXON_INTRON_JUNCTION/expected_num_reads.temp";
my (@sumEU, @sumENU, @sumIU, @sumINU);

open(TEMP, ">$tempfile");
#print header for the table
print TEMP "ID\t";
#Unique
if ($U eq "true"){
    for(my $i=1;$i<=$i_exon;$i++){
	print TEMP $i . "_ex_U\t";
    }
    for(my $i=1;$i<=$i_intron;$i++){
	print TEMP $i . "_int_U\t";
    }
    print TEMP "interg_U\t";
}
#Non-Unique
if ($NU eq "true"){
    for(my $i=1;$i<=$i_exon;$i++){
	print TEMP $i . "_ex_NU\t";
    }
    for(my $i=1;$i<=$i_intron;$i++){
	print TEMP $i . "_int_NU\t";
    }
    print TEMP "interg_NU\t";
}

if ($U eq "true"){
    print TEMP "TOTAL_U\t";
}
if ($NU eq "true"){
    print TEMP "TOTAL_NU\t";
}
print TEMP "\n";

for (my $i=1; $i<=$i_exon; $i++){
    $sumEU[$i] = 0;
    $sumENU[$i] = 0;
}
for (my $i=1; $i<=$i_intron;$i++){
    $sumIU[$i] = 0;
    $sumINU[$i] = 0;
}
my $sumIGU = 0;
my $sumIGNU = 0;

open(IN, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my $total_u = 0;
    my $total_nu = 0;
    print TEMP "$id\t";
    if ($U eq "true"){
	for (my $i=1; $i<=$i_exon; $i++){
	    my $str_e = `head -$i $LOC/$id/EIJ/Unique/$id.linecounts_exons.txt | tail -1`;
	    chomp($str_e);
	    my @a = split (/\t/, $str_e);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_u += $N;
	    $sumEU[$i] += $N;
	}
	for (my $i=1; $i<=$i_intron; $i++){
	    my $line_num = $i+1;
	    my $str_i = `head -$line_num $LOC/$id/EIJ/Unique/$id.linecounts_notexons.txt | tail -1`;
	    chomp($str_i);
	    my @a = split (/\t/, $str_i);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_u += $N;
	    $sumIU[$i] += $N;
	}
	my $str_ig = `head -1 $LOC/$id/EIJ/Unique/$id.linecounts_notexons.txt`;
	chomp($str_ig);
	my @a = split (/\t/, $str_ig);
	my $N = $a[1];
	print TEMP "$N\t";
	$total_u += $N;
	$sumIGU += $N;
    }
    if ($NU eq "true"){
	for (my $i=1; $i<=$i_exon; $i++){
	    my $str_e = `head -$i $LOC/$id/EIJ/NU/$id.linecounts_exons.txt | tail -1`;
	    chomp($str_e);
	    my @a = split (/\t/, $str_e);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_nu += $N;
	    $sumENU[$i] += $N;
	}
	for (my $i=1; $i<=$i_intron; $i++){
	    my $line_num = $i+1;
	    my $str_i = `head -$line_num $LOC/$id/EIJ/NU/$id.linecounts_notexons.txt | tail -1`;
	    chomp($str_i);
	    my @a = split (/\t/, $str_i);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_nu += $N;
	    $sumINU[$i] += $N;
	}
	my $str_ig = `head -1 $LOC/$id/EIJ/NU/$id.linecounts_notexons.txt`;
	chomp($str_ig);
	my @a = split (/\t/, $str_ig);
	my $N = $a[1];
	print TEMP "$N\t";
	$total_nu += $N;
	$sumIGNU += $N;
    }
    if ($U eq "true"){
	print TEMP "$total_u\t";
    }
    if ($NU eq "true"){
	print TEMP "$total_nu\t";
    }
    print TEMP "\n";
}
close(TEMP);

my $SUM_U = 0;
my $SUM_NU = 0;
my $new_exon_u = 0;
my $new_intron_u = 0;
my $new_exon_nu = 0;
my $new_intron_nu = 0;
my $col_total = 0;
my $to_print = "";
if ($numargs_u_nu eq '0'){
    $col_total = ($i_exon + $i_intron + 1) * 2 + 1 + 1;
    $to_print = $to_print . "\$1";
}
else{
    $col_total = ($i_exon + $i_intron + 1) + 1 + 1;
    $to_print = $to_print . "\$1";
}
`sort -nk 2 $tempfile > $tempfile.sorted`;

my $sorted_list = `cut -f 1 $tempfile.sorted | sed '/ID/d'`;
my @s = split (/\n/, $sorted_list);
my $size = @s;
my @ID;
$ID[0] = "";
for(my $i=0;$i<=@s;$i++){
    $ID[$i+1] = $s[$i];
}

my %COLUMN_U;
my %COLUMN_NU;
# predict # reads after removing samples
open(IN, "$tempfile.sorted");
my $header = <IN>;
while(my $line = <IN>){
    chomp($line);
    my @a = split(/\t/, $line);
    if ($numargs_u_nu eq '0'){
	for(my $i=1;$i<$col_total/2;$i++){
	    push @{$COLUMN_U{$i}}, $a[$i];
	}
	for (my $j=$col_total/2;$j<$col_total-1;$j++){
	    push @{$COLUMN_NU{$j}}, $a[$j];
	}
    }
    else{
	if ($U eq 'true'){
	    for(my $i=1;$i<$col_total-1;$i++){
		push @{$COLUMN_U{$i}}, $a[$i];
	    }
	}
	else{
	    for(my $i=1;$i<$col_total-1;$i++){
		push @{$COLUMN_NU{$i}}, $a[$i];
	    }
	}
    }
}
close(IN);

my @P_SUM_U;
my @P_SUM_NU;
if ($U eq "true"){
    foreach my $key (sort {$a <=> $b} keys %COLUMN_U){
	my $min = &get_min(@{$COLUMN_U{$key}});
	$P_SUM_U[0] += $min;
	for(my $i=1; $i<$size;$i++){
	    shift @{$COLUMN_U{$key}};
	    $min = &get_min(@{$COLUMN_U{$key}});
	    $P_SUM_U[$i] += $min;
	}
    }
}
if ($NU eq "true"){
    foreach my $key (sort {$a <=> $b} keys %COLUMN_NU){
	my $min = &get_min(@{$COLUMN_NU{$key}});
	$P_SUM_NU[0] += $min;
	for(my $i=1; $i<$size;$i++){
	    shift @{$COLUMN_NU{$key}};
	    $min = &get_min(@{$COLUMN_NU{$key}});
	    $P_SUM_NU[$i] += $min;
	}
    }
}
#debug
=comment
for(my $i=0;$i<$size;$i++){
    print "$i\t$ID[$i]\t$P_SUM_U[$i]\t$P_SUM_NU[$i]\n";
}
=cut
if ($U eq "true"){
    for (my $i=1; $i<=$i_exon; $i++){
	if ($sumEU[$i] > 0){
	    $new_exon_u = $i;
	}
    }
    for (my $i=1; $i<=$i_intron;$i++){
	if ($sumIU[$i] > 0){
	    $new_intron_u = $i;
	}
    }
}
if ($NU eq "true"){
    for (my $i=1; $i<=$i_exon; $i++){
	if ($sumENU[$i] > 0){
	    $new_exon_nu = $i;
	}
    }
    for (my $i=1; $i<=$i_intron;$i++){
	if ($sumINU[$i] > 0){
	    $new_intron_nu = $i;
	}
    }
}

if ($numargs_u_nu eq '0'){
    #Unique
    for (my $i=2; $i<2+$new_exon_u; $i++){
	$to_print = $to_print . ",\$$i";
    }
    for (my $i=2+$i_exon; $i<2+$i_exon+$new_intron_u;$i++){
    	$to_print = $to_print . ",\$$i";
    }
    $to_print = $to_print . ",\$(2+$i_exon+$i_intron)";
    #NU
    for (my $i=3+$i_exon+$i_intron; $i<3+$i_exon+$i_intron+$new_exon_nu; $i++){
	$to_print = $to_print . ",\$$i";
    }
    for (my $i=3+$i_exon+$i_intron+$i_exon; $i<3+$i_exon+$i_intron+$i_exon+$new_intron_nu;$i++){
    	$to_print = $to_print . ",\$$i";
    }
    $to_print = $to_print . ",\$(3+$i_exon+$i_intron+$i_exon+$i_intron)";
    $to_print = $to_print . ",\$$col_total, \$($col_total+1)";
}
else{
    #Unique
    if ($U eq "true"){
	for (my $i=2; $i<2+$new_exon_u; $i++){
	    $to_print = $to_print . ",\$$i";
	}
	for (my $i=2+$i_exon; $i<2+$i_exon+$new_intron_u;$i++){
	    $to_print = $to_print . ",\$$i";
	}
	$to_print = $to_print . ",\$(2+$i_exon+$i_intron)";
	$to_print = $to_print . ",\$$col_total";
    }
    #NU
    if ($NU eq "true"){
        for (my $i=2; $i<2+$new_exon_nu; $i++){
            $to_print = $to_print . ",\$$i";
        }
        for (my $i=2+$i_exon; $i<2+$i_exon+$new_intron_nu;$i++){
            $to_print = $to_print . ",\$$i";
        }
        $to_print = $to_print . ",\$(2+$i_exon+$i_intron)";
	$to_print = $to_print . ",\$$col_total";
    }
}

my $rearr = `awk -v OFS=\$\'\t\' \'{print $to_print}\' $tempfile.sorted`;
#print $rearr;

my $TOTAL;
if (($U eq "true") && ($NU eq "true")){
    $TOTAL = $P_SUM_U[0] + $P_SUM_NU[0];
    $SUM_U = &format_large_int($P_SUM_U[0]);
    $SUM_NU = &format_large_int($P_SUM_NU[0]);
}
else{
    if ($U eq "true"){
	$TOTAL = $P_SUM_U[0];
	$SUM_U = &format_large_int($P_SUM_U[0]);
    }
    if ($NU eq "true"){
	$TOTAL = $P_SUM_NU[0];
	$SUM_NU = &format_large_int($P_SUM_NU[0]);
    }
}
#print "exonu = $new_exon_u\nintronu = $new_intron_u\n exonnu = $new_exon_nu\n intronnu = $new_intron_nu\n";

open(OUT, ">$outfile");
$TOTAL = &format_large_int($TOTAL);
print OUT "\n[EXON INTRON JUNCTION NORMALIZATION]\n";
print OUT "\nExpected number of reads after normalization (estimate): $TOTAL";
if (($U eq "true") && ($NU eq "true")){
    print OUT " total reads\n";
    print OUT "\t\t\t\t\t\t\t $SUM_U unique reads\n";
    print OUT "\t\t\t\t\t\t\t $SUM_NU non-unique reads\n";
}
else{
    if ($U eq "true"){
	print OUT " (unique reads)\n";
    }
    if ($NU eq "true"){
	print OUT " (non-unique reads)\n";
    }
}
print OUT "\n[1] You may remove sample ids from <sample_dirs> file to get more reads:\n\n<Expected number of reads after removing samples>\n";

my $num_to_remove;
if ($numargs_u_nu eq '0'){
    print OUT "#ids-to-rm\tUnique\tNU\tTOTAL\tSampleID\n";
    $num_to_remove = @P_SUM_U;
}
else{
    if ($U eq "true"){
	print OUT "#ids-to-rm\tUnique\tSampleID\n";
	$num_to_remove = @P_SUM_U;
    }
    else{ 
	print OUT "#ids-to-rm\tNU\tSampleID\n";
	$num_to_remove = @P_SUM_NU;
    }
}

for(my $i=0; $i<$num_to_remove;$i++){
    if ($numargs_u_nu eq '0'){
	my $P_TOTAL = $P_SUM_U[$i]+$P_SUM_NU[$i];
	$P_TOTAL = &format_large_int($P_TOTAL);
	my $P_U = &format_large_int($P_SUM_U[$i]);
	my $P_NU = &format_large_int($P_SUM_NU[$i]);
	print OUT "$i\t$P_U\t$P_NU\t$P_TOTAL\t$ID[$i]\n";
    }
    else{
	if ($U eq "true"){
	    my $P_U = &format_large_int($P_SUM_U[$i]);
	    print OUT "$i\t$P_U\t$ID[$i]\n";
	}
	if ($NU eq "true"){
	    my $P_NU = &format_large_int($P_SUM_NU[$i]);
	    print OUT "$i\t$P_NU\t$ID[$i]\n";
	}
    }
}
print OUT "\n[2] Breakdown of reads:\n\n";

print OUT $rearr;

`rm $tempfile $tempfile.sorted`;

print "got here\n";

sub format_large_int () {
    (my $int) = @_;
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

sub get_min(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[0];
}



