if(@ARGV<3) {
    die "usage: perl quants2spreadsheet.1.pl <file names> <loc> <type of quants file> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories.
<type of quants file> is the type of quants file. e.g: exonquants, intronquants

option:
 -NU: set this if you want to use non-unique quants, otherwise by default it will 
      use unique quants files as input
";
}

$nuonly = 'false';
for($i=3; $i<@ARGV; $i++) {
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
$size = @fields;
$last_dir = $fields[@size-1];
$norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";

if ($type =~ /^exon/){
    $out = "$norm_dir/list_of_exons_counts_u.txt";
    $sample_name_file = "$norm_dir/file_exonquants_u.txt";
    if ($nuonly eq "true"){
	$out =~ s/_u.txt/_nu.txt/;
	$sample_name_file = s/_u.txt/_nu.txt/;
    }
}
else{
    if ($type =~ /^intron/){
        $out = "$norm_dir/master_list_of_introns_counts_u.txt";
        $sample_name_file = "$norm_dir/file_intronquants_u.txt";
	if ($nuonly eq "true"){
	    $out =~ s/_u.txt/_nu.txt/;
	    $sample_name_file = s/_u.txt/_nu.txt/;
	}
    }
    else{
        die "ERROR:Please check the type of quants file. It has to be either \"exonquants\" or \"in\
tronquants\".\n\n";
    }
}

if($type =~ /^exon/){
    open(INFILE, $ARGV[0]);
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
	chomp($line);
	$id = $line;
	$id =~ s/Sample_//;
	if($nuonly eq "false"){
	    print OUT "$exon_dir/Unique/$id.exonmappers.norm_u.exonquants\n";
	}
	if($nuonly eq "true"){
            print OUT "$exon_dir/NU/$id.exonmappers.norm_nu.exonquants\n";
	}
    }
}
if ($type =~ /^intron/){
    open(INFILE, $ARGV[0]);
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
	chomp($line);
	$id = $line;
	$id =~ s/Sample_//;
	if($nuonly eq "false"){
            print OUT "$nexon_dir/Unique/$id.intronmappers.norm_u.intronquants\n";
	}
	if($nuonly eq "true"){
	    print OUT "$nexon_dir/NU/$id.intronmappers.norm_nu.intronquants\n";
	}
    }
}
close(INFILE);
close(OUT);

open(FILES, $sample_name_file);
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
    $id =~ s/.exonmappers.norm_u.exonquants//;
    $id =~ s/.exonmappers.norm_nu.exonquants//;
    $id =~ s/.intronmappers.norm_u.intronquants//;
    $id =~ s/.intronmappers.norm_nu.intronquants//;
    $id =~ s/Sample_//;
    $ID[$filecnt] = $1;
    open(INFILE, $file_wp);
    $firstline = <INFILE>;
    $rowcnt = 0;
    while($line = <INFILE>) {
	chomp($line);
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
	@a = split(/\t/,$line);
	$DATA[$filecnt][$rowcnt] = $a[1];
	$rowcnt++;
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);

open(OUTFILE, ">$out");
print OUTFILE "id";
for($i=0; $i<@ID; $i++) {
    print OUTFILE "\t$ID[$i]";
}
print OUTFILE "\n";
for($i=0; $i<$rowcnt; $i++) {
    if ($type =~ /^exon/){
	print OUTFILE "$id[$i]";
    }
    if ($type =~ /^intron/){
	print OUTFILE "intron:$id[$i]";
    }
    for($j=0; $j<$filecnt; $j++) {
	print OUTFILE "\t$DATA[$j][$i]";
    }
    print OUTFILE "\n";
}
close(OUTFILE);
