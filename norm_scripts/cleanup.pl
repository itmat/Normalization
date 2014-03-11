if(@ARGV<2) {
    die "Usage: perl cleanup.pl <sample dirs> <loc> 

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$size = @fields;
$last_dir = $fields[@size-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$norm_dir = $study_dir . "NORMALIZED_DATA";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";

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
}
