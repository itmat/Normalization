#!/usr/bin/env perl

$USAGE = "\nUsage: perl getstats.pl <dirs> <loc> [option]

where 
<dirs> is a file of directory names (without path)
<loc> is where the sample directories are

option:
 -u : set this if you want to generate summary table for normalized sam files (Unique)
 -nu : set this if you want to generate summary table for normalized sam files (NU)

This will parse the mapping_stats.txt files for all dirs
and output a table with summary info across all samples.
";
if(@ARGV<2) {
    die $USAGE;
}

$u = "false";
$nu = "false";
$numargs = 0;
for ($i=2; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-u'){
        $option_found = "true";
        $u = "true";
	$numargs++;
    }
    if ($ARGV[$i] eq '-nu'){
        $option_found = "true";
        $nu = "true";
	$numargs++;
    }
}
if ($numargs > 1){
    die "you cannot set both \"-u\" and \"-nu\"\n";
}

$dirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$stats_dir = $study_dir . "STATS/GENE/";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}

$cwd = `pwd`;
open(DIRS, $dirs) or die "cannot find file '$dirs'\n";
while($dir = <DIRS>) {
    chomp($dir);
    $id = $dir;
    if ($numargs eq "0"){
	$filename = "$study_dir/NORMALIZED_DATA/GENE/FINAL_SAM/MERGED/$id.GNORM.mappingstats.txt";
    }
    elsif ($u eq "true"){
	$filename = "$study_dir/NORMALIZED_DATA/GENE/FINAL_SAM/Unique/$id.GNORM.Unique.mappingstats.txt";
    }
    elsif ($nu eq "true"){
	$filename = "$study_dir/NORMALIZED_DATA/GENE/FINAL_SAM/NU/$id.GNORM.NU.mappingstats.txt";
    }
    if(!(-e "$filename")) {
	next;
    }
    $x = `head -1 $filename`;
    chomp($x);
    $x =~ s/[^\d,]//g;
    $total{$dir} = $x;
    $TOTAL = $x;
    $TOTAL =~ s/,//g;
    $min_total = $TOTAL;

    $x = `grep "Both forward and reverse mapped consistently" $filename`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    $TOTAL_FRCONS = $1;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $uniqueandFRconsistently{$dir} = "$y ($x)";
    $min_total_frcons = $TOTAL_FRCONS;

    $x = `grep "At least one of forward or reverse mapped" $filename | head -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    $UTOTAL_F_or_R_CONS = $1;
    $UTOTAL_F_or_R_CONS =~ s/,//g;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $uniqueandAtLeastOneMapped{$dir} = "$y ($x)";
    $min_utotal_f_or_r_cons = $UTOTAL_F_or_R_CONS;
    $min_utotal_f_or_r_cons =~ s/,//g;

    $x = `grep "At least one of forward or reverse mapped" $filename | head -2 | tail -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    $NUTOTAL_F_or_R = $1;
    $NUTOTAL_F_or_R =~ s/,//g;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $NUandAtLeastOneMapped{$dir} = "$y ($x)";
    $min_nutotal_f_or_r = $NUTOTAL_F_or_R;
    $min_nutotal_f_or_r =~ s/,//g;

    $x = `grep "At least one of forward or reverse mapped" $filename | tail -1`;
    chomp($x);
    $x =~ /([\d,]+)/;
    $y = $1;
    $x =~ s/[^\d.%)(]//g;
    $x =~ s/^(\d+)//;
    $TOTALMAPPED = $1;
    $x =~ s/\(//;
    $x =~ s/\)//;
    $TotalMapped{$dir} = "$y ($x)";
    $min_total_UorNU = $TOTALMAPPED;
    $min_total_UorNU =~ s/,//g;

    $x = `grep "Total number consistent ambiguous" $filename`;
    chomp($x);
    $x =~ s/^.*: //;
    $x =~ /^(.*) /;
    $NUTOTAL_F_and_R = $1;
    $NUTOTAL_F_and_R =~ s/,//g;
    $NUandFRconsistently{$dir} = $x;
    $min_nutotal = $NUTOTAL_F_and_R;
    $min_nutotal =~ s/,//g;

    $x = `grep "do overlap" $filename | head -1`;
    chomp($x);
    $x =~ s/[^\d,]//g;
    $overlap = $x;
    $overlap =~ s/,//;
    $Overlap{$dir} = "$x";

    $x = `grep "don.t overlap" $filename | head -1`;
    chomp($x);
    $x =~ s/[^\d,]//g;
    $noverlap = $x;
    $noverlap =~ s/,//;
    $NOverlap{$dir} = "$x";

    if($overlap + $noverlap > 0) {
	$Pover{$dir} = int($overlap / ($overlap+$noverlap) * 1000) / 10;
    } else {
	$Pover{$dir} = 0;
    }
    $min_pover = $Pover{$dir};
    $min_pover =~ s/,//g;


    $x = `grep chrM $filename | head -1`;
    chomp($x);
    if($x eq '') {
	$x = `grep MT $filename | head -1`;
	chomp($x);
    }
    @a1 = split(/\t/,$x);
    $a1[1] =~ s/[^\d]//g;
    $x = $a1[1];
    if ($x eq ''){
	$x = '0';
    }
    unless($norm_nu eq "true"){
	$y = int($x / $UTOTAL_F_or_R_CONS * 1000) / 10;
    }
    $min_chrm = $x;
    $x2 = &format_large_int($x);
    if ($x2 eq ''){
	$x2 = '0';
    }
    $UchrM{$dir} = "$x2 ($y%)";
}

