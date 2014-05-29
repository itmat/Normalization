#!/usr/bin/env perl
if(@ARGV<2) {
    die "usage: perl juncs2spreadsheet_min_max.pl <sample dirs> <loc>

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories

";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
$type = $ARGV[2];
@fields = split("/", $LOC);
$study = $fields[@fields-2];
$last_dir = $fields[@fields-1];
$norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA";
$junc_dir = $norm_dir . "/JUNCTIONS";
$spread_dir = $norm_dir. "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir $spread_dir`;
}

$outfile = "$spread_dir/master_list_of_junctions_counts";
$out_MIN = $outfile . "_MIN.$study.txt";
$out_MAX = $outfile . "_MAX.$study.txt";
$sample_name_file = "$norm_dir/file_junctions_minmax.txt";

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
open(OUT, ">$sample_name_file");
while($line = <INFILE>){
    chomp($line);
    $id = $line;
    print OUT "$junc_dir/$id.FINAL.norm_junctions_all.rum\n";
}
close(INFILE);
close(OUT);

open(FILES, $sample_name_file);
$filecnt = 0;
while ($file = <FILES>){
    chomp($file);
    @fields = split("/",$file);
    $size = @fields;
    $id = $fields[$size-1];
    $id =~ s/.FINAL.norm_junctions_all.rum//;
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    while($line = <INFILE>){
	chomp($line);
	@a = split(/\t/,$line);
	if ($a[2]==0){
	    next;
	}
	$HASH_MIN{$a[0]}[$filecnt] = $a[7];
	$HASH_MAX{$a[0]}[$filecnt] = $a[7]+$a[9];
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);

open(OUT_MIN, ">$out_MIN");
open(OUT_MAX, ">$out_MAX");
print OUT_MIN "loc";
print OUT_MAX "loc";

for($i=0; $i<@ID; $i++) {
    print OUT_MIN "\t$ID[$i]";
    print OUT_MAX "\t$ID[$i]";
}
print OUT_MIN "\n";
print OUT_MAX "\n";

foreach $loc (keys %HASH_MIN) {
    print OUT_MIN "junction:$loc";
    for($i=0; $i<@ID; $i++) {
	$val = $HASH_MIN{$loc}[$i] + 0;
	print OUT_MIN "\t$val";
	}
	print OUT_MIN "\n";
}
close(OUT_MIN);

foreach $loc (keys %HASH_MAX) {
    print OUT_MAX "junction:$loc";
    for($i=0; $i<@ID; $i++) {
        $val = $HASH_MAX{$loc}[$i] + 0;
        print OUT_MAX "\t$val";
    }
    print OUT_MAX "\n";
}
close(OUT_MAX);


print "got here\n";
