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
 -stranded : set this if your data are strand-specific.

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
my $stranded = "false";
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
    if ($ARGV[$i] eq '-stranded'){
	$option_found = "true";
	$stranded = "true";
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
    $temp =~ s/.txt$/.after_filter_high_expressers.txt/;
    $outfile = $temp;
}
my $tempfile = "$stats_dir/EXON_INTRON_JUNCTION/expected_num_reads.temp";
my $tempfile_exon = "$stats_dir/EXON_INTRON_JUNCTION/expected_num_reads_exononly.temp";
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
}
#Non-Unique
if ($NU eq "true"){
    for(my $i=1;$i<=$i_exon;$i++){
	print TEMP $i . "_ex_NU\t";
    }
    for(my $i=1;$i<=$i_intron;$i++){
	print TEMP $i . "_int_NU\t";
    }
}

if ($U eq "true"){
    print TEMP "TOTAL_U_exon\tTOTAL_U_intron\tinterg_U\t";
}
if ($NU eq "true"){
    print TEMP "TOTAL_NU_exon\tTOTAL_NU_intron\tinterg_NU";
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
    my $total_u_exon = 0;
    my $total_nu_exon = 0;
    my $total_u_intron = 0;
    my $total_nu_intron = 0;
    my $total_u_ig = 0;
    my $total_nu_ig = 0;
    print TEMP "$id\t";
    my $linecountfile_u = "$LOC/$id/EIJ/Unique/linecounts.txt";
    if ($stranded eq "true"){
	$linecountfile_u = "$LOC/$id/EIJ/Unique/sense/linecounts.txt";
    }
    my $linecountfile_nu = "$LOC/$id/EIJ/NU/linecounts.txt";
    if ($stranded eq "true"){
	$linecountfile_nu = "$LOC/$id/EIJ/NU/sense/linecounts.txt";
    }
    if ($U eq "true"){
	for (my $i=1; $i<=$i_exon; $i++){
	    my $str_e = `grep exonmappers.$i.sam $linecountfile_u`;
	    chomp($str_e);
	    my @a = split (/\t/, $str_e);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_u_exon += $N;
	    $sumEU[$i] += $N;
	}
	for (my $i=1; $i<=$i_intron; $i++){
	    my $str_i = `grep intronmappers.$i.sam $linecountfile_u`;
	    chomp($str_i);
	    my @a = split (/\t/, $str_i);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_u_intron += $N;
	    $sumIU[$i] += $N;
	}
	my $str_ig = `grep intergenicmappers.sam $linecountfile_u`;
	chomp($str_ig);
	my @a = split (/\t/, $str_ig);
	my $N = $a[1];
	$total_u_ig += $N;
	$sumIGU += $N;
    }
    if ($NU eq "true"){
	for (my $i=1; $i<=$i_exon; $i++){
	    my $str_e = `grep exonmappers.$i.sam $linecountfile_nu`;
	    chomp($str_e);
	    my @a = split (/\t/, $str_e);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_nu_exon += $N;
	    $sumENU[$i] += $N;
	}
	for (my $i=1; $i<=$i_intron; $i++){
	    my $str_i = `grep intronmappers.$i.sam $linecountfile_nu`;
	    chomp($str_i);
	    my @a = split (/\t/, $str_i);
	    my $N = $a[1];
	    print TEMP "$N\t";
	    $total_nu_intron += $N;
	    $sumINU[$i] += $N;
	}
	my $str_ig = `grep intergenicmappers.sam $linecountfile_nu`;
	chomp($str_ig);
	my @a = split (/\t/, $str_ig);
	my $N = $a[1];
	$total_nu_ig += $N;
	$sumIGNU += $N;
    }
    if ($U eq "true"){
	print TEMP "$total_u_exon\t$total_u_intron\t$total_u_ig\t";
    }
    if ($NU eq "true"){
	print TEMP "$total_nu_exon\t$total_nu_intron\t$total_nu_ig\t";
    }
    print TEMP "\n";
}
close(TEMP);

my $new_exon_u = 0;
my $new_intron_u = 0;
my $new_exon_nu = 0;
my $new_intron_nu = 0;
my $col_total = 0;
my $to_print = "";
if ($numargs_u_nu eq '0'){
    $col_total = ($i_exon + $i_intron) * 2 + 1 + 1;
    $to_print = $to_print . "\$1";
}
else{
    $col_total = ($i_exon + $i_intron) + 1 + 1;
    $to_print = $to_print . "\$1";
}

#sort by unique 1 exonmapper 
`sort -nk 2 $tempfile > $tempfile.sorted`;

