#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "Usage: perl predict_num_reads.pl <sample dirs> <loc> [options]

This will provide a rough estimate of number of reads you'll have after normalization.
You can remove unwanted samples from your <sample dirs> file.

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

options:
 -stranded : set this if data are strand-specific.

 -se : set this if the data are single end, otherwise by default it will assume it's a paired end data

 -u  :  set this if you want to return number of unique reads only, otherwise by default it will return number of unique and non-unique reads

 -nu  :  set this if you want to return number of non-unique reads only, otherwise by default it will return number of unique and non-unique reads
 
 -alt_stats <s>

 -h : print usage

";
if(@ARGV<2) {
    die $USAGE;
}
my $U = 'true';
my $NU = 'true';
my $numargs_u_nu = 0;
my $se = "false";
my $stranded = "false";
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";

for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-alt_stats'){
	$option_found = "true";
	$stats_dir = $ARGV[$i+1];
	$i++;
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

open(TEMP, ">$tempfile");
#print header for the table
print TEMP "ID\t";
#Unique
if ($U eq "true"){
    if ($stranded eq "true"){
	print TEMP "senseUnique\t";
    }
    if ($stranded eq "false"){
	print TEMP "Unique\t";
    }
}
#Non-Unique
if ($NU eq "true"){
    if ($stranded eq "true"){
	print TEMP "senseNU\t";
    }
    if ($stranded eq "false"){
	print TEMP "NU\t";
    }
}

#antisense
if ($stranded eq "true"){
    if ($U eq "true"){
	print TEMP "antisenseUnique\t";
    }
    if ($NU eq "true"){
	print TEMP "antisenseNU\t";
    }
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
    if ($stranded eq "true"){
	if ($U eq "true"){
	    my $str_u_a = `cat $LOC/$id/GNORM/Unique/$id.filtered_u.genes.antisense.linecount.txt`;
	    chomp($str_u_a);
	    my @a = split (/\t/, $str_u_a);
	    my $N2 = $a[1];
	    my $N = $N2 / 2;
	    if ($se eq "true"){
		$N = $N2;
	    }
	    print TEMP "$N\t";
	}
	if ($NU eq "true"){
	    my $str_nu_a = `cat $LOC/$id/GNORM/NU/$id.filtered_nu.genes.antisense.linecount.txt`;
	    chomp($str_nu_a);
	    my @a = split (/\t/, $str_nu_a);
	    my $N2 = $a[1];
	    my $N = $N2 / 2;
	    if ($se eq "true"){
		$N = $N2;
	    }
	    print TEMP "$N\t";
	}
    }
    print TEMP "\n";
}
close(TEMP);
my $SUM_U = 0;
my $SUM_NU = 0;
my $SUM_U_A = 0;
my $SUM_NU_A = 0;

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
my @COLUMN_U_A;
my @COLUMN_NU_A;

# predict # reads after removing samples
open(IN, "$tempfile.sorted");
my $header = <IN>;
while(my $line = <IN>){
    chomp($line);
    my @a = split(/\t/, $line);
    if ($numargs_u_nu eq '0'){ #both u and nu true
	push (@COLUMN_U, $a[1]);
	push (@COLUMN_NU, $a[2]);
	if ($stranded eq "true"){
	    push (@COLUMN_U_A, $a[3]);
	    push (@COLUMN_NU_A, $a[4]);
	}
    }
    else{
	if ($U eq 'true'){
	    push (@COLUMN_U, $a[1]);
	    if ($stranded eq "true"){
		push (@COLUMN_U_A, $a[2]);
	    }
	}
	else{
	    push (@COLUMN_NU, $a[1]);
            if ($stranded eq "true"){
		push (@COLUMN_NU_A, $a[2]);
            }
	}
    }
}
close(IN);

