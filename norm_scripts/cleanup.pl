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
$norm_dir = $study_dir . "NORMALIZED_DATA";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";
$spread_dir = $norm_dir . "/SPREADSHEETS";
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
if (-d $spread_dir){
    if (-e "$norm_dir/file_exonquants_minmax.txt"){
	`rm $norm_dir/*txt`;
    }
    if (-e "$norm_dir/file_exonquants.1.txt"){
	`rm $norm_dir/*txt`;
    }
}
open(INFILE, $ARGV[0]) or die "cannot find file $ARGV[0]\n";
while($line = <INFILE>){
    chomp($line);
    #remove filtered sam / head files
    if (-d "$LOC/$line/Unique"){
	`rm -r $LOC/$line/Unique`;
    }
    if (-d "$LOC/$line/NU"){
	`rm -r $LOC/$line/NU`;
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
