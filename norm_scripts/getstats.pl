if(@ARGV<2) {
    die "usage: perl getstats.pl <dirs> <loc>

where 
<dirs> is a file of directory names (without path)
<loc> is where the sample directories are

This will parse the mapping_stats.txt files for all dirs
and output a table with summary info across all samples.
";
}

$dirs = $ARGV[0];
$LOC = $ARGV[1];
$cwd = `pwd`;
open(DIRS, $dirs) or die "cannot find file '$dirs'\n";
while($dir = <DIRS>) {
    chomp($dir);
    $id = $dir;
    $id =~ s/Sample_//;
    $filename = "$LOC/$dir/$id.mappingstats.txt";
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
    $NUTOTAL_F_or_R = $1;
    $NUTOTAL_F_or_R =~ s/,//g;
    $NUandAtLeastOneMapped{$dir} = $x;
    $min_nutotal = $NUTOTAL_F_or_R;
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
    $y = int($x / $UTOTAL_F_or_R_CONS * 1000) / 10;
    $min_chrm = $x;
    $x2 = &format_large_int($x);
    $UchrM{$dir} = "$x2 ($y%)";
}

$max1 = 0;
$max2 = 0;
$max3 = 0;
$max4 = 0;
$max5 = 0;
$max6 = 0;

$outfile = "$LOC/mappingstats_summary.txt";
open(OUT, ">$outfile");
#print OUT "id\ttotal\t!<>\t!<|>\t!chrM(%!)\t\%overlap\t~!<|>\t<|>\n";
print OUT "id\ttotalreads\tUniqueFWDandREV\tUniqueFWDorREV\tUniqueChrM\tNon-UniqueFWDorREV\tFWDorREVmapped\n";
foreach $dir (keys %UchrM) {
    print OUT "$dir\t$total{$dir}\t$uniqueandFRconsistently{$dir}\t$uniqueandAtLeastOneMapped{$dir}\t$UchrM{$dir}\t$NUandAtLeastOneMapped{$dir}\t$TotalMapped{$dir}\n";
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

    $x = $NUandAtLeastOneMapped{$dir};
    $x =~ s/ \(.*//;
    $x =~ s/,//g;
    if($x < $min_nutotal) {
	$min_nutotal = $x;
    }
    if($x > $max_nutotal) {
	$max_nutotal = $x;
    }


}
$min_total = &format_large_int($min_total);
$min_total_frcons = &format_large_int($min_total_frcons);
$min_utotal_f_or_r_cons = &format_large_int($min_utotal_f_or_r_cons);
$min_nutotal = &format_large_int($min_nutotal);
$min_total_UorNU = &format_large_int($min_total_UorNU);
$min_chrm = &format_large_int($min_chrm);
print OUT "mins\t$min_total\t$min_total_frcons\t$min_utotal_f_or_r_cons\t$min_chrm\t$min_pover\%\t$min_nutotal\t$min_total_UorNU\n";
$max_total = &format_large_int($max_total);
$max_total_frcons = &format_large_int($max_total_frcons);
$max_utotal_f_or_r_cons = &format_large_int($max_utotal_f_or_r_cons);
$max_nutotal = &format_large_int($max_nutotal);
$max_total_UorNU = &format_large_int($max_total_UorNU);
$max_chrm = &format_large_int($max_chrm);
print OUT "maxs\t$max_total\t$max_total_frcons\t$max_utotal_f_or_r_cons\t$max_chrm\t$max_pover\%\t$max_nutotal\t$max_total_UorNU\n";

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


