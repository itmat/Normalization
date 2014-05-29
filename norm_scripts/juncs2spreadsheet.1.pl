#!/usr/bin/env perl
if(@ARGV<2) {
    die "usage: perl juncs2spreadsheet.1.pl <sample dirs> <loc> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories

option:
-NU: set this if you want to use non-unique junctions, otherwise by default it will
     use unique junctions files as input
";
}
$nuonly = 'false';
for($i=2; $i<@ARGV; $i++) {
    $arg_recognized = 'false';
    if($ARGV[$i] eq '-NU') {
	$nuonly = 'true';
	$arg_recognized = 'true';
    }
    if($arg_recognized eq 'false') {
	die "arg \"$ARGV[$i]\" not recognized.\n";
    }
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
$spread_dir = $norm_dir . "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir $spread_dir`;
}
$outfile = "$spread_dir/master_list_of_junctions_counts_u.$study.txt";
$sample_name_file = "$norm_dir/file_junctions_u.txt";
if ($nuonly eq "true"){
    $outfile =~ s/_u.$study.txt/_nu.$study.txt/;
    $sample_name_file =~ s/_u.txt/_nu.txt/;
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
open(OUT, ">$sample_name_file");
while($line = <INFILE>){
    chomp($line);
    $id = $line;
    if($nuonly eq "true"){
	print OUT "$junc_dir/$id.FINAL.norm_nu_junctions_all.rum\n";
    }
    if ($nuonly eq "false"){
	print OUT "$junc_dir/$id.FINAL.norm_u_junctions_all.rum\n";
    }
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
    $id =~ s/.FINAL.norm_u_junctions_all.rum//;
    $id =~ s/.FINAL.norm_u_junctions_all.rum//;
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    while($line = <INFILE>){
	chomp($line);
	@a = split(/\t/,$line);
	if ($a[2]==0){
	    next;
	}
	$HASH_MIN{$a[0]}[$filecnt] = $a[7];
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);

open(OUT_MIN, ">$outfile");
print OUT_MIN "loc";

for($i=0; $i<@ID; $i++) {
    print OUT_MIN "\t$ID[$i]";
}
print OUT_MIN "\n";

foreach $loc (keys %HASH_MIN) {
    print OUT_MIN "junction:$loc";
    for($i=0; $i<@ID; $i++) {
	$val = $HASH_MIN{$loc}[$i] + 0;
	print OUT_MIN "\t$val";
	}
	print OUT_MIN "\n";
}
close(OUT_MIN);


print "got here\n";