my @P_U;
my @P_NU;
my @P_U_A;
my @P_NU_A;
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
if ($stranded eq "true"){
    if ($U eq "true"){
	my $min = &get_min(@COLUMN_U_A);
	$P_U_A[0] = $min;
	for(my $i=1; $i<$size;$i++){
	    shift @COLUMN_U_A;
	    $min = &get_min(@COLUMN_U_A);
	    $P_U_A[$i] = $min;
	}
    }
    if ($NU eq "true"){
	my $min = &get_min(@COLUMN_NU_A);
	$P_NU_A[0] += $min;
	for(my $i=1; $i<$size;$i++){
	    shift @COLUMN_NU_A;
	    $min = &get_min(@COLUMN_NU_A);
	    $P_NU_A[$i] = $min;
	}
    }
}
#debug
=comment
for(my $i=0;$i<$size;$i++){
    print "$i\t$ID[$i]\t$P_U[$i]\t$P_NU[$i]\t$P_U_A[$i]\t$P_NU_A[$i]\n";
}
=cut

my $sorted = `cat $tempfile.sorted`;

my $TOTAL;
my $TOTAL_A;
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
if ($stranded eq "true"){
    if (($U eq "true") && ($NU eq "true")){
	$TOTAL_A = $P_U_A[0] + $P_NU_A[0];
	$SUM_U_A = &format_large_int($P_U_A[0]);
	$SUM_NU_A = &format_large_int($P_NU_A[0]);
    }
    else{
	if ($U eq "true"){
	    $TOTAL_A = $P_U_A[0];
	    $SUM_U_A = &format_large_int($P_U_A[0]);
	}
	if ($NU eq "true"){
	    $TOTAL_A = $P_NU_A[0];
	    $SUM_NU_A = &format_large_int($P_NU_A[0]);
	}
    }
}

open(OUT, ">$outfile");
$TOTAL = &format_large_int($TOTAL);
if ($stranded eq "true"){
    $TOTAL_A = &format_large_int($TOTAL_A);
}
print OUT "\n[GENE NORMALIZATION]\n";
print OUT "\nExpected number of reads after normalization (estimate): ";
if (($U eq "true") && ($NU eq "true")){
    if ($stranded eq "false"){
	print OUT "$TOTAL total reads\n";
	print OUT "\t\t\t\t\t\t\t $SUM_U unique\n";
	print OUT "\t\t\t\t\t\t\t $SUM_NU non-unique\n";
    }
    if ($stranded eq "true"){
	print OUT "$TOTAL sense reads\t$TOTAL_A antisense reads\n";
        print OUT "\t\t\t\t\t\t\t $SUM_U sense unique\t$SUM_U_A antisense unique\n";
        print OUT "\t\t\t\t\t\t\t $SUM_NU sense non-unique\t$SUM_NU_A antisense non-unique\n";
    }
}
else{
    if ($U eq "true"){
	if ($stranded eq "false"){
	    print OUT "$TOTAL unique reads\n";
	}
	if ($stranded eq "true"){
	    print OUT "$TOTAL sense unique\t$TOTAL_A antisense unique\n";
	}
    }
    if ($NU eq "true"){
	if ($stranded eq "false"){
            print OUT "$TOTAL non-unique reads\n";
	}
	if ($stranded eq "true"){
	    print OUT "$TOTAL sense non-unique\t$TOTAL_A antisense non-unique\n";
        }
    }
}

print OUT "\n[1] You may remove sample ids from <sample_dirs> file to get more reads:\n\n<Expected number of reads after removing samples>\n";

