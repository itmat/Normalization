#!/usr/bin/env perl
if(@ARGV<3) {
    die "usage: perl quants2spreadsheet_min_max.pl <sample dirs> <loc> <type of quants file>

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories.
<type of quants file> is the type of quants file. e.g: exonquants, intronquants

";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
$type = $ARGV[2];
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";
$spread_dir = $norm_dir . "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir $spread_dir`;
}

if ($type =~ /^exon/){
    $out_MIN = "$spread_dir/master_list_of_exons_counts_MIN.txt";
    $out_MAX = "$spread_dir/master_list_of_exons_counts_MAX.txt";
    $sample_name_file = "$norm_dir/file_exonquants_minmax.txt";
}
else{
    if ($type =~ /^intron/){
	$out_MIN = "$spread_dir/master_list_of_introns_counts_MIN.txt";
	$out_MAX = "$spread_dir/master_list_of_introns_counts_MAX.txt";
	$sample_name_file = "$norm_dir/file_intronquants_minmax.txt";
	$merged_dir = $nexon_dir . "/MERGED";
	unless (-d $merged_dir){
	    `mkdir $merged_dir`;
	}
    }
    else{
	die "ERROR:Please check the type of quants file. It has to be either \"exonquants\" or \"intronquants\".\n\n";
    }
}

if ($type =~ /^exon/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
	chomp($line);
	$id = $line;
	$id =~ s/Sample_//;
	print OUT "$exon_dir/MERGED/$id.exonmappers.norm_exonquants\n";
    }
}
close(INFILE);
close(OUT);

if ($type =~ /^intron/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    while($line = <INFILE>){
	chomp($line);
	$id = $line;
	$id =~ s/Sample_//;	
	$Unique = "$nexon_dir/Unique/$id.intronmappers.norm_u_intronquants";
	$NU = "$nexon_dir/NU/$id.intronmappers.norm_nu_intronquants";
	$Unique_no_header = $Unique . "_no_header";
	$NU_no_header = $NU . "_no_header";
	$NEW_quants = "$merged_dir/$id.intronquants_merged";

	open(FILE1, "<$Unique") or die "cannot find file '$Unique'\n";
	@lines = <FILE1>;
	close(FILE1);

	open(FILE1_new, ">$Unique_no_header");
	foreach $line (@lines){
	    print FILE1_new $line unless ($line !~ /([^:\t\s]+):(\d+)-(\d+)/);
	}
	close(FILE1_new);

	open(FILE2, "<$NU") or die "cannot find file '$NU'\n";
	@lines2 = <FILE2>;
	close(FILE2);

	open(FILE2_new, ">$NU_no_header");
	foreach $line2 (@lines2){
	    print FILE2_new $line2 unless ($line2 !~ /([^:\t\s]+):(\d+)-(\d+)/);
	}
	close(FILE2_new);
    
	open(File1, $Unique_no_header);
	open(File2, $NU_no_header);
	open(OUT, ">$NEW_quants");
	print OUT "feature\t\min\tmax\n";
	while (!eof File1 and !eof File2){
	    $line_U = <File1>;
	    $line_NU = <File2>;
	    chomp($line_U);
	    chomp($line_NU);

	    @a1 = split(/\t/, $line_U);
	    $feature1 = $a1[0];
	    $min = $a1[1];

	    @a2 = split(/\t/, $line_NU);
	    $feature2 = $a2[0];
	    $nu_cnt = $a2[1];

	    $max = $min + $nu_cnt;

	    if ($feature1 eq $feature2){
		$feature_min_max = "$feature1\t$min\t$max\n";
	    }
	    else{
		$feature_min_max = "not equal!!!!";
	    }
	    print OUT $feature_min_max;
	}
	close(OUT);
	close(File1);
	close(File2);
    }
    close(INFILE);
#    `rm $nexon_dir/Unique/*no_header $nexon_dir/NU/*no_header`;
    open(INFILE, $ARGV[0]);
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
	chomp($line);
	$id = $line;
	$id =~ s/Sample_//;
	print OUT "$merged_dir/$id.intronquants_merged\n";
    }
}
close(INFILE);
close(OUT);
	
open(FILES, $sample_name_file);
chomp($file);
$file = <FILES>;
close(FILES);

open(INFILE, $file);
$firstline = <INFILE>;
$rowcnt = 0;
while($line = <INFILE>) {
    chomp($line);
    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	next;
    }
    @a = split(/\t/,$line);
    $id[$rowcnt] = $a[0];
    $rowcnt++;
}
close(INFILE);

open(FILES, $sample_name_file);
$filecnt = 0;
while($file = <FILES>) {
    chomp($file);
    @fields = split("/",$file);
    $size = @fields;
    $id = $fields[$size-1];
    $id =~ s/.exonmappers.norm_exonquants//;
    $id =~ s/.intronquants_merged//;
    $id =~ s/Sample_//; 
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    $firstline = <INFILE>;
    $rowcnt = 0;
    while($line = <INFILE>) {
	chomp($line);
	@a = split(/\t/,$line);
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
	$DATA_MIN[$filecnt][$rowcnt] = $a[1];
	$DATA_MAX[$filecnt][$rowcnt] = $a[2];
	$rowcnt++;
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);

open(OUT_MIN, ">$out_MIN");
open(OUT_MAX, ">$out_MAX");
print OUT_MIN "id";
print OUT_MAX "id";

for($i=0; $i<@ID; $i++) {
    print OUT_MIN "\t$ID[$i]";
    print OUT_MAX "\t$ID[$i]";
}
print OUT_MIN "\n";
print OUT_MAX "\n";

for($i=0; $i<$rowcnt; $i++) {
    if ($type =~ /^exon/){
	print OUT_MIN "exon:$id[$i]";
	print OUT_MAX "exon:$id[$i]";
    }
    if ($type =~ /^intron/){
	print OUT_MIN "intron:$id[$i]";
	print OUT_MAX "intron:$id[$i]";
    }
    for($j=0; $j<$filecnt; $j++) {
	print OUT_MIN "\t$DATA_MIN[$j][$i]";
	print OUT_MAX "\t$DATA_MAX[$j][$i]";
    }
    print OUT_MIN "\n";
    print OUT_MAX "\n";
}
close(OUT_MIN);
close(OUT_MAX);


