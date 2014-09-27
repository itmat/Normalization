#!/usr/bin/env perl
if(@ARGV<2) {
    die "Usage: perl cleanup.pl <sample dirs> <loc> 

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$norm_dir = $study_dir . "NORMALIZED_DATA/EXON_INTRON_JUNCTION/";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";
$spread_dir = $norm_dir . "/SPREADSHEETS";
$gnorm_dir = $study_dir . "NORMALIZED_DATA/GENE/";
$gspread_dir = $gnorm_dir . "/SPREADSHEETS";

if (-d $exon_dir){
    `rm -r $exon_dir`;
}
if (-d $nexon_dir){
    `rm -r $nexon_dir`;
}
if (-d "$norm_dir/FINAL_SAM/MERGED"){
    if (-d "$norm_dir/FINAL_SAM/Unique"){
	`rm -r $norm_dir/FINAL_SAM/Unique`;
    }
    if (-d "$norm_dir/FINAL_SAM/NU"){
	`rm -r $norm_dir/FINAL_SAM/NU`;
    }
}
if (-d "$gnorm_dir/FINAL_SAM/MERGED"){
    if (-d "$gnorm_dir/FINAL_SAM/Unique"){
        `rm -r $gnorm_dir/FINAL_SAM/Unique`;
    }
    if (-d "$gnorm_dir/FINAL_SAM/NU"){
        `rm -r $gnorm_dir/FINAL_SAM/NU`;
    }
}
if (-d $spread_dir){
    if (-e "$norm_dir/file_exonquants_minmax.txt"){
	`rm $norm_dir/*txt`;
    }
    if (-e "$norm_dir/file_exonquants.1.txt"){
	`rm $norm_dir/*txt`;
    }
}
if (-e "$gspread_dir/file_genequants_minmax.GNORM.txt"){
    `rm $gspread_dir/file_genequants_minmax.GNORM.txt`;
}

open(INFILE, $ARGV[0]) or die "cannot find file $ARGV[0]\n";
while($line = <INFILE>){
    chomp($line);
    #remove filtered sam / head files
    if (-d "$LOC/$line/EIJ/Unique"){
	`rm -r $LOC/$line/EIJ/Unique`;
    }
    if (-d "$LOC/$line/EIJ/NU"){
	`rm -r $LOC/$line/EIJ/NU`;
    }
    if (-d "$LOC/$line/EIJ"){
	`rm -r $LOC/$line/EIJ`;
    }
    if (-d "$LOC/$line/GNORM/Unique"){
        `rm -r $LOC/$line/GNORM/Unique`;
    }
    if (-d "$LOC/$line/GNORM/NU"){
        `rm -r $LOC/$line/GNORM/NU`;
    }
    if (-d "$LOC/$line/GNORM"){
	`rm -r $LOC/$line/GNORM`;
    }
    if (-e "$LOC/$line/blast.out.1"){
	`rm $LOC/$line/blast.out.*`;
	`rm $LOC/$line/temp.1`;
    }
    if (-e "$LOC/$line/Aligned.out_junctions_all.sorted.rum"){
	`rm $LOC/$line/*junctions_*`;
    }
    if (-e "$LOC/$line/RUM_junctions_all.sorted.rum"){
	`rm $LOC/$line/*junctions_*`;
    }

}
print "got here\n";
