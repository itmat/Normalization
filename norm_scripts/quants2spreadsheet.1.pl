#!/usr/bin/env perl
if(@ARGV<3) {
    die "usage: perl quants2spreadsheet.1.pl <file names> <loc> <type of quants file> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories
<type of quants file> is the type of quants file (e.g: exonquants, intronquants, genequants)

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
$study = $fields[@fields-2];
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
    $out = "$spread_dir/master_list_of_exons_counts_u.$study.txt";
    $sample_name_file = "$norm_dir/file_exonquants_u.txt";
    if ($nuonly eq "true"){
	$out =~ s/_u.$study.txt/_nu.$study.txt/;
	$sample_name_file =~ s/_u.txt/_nu.txt/;
    }
}
elsif ($type =~ /^gene/){
    $out_min = "$spread_dir/master_list_of_genes_counts_u.MIN.$study.txt";
    $out_max = "$spread_dir/master_list_of_genes_counts_u.MAX.$study.txt";
    $sample_name_file = "$norm_dir/file_genequants_u.txt";
    if ($nuonly eq "true"){
        $out_min =~ s/_u.MIN/_nu.MIN/;
        $out_max =~ s/_u.MAX/_nu.MAX/;
        $sample_name_file =~ s/_u.txt/_nu.txt/;
    }
}
elsif ($type =~ /^intron/){
    $out = "$spread_dir/master_list_of_introns_counts_u.$study.txt";
    $sample_name_file = "$norm_dir/file_intronquants_u.txt";
    if ($nuonly eq "true"){
	$out =~ s/_u.$study.txt/_nu.$study.txt/;
	$sample_name_file =~ s/_u.txt/_nu.txt/;
    }
}
else{
    die "ERROR:Please check the type of quants file. It has to be either \"exonquants\", \"intronquants\", \"genequants\".\n\n";
}


if($type =~ /^exon/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
	chomp($line);
	$id = $line;
	if($nuonly eq "false"){
	    print OUT "$exon_dir/Unique/$id.exonmappers.norm_u_exonquants\n";
	}
	if($nuonly eq "true"){
            print OUT "$exon_dir/NU/$id.exonmappers.norm_nu_exonquants\n";
	}
    }
}
if ($type =~ /^gene/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
        chomp($line);
        $id = $line;
        if($nuonly eq "false"){
            print OUT "$norm_dir/FINAL_SAM/Unique/$id.FINAL.norm_u.genequants\n";
        }
        if($nuonly eq "true"){
            print OUT "$norm_dir/FINAL_SAM/NU/$id.FINAL.norm_nu.genequants\n";
        }
    }
}
close(INFILE);
close(OUT);

if ($type =~ /^intron/){
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    open(OUT, ">$sample_name_file");
    while ($line = <INFILE>){
	chomp($line);
	$id = $line;
	if($nuonly eq "false"){
            print OUT "$nexon_dir/Unique/$id.intronmappers.norm_u_intronquants\n";
	}
	if($nuonly eq "true"){
	    print OUT "$nexon_dir/NU/$id.intronmappers.norm_nu_intronquants\n";
	}
    }
}
close(INFILE);
close(OUT);

open(FILES, $sample_name_file);
$file = <FILES>;
close(FILES);

open(INFILE, $file) or die "cannot find file \"$file\"\n";
$firstline = <INFILE>;
$rowcnt = 0;
while($line = <INFILE>) {
    chomp($line);
    if ($type =~ /^gene/){
	if ($line !~ /^EN/){
	    next;
	}
    }
    if (($type =~ /^exon/) || ($type =~ /^intron/)){
	if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
	    next;
	}
    }
    @a = split(/\t/,$line);
    $id[$rowcnt] = $a[0];
    $sym[$rowcnt] = $a[3];
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
    $id =~ s/.exonmappers.norm_u_exonquants//;
    $id =~ s/.exonmappers.norm_nu_exonquants//;
    $id =~ s/.intronmappers.norm_u_intronquants//;
    $id =~ s/.intronmappers.norm_nu_intronquants//;
    $id =~ s/.FINAL.norm_u.genequants//;
    $id =~ s/.FINAL.norm_nu.genequants//;
    $ID[$filecnt] = $id;
    open(INFILE, $file);
    $firstline = <INFILE>;
    $rowcnt = 0;
    while($line = <INFILE>) {
	chomp($line);
	@a = split(/\t/,$line);
	if (($type =~ /^exon/) || ($type =~ /^intron/)){
	    if ($line !~ /([^:\t\s]+):(\d+)-(\d+)/){
		next;
	    }
	    $DATA[$filecnt][$rowcnt] = $a[1];
	}
	if ($type =~ /^gene/){
	    if ($line !~ /^EN/){
		next;
	    }
	    $DATA_MIN[$filecnt][$rowcnt] = $a[1];
	    $DATA_MAX[$filecnt][$rowcnt] = $a[2];
	}
	$rowcnt++;
    }
    close(INFILE);
    $filecnt++;
}
close(FILES);

if (($type =~ /^exon/) || ($type =~ /^intron/)){
    open(OUTFILE, ">$out");
    print OUTFILE "id";
    for($i=0; $i<@ID; $i++) {
	print OUTFILE "\t$ID[$i]";
    }
    print OUTFILE "\n";
    for($i=0; $i<$rowcnt; $i++) {
	if ($type =~ /^exon/){
	    print OUTFILE "exon:$id[$i]";
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
}
if ($type =~ /^gene/){
    open(OUT_MIN, ">$out_min");
    open(OUT_MAX, ">$out_max");
    print OUT_MIN "id";
    print OUT_MAX "id";
    for($i=0; $i<@ID; $i++) {
        print OUT_MIN "\t$ID[$i]";
        print OUT_MAX "\t$ID[$i]";
    }
    print OUT_MIN "\tgeneSymbol\n";
    print OUT_MAX "\tgeneSymbol\n";
    for($i=0; $i<$rowcnt; $i++) {
	print OUT_MIN "$id[$i]";
	print OUT_MAX "$id[$i]";
        for($j=0; $j<$filecnt; $j++) {
            print OUT_MIN "\t$DATA_MIN[$j][$i]";
            print OUT_MAX "\t$DATA_MAX[$j][$i]";
	}
	print OUT_MIN "\t$sym[$i]\n";
	print OUT_MAX "\t$sym[$i]\n";
    }
    close(OUT_MIN);
    close(OUT_MAX);
}
print "got here\n";