my $num_to_remove;
if ($numargs_u_nu eq '0'){
    if ($stranded eq "true"){
	print OUT "#ids-to-rm\tsenseUnique\tsenseNU\tsenseTOTAL\tantisenseUnique\tantisenseNU\tantisenseTOTAL\tSampleIDs-to-rm\n";
    }
    if ($stranded eq "false"){
	print OUT "#ids-to-rm\tUnique\tNU\tTOTAL\tSampleIDs-to-rm\n";
    }
    $num_to_remove = @P_U;
}
else{
    if ($U eq "true"){
	if ($stranded eq "true"){
            print OUT "#ids-to-rm\tsenseUnique\tantisenseUnique\tSampleIDs-to-rm\n";
	}
	if ($stranded eq "false"){
	    print OUT "#ids-to-rm\tUnique\tSampleIDs-to-rm\n";
	}
	$num_to_remove = @P_U;
    }
    else{
	if ($stranded eq "true"){
            print OUT "#ids-to-rm\tsenseNU\tantisenseNU\tSampleIDs-to-rm\n";
	}
	if ($stranded eq "false"){
	    print OUT "#ids-to-rm\tNU\tSampleID\n";
	}
	$num_to_remove = @P_NU;
    }
}
my $ids = "";
for(my $i=0; $i<$num_to_remove;$i++){
    if ($numargs_u_nu eq '0'){
	if ($stranded eq "false"){
	    my $P_TOTAL = $P_U[$i]+$P_NU[$i];
	    $P_TOTAL = &format_large_int($P_TOTAL);
	    my $P_U_F = &format_large_int($P_U[$i]);
	    my $P_NU_F = &format_large_int($P_NU[$i]);
	    print OUT "$i\t$P_U_F\t$P_NU_F\t$P_TOTAL\t";
	    $ids .= ",$ID[$i],";
	    $ids =~ s/,$//;
	    $ids =~ s/^,//;
	    print OUT "$ids\n";
	}
	if ($stranded eq "true"){
	    my $P_TOTAL = $P_U[$i]+$P_NU[$i];
            $P_TOTAL = &format_large_int($P_TOTAL);
	    my $P_U_F = &format_large_int($P_U[$i]);
            my $P_NU_F = &format_large_int($P_NU[$i]);
	    my $P_TOTAL_A = $P_U_A[$i]+$P_NU_A[$i];
	    $P_TOTAL_A = &format_large_int($P_TOTAL_A);
	    my $P_U_F_A = &format_large_int($P_U_A[$i]);
            my $P_NU_F_A = &format_large_int($P_NU_A[$i]);
            print OUT "$i\t$P_U_F\t$P_NU_F\t$P_TOTAL\t$P_U_F_A\t$P_NU_F_A\t$P_TOTAL_A\t";
	    $ids .= ",$ID[$i],";
	    $ids =~ s/,$//;
	    $ids =~ s/^,//;
	    print OUT "$ids\n";
	}
    }
    else{
	if ($U eq "true"){
	    if ($stranded eq "false"){
		my $P_U_F = &format_large_int($P_U[$i]);
		print OUT "$i\t$P_U_F\t";
		$ids .= ",$ID[$i],";
		$ids =~ s/,$//;
		$ids =~ s/^,//;
		print OUT "$ids\n";
	    }
	    if ($stranded eq "true"){
                my $P_U_F = &format_large_int($P_U[$i]);
                my $P_U_F_A = &format_large_int($P_U_A[$i]);
                print OUT "$i\t$P_U_F\t$P_U_F_A\t";
		$ids .= ",$ID[$i],";
		$ids =~ s/,$//;
		$ids =~ s/^,//;
		print OUT "$ids\n";
	    }
	}
	if ($NU eq "true"){
	    if ($stranded eq "false"){
		my $P_NU_F = &format_large_int($P_NU[$i]);
		print OUT "$i\t$P_NU_F\t";
		$ids .= ",$ID[$i],";
		$ids =~ s/,$//;
		$ids =~ s/^,//;
		print OUT "$ids\n";
	    }
	    if ($stranded eq "true"){
		my $P_NU_F = &format_large_int($P_NU[$i]);
		my $P_NU_F_A = &format_large_int($P_NU_A[$i]);
                print OUT "$i\t$P_NU_F\t$P_NU_F_A\t";
		$ids .= ",$ID[$i],";
		$ids =~ s/,$//;
		$ids =~ s/^,//;
		print OUT "$ids\n";
	    }
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