my $sorted_list = `cut -f 1 $tempfile.sorted | sed '/ID/d'`;
my @s = split (/\n/, $sorted_list);
my $size = @s;
my @ID;
$ID[0] = "";
for(my $i=0;$i<=@s;$i++){
    $ID[$i+1] = $s[$i];
}

my %COLUMN_U_EX;
my %COLUMN_NU_EX;
my %COLUMN_U_INT;
my %COLUMN_NU_INT;
my %COLUMN_U_IG;
my %COLUMN_NU_IG;
# predict # reads after removing samples
open(IN, "$tempfile.sorted");
my $header = <IN>;
while(my $line = <IN>){
    chomp($line);
    my @a = split(/\t/, $line);
    if ($numargs_u_nu eq '0'){
	for(my $i=1;$i<=$i_exon;$i++){
	    push @{$COLUMN_U_EX{$i}}, $a[$i];
	}
	for(my $i=$i_exon+1;$i<($col_total/2);$i++){
            push @{$COLUMN_U_INT{$i}}, $a[$i];
        }
	for (my $j=$col_total/2;$j<($col_total/2)+$i_exon;$j++){
	    push @{$COLUMN_NU_EX{$j}}, $a[$j];
	}
        for (my $j=($col_total/2)+$i_exon;$j<$col_total-1;$j++){
            push @{$COLUMN_NU_INT{$j}}, $a[$j];
        }
	my $ig_u_col = $col_total+1;
	push @{$COLUMN_U_IG{$ig_u_col}}, $a[$ig_u_col];
	my $ig_nu_col = $col_total+4;
	push @{$COLUMN_NU_IG{$ig_nu_col}}, $a[$ig_nu_col];
    }
    else{
	my $ig_col = $col_total+1;
	if ($U eq 'true'){
	    for(my $i=1;$i<=$i_exon;$i++){
		push @{$COLUMN_U_EX{$i}}, $a[$i];
	    }
	    for(my $i=$i_exon+1;$i<$col_total-1;$i++){
                push @{$COLUMN_U_INT{$i}}, $a[$i];
	    }
	    push @{$COLUMN_U_IG{$ig_col}}, $a[$ig_col];
	}
	else{
	    for(my $i=1;$i<=$i_exon;$i++){
		push @{$COLUMN_NU_EX{$i}}, $a[$i];
	    }
            for(my $i=$i_exon+1;$i<$col_total-1;$i++){
                push @{$COLUMN_NU_INT{$i}}, $a[$i];
            }
	    push @{$COLUMN_NU_IG{$ig_col}}, $a[$ig_col];
	}
    }
}
close(IN);

