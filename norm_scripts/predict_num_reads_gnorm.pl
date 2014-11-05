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
 -stranded : set this if data are strand-specific.

 -se : set this if the data are single end, otherwise by default it will assume it's a paired end data

 -u  :  set this if you want to return number of unique reads only, otherwise by default it will return number of unique and non-unique reads

 -nu  :  set this if you want to return number of non-unique reads only, otherwise by default it will return number of unique and non-unique reads


";
}
my $U = 'true';
my $NU = 'true';
my $numargs_u_nu = 0;
my $se = "false";
my $stranded = "false";
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
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
    if ($ARGV[$i] eq '-se'){
	$se = "true";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
        $stranded = "true";
        $option_found = "true";
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
unless (-d "$stats_dir/GENE/"){
    `mkdir $stats_dir/GENE/`;
}
my $outfile = "$stats_dir/GENE/expected_num_reads_gnorm.txt";
if (-e "$outfile"){
    my $temp = $outfile;
    $temp =~ s/.txt$/.after_filter_high_expressers.txt/;
    $outfile = $temp;
}
my $tempfile = "$stats_dir/GENE/expected_num_reads_gnorm.temp";
my (@sumEU, @sumENU, @sumIU, @sumINU);

open(TEMP, ">$tempfile");
#print header for the table
print TEMP "ID\t";
#Unique
if ($U eq "true"){
    print TEMP "Unique\t";
}
#Non-Unique
if ($NU eq "true"){
    print TEMP "NU\t";
}

print TEMP "\n";

open(IN, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    print TEMP "$id\t";
    if ($U eq "true"){
	my $str_u;
	if ($stranded eq "false"){
	    $str_u = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.genes.linecount.txt`;
	}
	if ($stranded eq "true"){
	    $str_u = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.genes.sense.linecount.txt`;
	}
	chomp($str_u);
	my @a = split (/\t/, $str_u);
	my $N2 = $a[1];
	my $N = $N2 / 2;
	if ($se eq "true"){
	    $N = $N2;
	}
	print TEMP "$N\t";
    }
    if ($NU eq "true"){
	my $str_nu;
	if ($stranded eq "false"){
	    $str_nu = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.genes.linecount.txt`;
	}
	if ($stranded eq "true"){
            $str_nu = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.genes.sense.linecount.txt`;
        }
        chomp($str_nu);
        my @a = split (/\t/, $str_nu);
        my $N2 = $a[1];
	my $N = $N2 / 2;
	if ($se eq "true"){
	    $N = $N2;
	}
        print TEMP "$N\t";
    }
    print TEMP "\n";
}
close(TEMP);
my $SUM_U = 0;
my $SUM_NU = 0;

`sort -nk 2 $tempfile > $tempfile.sorted`;

my $sorted_list = `cut -f 1 $tempfile.sorted | sed '/ID/d'`;
my @s = split (/\n/, $sorted_list);
my $size = @s;
my @ID;
$ID[0] = "";
for(my $i=0;$i<=@s;$i++){
    $ID[$i+1] = $s[$i];
}

my @COLUMN_U;
my @COLUMN_NU;

# predict # reads after removing samples
open(IN, "$tempfile.sorted");
my $header = <IN>;
while(my $line = <IN>){
    chomp($line);
    my @a = split(/\t/, $line);
    if ($numargs_u_nu eq '0'){
	push (@COLUMN_U, $a[1]);
	push (@COLUMN_NU, $a[2]);
    }
    else{
	if ($U eq 'true'){
	    push (@COLUMN_U, $a[1]);
	}
	else{
	    push (@COLUMN_NU, $a[1]);
	}
    }
}
close(IN);

my @P_U;
my @P_NU;
if ($U eq "true"){
    my $min = &get_min(@COLUMN_U);
    $P_U[0] = $min;
    for(my $i=1; $i<$size;$i++){
	shift @COLUMN_U;
	$min = &get_min(@COLUMN_U);
	$P_U[$i] = $min;
    }
}
if ($NU eq "true"){
    my $min = &get_min(@COLUMN_NU);
    $P_NU[0] += $min;
    for(my $i=1; $i<$size;$i++){
	shift @COLUMN_NU;
	$min = &get_min(@COLUMN_NU);
	$P_NU[$i] = $min;
    }
}
#debug
=comment
for(my $i=0;$i<$size;$i++){
    print "$i\t$ID[$i]\t$P_U[$i]\t$P_NU[$i]\n";
}
=cut

my $sorted = `cat $tempfile.sorted`;

my $TOTAL;
if (($U eq "true") && ($NU eq "true")){
    $TOTAL = $P_U[0] + $P_NU[0];
    $SUM_U = &format_large_int($P_U[0]);
    $SUM_NU = &format_large_int($P_NU[0]);
}
else{
    if ($U eq "true"){
	$TOTAL = $P_U[0];
	$SUM_U = &format_large_int($P_U[0]);
    }
    if ($NU eq "true"){
	$TOTAL = $P_NU[0];
	$SUM_NU = &format_large_int($P_NU[0]);
    }
}
#print "exonu = $new_exon_u\nintronu = $new_intron_u\n exonnu = $new_exon_nu\n intronnu = $new_intron_nu\n";

open(OUT, ">$outfile");
$TOTAL = &format_large_int($TOTAL);
print OUT "\n[GENE NORMALIZATION]\n";
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
if ($stranded eq "true"){
    print OUT "\t\t\t\t\t\t\t (*For stranded data, these numbers refer to the sense gene mappers)\n";
}
print OUT "\n[1] You may remove sample ids from <sample_dirs> file to get more reads:\n\n<Expected number of reads after removing samples>\n";

my $num_to_remove;
if ($numargs_u_nu eq '0'){
    print OUT "#ids-to-rm\tUnique\tNU\tTOTAL\tSampleID\n";
    $num_to_remove = @P_U;
}
else{
    if ($U eq "true"){
	print OUT "#ids-to-rm\tUnique\tSampleID\n";
	$num_to_remove = @P_U;
    }
    else{ 
	print OUT "#ids-to-rm\tNU\tSampleID\n";
	$num_to_remove = @P_NU;
    }
}

for(my $i=0; $i<$num_to_remove;$i++){
    if ($numargs_u_nu eq '0'){
	my $P_TOTAL = $P_U[$i]+$P_NU[$i];
	$P_TOTAL = &format_large_int($P_TOTAL);
	my $P_U_F = &format_large_int($P_U[$i]);
	my $P_NU_F = &format_large_int($P_NU[$i]);
	print OUT "$i\t$P_U_F\t$P_NU_F\t$P_TOTAL\t$ID[$i]\n";
    }
    else{
	if ($U eq "true"){
	    my $P_U_F = &format_large_int($P_U[$i]);
	    print OUT "$i\t$P_U_F\t$ID[$i]\n";
	}
	if ($NU eq "true"){
	    my $P_NU_F = &format_large_int($P_NU[$i]);
	    print OUT "$i\t$P_NU_F\t$ID[$i]\n";
	}
    }
}
print OUT "\n[2] Breakdown of reads:\n\n";

print OUT $sorted;

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