$max1 = 0;
$max2 = 0;
$max3 = 0;
$max4 = 0;
$max5 = 0;
$max6 = 0;

if ($numargs eq "0"){
    $outfile = "$stats_dir/num_reads_after_normalization_gnorm.txt";
}
elsif ($u eq "true"){
    $outfile = "$stats_dir/num_reads_after_normalization_gnorm_u.txt";
}
elsif ($nu eq "true"){
    $outfile = "$stats_dir/num_reads_after_normalization_gnorm_nu.txt";
}
open(OUT, ">$outfile");
#print OUT "id\ttotal\t!<>\t!<|>\t!chrM(%!)\t\%overlap\t~!<>\t~!<|>\t<|>\n";
if ($numargs eq "0"){
    print OUT "id\ttotalreads\tUnique\tNon-Unique\n";
}
elsif ($u eq "true"){
    print OUT "id\ttotalreads\tUnique\n";
}
elsif ($nu eq "true"){
    print OUT "id\ttotalreads\tNon-Unique\n";
}
foreach $dir (keys %UchrM) {
    if ($numargs eq "0"){
	print OUT "$dir\t$total{$dir}\t$uniqueandAtLeastOneMapped{$dir}\t$NUandAtLeastOneMapped{$dir}\n";
    }
    elsif ($u eq "true"){
	print OUT "$dir\t$total{$dir}\t$uniqueandAtLeastOneMapped{$dir}\n";
    }
    elsif ($nu eq "true"){
	print OUT "$dir\t$total{$dir}\t$NUandAtLeastOneMapped{$dir}\n";
    }
    $x = $total{$dir};
    $x =~ s/,//g;
    if($x < $min_total) {
	$min_total = $x;
    }
    if($x > $max_total) {
	$max_total = $x;
    }

    $x = $uniqueandFRconsistently{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_total_frcons) {
	$min_total_frcons = $x;
    }
    if($x > $max_total_frcons) {
	$max_total_frcons = $x;
    }

    $x = $TotalMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_total_UorNU) {
	$min_total_UorNU = $x;
    }
    if($x > $max_total_UorNU) {
	$max_total_UorNU = $x;
    }

    $x = $uniqueandAtLeastOneMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_utotal_f_or_r_cons) {
	$min_utotal_f_or_r_cons = $x;
    }
    if($x > $max_utotal_f_or_r_cons) {
	$max_utotal_f_or_r_cons = $x;
    }

    $x = $UchrM{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_chrm) {
	$min_chrm = $x;
    }
    if($x > $max_chrm) {
	$max_chrm = $x;
    }

    $x = $Pover{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_pover) {
	$min_pover = $x;
    }
    if($x > $max_pover) {
	$max_pover = $x;
    }

    $x = $NUandFRconsistently{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_nutotal) {
	$min_nutotal = $x;
    }
    if($x > $max_nutotal) {
	$max_nutotal = $x;
    }

    $x = $NUandAtLeastOneMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
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
$min_nutotal_f_or_r = &format_large_int($min_nutotal_f_or_r);
$min_chrm = &format_large_int($min_chrm);
if ($numargs eq "0"){
    print OUT "mins\t$min_total\t$min_utotal_f_or_r_cons\t$min_nutotal_f_or_r\n";
}
elsif ($u eq "true"){
    print OUT "mins\t$min_total\t$min_utotal_f_or_r_cons\n";
}
elsif ($nu eq "true"){
    print OUT "mins\t$min_total\t$min_nutotal_f_or_r\n";
}

$max_total = &format_large_int($max_total);
$max_total_frcons = &format_large_int($max_total_frcons);
$max_utotal_f_or_r_cons = &format_large_int($max_utotal_f_or_r_cons);
$max_nutotal = &format_large_int($max_nutotal);
$max_nutotal_f_or_r = &format_large_int($max_nutotal_f_or_r);
$max_total_UorNU = &format_large_int($max_total_UorNU);
$max_chrm = &format_large_int($max_chrm);
if ($numargs eq "0"){
    print OUT "maxs\t$max_total\t$max_utotal_f_or_r_cons\t$max_nutotal_f_or_r\n";
}
elsif ($u eq "true"){
    print OUT "maxs\t$max_total\t$max_utotal_f_or_r_cons\n";
}
elsif ($nu eq "true"){
    print OUT "maxs\t$max_total\t$max_nutotal_f_or_r\n";
}

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


print "got here\n";