my @P_SUM_U_EX;
my @P_SUM_NU_EX;
my @P_SUM_U_INT;
my @P_SUM_NU_INT;
my @P_IG_U;
my @P_IG_NU;
if ($U eq "true"){
    foreach my $key (sort {$a <=> $b} keys %COLUMN_U_EX){
	my $min_ex = &get_min(@{$COLUMN_U_EX{$key}});
	$P_SUM_U_EX[0] += $min_ex;
	for(my $i=1; $i<$size;$i++){
	    shift @{$COLUMN_U_EX{$key}};
	    $min_ex = &get_min(@{$COLUMN_U_EX{$key}});
	    $P_SUM_U_EX[$i] += $min_ex;
	}
	my $int_key = $key+$i_exon;
	if (defined $COLUMN_U_INT{$int_key}){
	    my $min_int = &get_min(@{$COLUMN_U_INT{$int_key}});
	    $P_SUM_U_INT[0] += $min_int;
	    for(my $i=1; $i<$size;$i++){
		shift @{$COLUMN_U_INT{$key}};
		$min_int = &get_min(@{$COLUMN_U_INT{$int_key}});
		$P_SUM_U_INT[$i] += $min_int;
	    }
	}
    }
    my $ig_key = $col_total+1;
    if (defined $COLUMN_U_IG{$ig_key}){
	my $min_ig = &get_min(@{$COLUMN_U_IG{$ig_key}});
	$P_IG_U[0] += $min_ig;
	for(my $i=1; $i<$size;$i++){
	    shift @{$COLUMN_U_IG{$ig_key}};
	    $min_ig = &get_min(@{$COLUMN_U_IG{$ig_key}});
	    $P_IG_U[$i] += $min_ig;
	}
    }
}
if ($NU eq "true"){
    foreach my $key (sort {$a <=> $b} keys %COLUMN_NU_EX){
	my $min_ex = &get_min(@{$COLUMN_NU_EX{$key}});
	$P_SUM_NU_EX[0] += $min_ex;
	for(my $i=1; $i<$size;$i++){
	    shift @{$COLUMN_NU_EX{$key}};
	    $min_ex = &get_min(@{$COLUMN_NU_EX{$key}});
	    $P_SUM_NU_EX[$i] += $min_ex;
	}
        my $int_key = $key+$i_exon;
	if (defined $COLUMN_NU_INT{$int_key}){
	    my $min_int = &get_min(@{$COLUMN_NU_INT{$int_key}});
	    $P_SUM_NU_INT[0] += $min_int;	    
	    for(my $i=1; $i<$size;$i++){
		shift @{$COLUMN_NU_INT{$key}};
		$min_int = &get_min(@{$COLUMN_NU_INT{$key+$i_exon}});
		$P_SUM_NU_INT[$i] += $min_int;
	    }
	}
    }
    my $ig_key = $col_total+4;
    if ($numargs_u_nu ne '0'){
	$ig_key = $col_total+1;
    }
    if (defined $COLUMN_NU_IG{$ig_key}){
        my $min_ig = &get_min(@{$COLUMN_NU_IG{$ig_key}});
        $P_IG_NU[0] += $min_ig;
        for(my $i=1; $i<$size;$i++){
            shift @{$COLUMN_NU_IG{$ig_key}};
            $min_ig = &get_min(@{$COLUMN_NU_IG{$ig_key}});
            $P_IG_NU[$i] += $min_ig;
        }
    }
}
=debug
for(my $i=0;$i<$size;$i++){
    print "$i\t$ID[$i]\t$P_SUM_U_EX[$i]\t$P_SUM_NU_EX[$i]\t$P_SUM_U_INT[$i]\t$P_SUM_NU_INT[$i]\n";
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
    #NU
    for (my $i=2+$i_exon+$i_intron; $i<2+$i_exon+$i_intron+$new_exon_nu; $i++){
	$to_print = $to_print . ",\$$i";
    }
    for (my $i=2+$i_exon+$i_intron+$i_exon; $i<2+$i_exon+$i_intron+$i_exon+$new_intron_nu;$i++){
    	$to_print = $to_print . ",\$$i";
    }
    $to_print = $to_print . ",\$$col_total, \$($col_total+1), \$($col_total+2), \$($col_total+3), \$($col_total+4), \$($col_total+5)";
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
	$to_print = $to_print . ",\$$col_total, \$($col_total+1), \$($col_total+2)";
    }
    #NU
    if ($NU eq "true"){
        for (my $i=2; $i<2+$new_exon_nu; $i++){
            $to_print = $to_print . ",\$$i";
        }
        for (my $i=2+$i_exon; $i<2+$i_exon+$new_intron_nu;$i++){
            $to_print = $to_print . ",\$$i";
        }
	$to_print = $to_print . ",\$$col_total, \$($col_total+1), \$($col_total+2)";
    }
}

my $rearr = `awk -v OFS=\$\'\t\' \'{print $to_print}\' $tempfile.sorted`;

my $TOTAL_EXON;
my $TOTAL_INTRON;
my $TOTAL_IG;
my $SUM_U_EX = 0;
my $SUM_NU_EX = 0;
my $SUM_U_INT = 0;
my $SUM_NU_INT = 0;
my $IG_U = 0;
my $IG_NU = 0;
if (($U eq "true") && ($NU eq "true")){
    $TOTAL_EXON = $P_SUM_U_EX[0] + $P_SUM_NU_EX[0];
    $SUM_U_EX = &format_large_int($P_SUM_U_EX[0]);
    $SUM_NU_EX = &format_large_int($P_SUM_NU_EX[0]);
    $TOTAL_INTRON = $P_SUM_U_INT[0] + $P_SUM_NU_INT[0];
    $SUM_U_INT = &format_large_int($P_SUM_U_INT[0]);
    $SUM_NU_INT = &format_large_int($P_SUM_NU_INT[0]);
    $TOTAL_IG = $P_IG_U[0] + $P_IG_NU[0];
    $IG_U = &format_large_int($P_IG_U[0]);
    $IG_NU = &format_large_int($P_IG_NU[0]);
}
else{
    if ($U eq "true"){
	$TOTAL_EXON = $P_SUM_U_EX[0];
	$SUM_U_EX = &format_large_int($P_SUM_U_EX[0]);
	$TOTAL_INTRON = $P_SUM_U_INT[0];
	$SUM_U_INT = &format_large_int($P_SUM_U_INT[0]);
	$TOTAL_IG = $P_IG_U[0];
	$IG_U = &format_large_int($P_IG_U[0]);
    }
    if ($NU eq "true"){
	$TOTAL_EXON = $P_SUM_NU_EX[0];
	$SUM_NU_EX = &format_large_int($P_SUM_NU_EX[0]);
	$TOTAL_INTRON = $P_SUM_NU_INT[0];
	$SUM_NU_INT = &format_large_int($P_SUM_NU_INT[0]);
        $TOTAL_IG = $P_IG_NU[0];
        $IG_NU = &format_large_int($P_IG_NU[0]);
    }
}
#print "exonu = $new_exon_u\nintronu = $new_intron_u\n exonnu = $new_exon_nu\n intronnu = $new_intron_nu\n";

open(OUT, ">$outfile");
$TOTAL_EXON = &format_large_int($TOTAL_EXON);
$TOTAL_INTRON = &format_large_int($TOTAL_INTRON);
$TOTAL_IG = &format_large_int($TOTAL_IG);
print OUT "\n[EXON INTRON JUNCTION NORMALIZATION]\n";
if (($U eq "true") && ($NU eq "true")){
    print OUT "\nExpected number of reads after normalization (estimate): $TOTAL_EXON total exonmappers\t$TOTAL_INTRON total intronmappers\t$TOTAL_IG total intergenicmappers\n";
    print OUT "\t\t\t\t\t\t\t $SUM_U_EX unique exonmappers\t$SUM_U_INT unique intronmappers\t$IG_U unique intergenicmappers\n";
    print OUT "\t\t\t\t\t\t\t $SUM_NU_EX non-unique exonmappers\t$SUM_NU_INT non-unique intronmappers\t$IG_NU non-unique intergenicmappers\n";
}
else{
    if ($U eq "true"){
	print OUT "\nExpected number of reads after normalization (estimate): $TOTAL_EXON unique exonmappers\t$TOTAL_INTRON unique intronamppers\t$TOTAL_IG unique intergenicmappers\n";
    }
    if ($NU eq "true"){
	print OUT "\nExpected number of reads after normalization (estimate): $TOTAL_EXON non-unique exonmappers\t$TOTAL_INTRON non-unique intronamppers\t$TOTAL_IG non-unique intergenicmappers\n";
    }
}
if ($stranded eq "true"){
    print OUT "\t\t\t\t\t\t\t (*For stranded data, these numbers refer to the sense exon/intron/intergenic mappers)\n";
}
print OUT "\n[1] You may remove sample ids from <sample_dirs> file to get more reads:\n\n<Expected number of reads after removing samples>\n";
my $num_to_remove;
if ($numargs_u_nu eq '0'){
    print OUT "#ids-to-rm\tu-EX\tu-INT\tu-IG\tnu-EX\tnu-INT\tnu-IG\tSampleID\n";
    $num_to_remove = @P_SUM_U_EX;
}
else{
    if ($U eq "true"){
	print OUT "#ids-to-rm\tu-EX\tu-INT\tu-IG\tSampleID\n";
	$num_to_remove = @P_SUM_U_EX;
    }
    else{ 
	print OUT "#ids-to-rm\tnu-EX\tnu-INT\tnu-IG\ttSampleID\n";
	$num_to_remove = @P_SUM_NU_EX;
    }
}

for(my $i=0; $i<$num_to_remove;$i++){
    if ($numargs_u_nu eq '0'){
	my $P_U_EX = &format_large_int($P_SUM_U_EX[$i]);
	my $P_U_INT = &format_large_int($P_SUM_U_INT[$i]);
	my $P_U_IG = &format_large_int($P_IG_U[$i]);
	my $P_NU_EX = &format_large_int($P_SUM_NU_EX[$i]);
	my $P_NU_INT = &format_large_int($P_SUM_NU_INT[$i]);
	my $P_NU_IG = &format_large_int($P_IG_NU[$i]);
	print OUT "$i\t$P_U_EX\t$P_U_INT\t$P_U_IG\t$P_NU_EX\t$P_NU_INT\t$P_NU_IG\t$ID[$i]\n";
    }
    else{
	if ($U eq "true"){
	    my $P_U_EX = &format_large_int($P_SUM_U_EX[$i]);
	    my $P_U_INT = &format_large_int($P_SUM_U_INT[$i]);
	    my $P_U_IG = &format_large_int($P_IG_U[$i]);
	    print OUT "$i\t$P_U_EX\t$P_U_INT\t$P_U_IG\t$ID[$i]\n";
	}
	if ($NU eq "true"){
	    my $P_NU_EX = &format_large_int($P_SUM_NU_EX[$i]);
	    my $P_NU_INT = &format_large_int($P_SUM_NU_INT[$i]);
	    my $P_NU_IG = &format_large_int($P_IG_NU[$i]);
	    print OUT "$i\t$P_NU_EX\t$P_NU_INT\t$P_NU_IG\t$ID[$i]\n";
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



