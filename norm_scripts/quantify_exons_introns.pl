#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "perl quanitfy_exons_introns.pl <samfile> <exons file> <introns file> <intergenic regions file> <loc>

<samfile> input samfile (full path)
<exons file> master list of exons file (full path) 
<introns file> master list of introns file (full path)
<intergenic regions file> master list of intergenic regions file (full path)
<loc> is where the sample directories are

* note : this script assumes the input samfile is single end data.

options:
 -exon_only : set this if you want to quantify exons only (this option does not work when -outputsam flag is used). 
              By default, this script will output both exon and intronquants
 -intron_only : set this if you want to quantify introns only (this option does not work when -outputsam flag is used).
                By default, this script will output both exon and intronquants
 -filter_highexp : set this if you want to filter out the reads that map to highly expressed exons and introns.
 -outputsam : set this if you want to output the sam files of exon mappers, intronmappers and intronmappers.
 -depthE <n> : by default, it will output 20 exonmappers.
 -depthI <n> : by default, it will output 10 intronmappers.
 -str_f : if forward read is in the same orientation as the transcripts/genes.
 -str_r : if reverse read is in the same orientation as the transcripts/genes.
 -h : prints usage.

";

if (@ARGV < 5){
    die $USAGE;
}
my $FWD = "false";
my $REV = "false";
my $numargs = 0;
my $stranded = "false";
my $i_exon = 20;
my $i_intron = 10;
my $print = "false";
my $filter = "false";
my $qexon = "true";
my $qintron = "true";
my $qcnt = 0;
for(my $i=5; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-h'){
	die $USAGE;
    }
    if ($ARGV[$i] eq '-filter_highexp'){
	$filter = "true";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-outputsam'){
	$option_found = "true";
	$print = "true";
    }
    if ($ARGV[$i] eq '-exon_only'){
        $option_found = "true";
	$qintron = "false";
	$qcnt++;
    }
    if ($ARGV[$i] eq '-intron_only'){
        $option_found = "true";
	$qexon = "false";
	$qcnt++;
    }
    if($ARGV[$i] eq '-str_f') {
	$FWD = "true";
	$stranded = "true";
	$numargs++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-str_r') {
	$REV = "true";
	$stranded = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthE'){
	$i_exon = $ARGV[$i+1];
	if ($i_exon !~ /(\d+$)/ ){
	    die "-depthE <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthI'){
	$i_intron = $ARGV[$i+1];
	if ($i_intron !~ /(\d+$)/ ){
	    die "-depthI <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($stranded eq "true"){
    if($numargs ne '1') {
	die "You can only use one of the options \"-str_f\" or \"-str_r\".\n";
    }
}

if ($qcnt > 1){
    die "You cannot use both -exon_only and -intron_only. It will quantify both exons and introns by default.\n\n";
}

my $samfile = $ARGV[0];
my @fields = split("/", $samfile);
my $samname = $fields[@fields-1];

my $LOC = $ARGV[4];
$LOC =~ s/\/$//;
my $directory = $samfile;
$directory =~ s/$samname$//g;
my $exonquants = $directory . "/$samname";
$exonquants =~ s/.sam.gz$/.exonquants/;
$exonquants =~ s/.sam$/.exonquants/;
my $intronquants = $directory . "/$samname";
$intronquants =~ s/.sam.gz$/.intronquants/;
$intronquants =~ s/.sam$/.intronquants/;
my $linecountfile = "$directory/linecounts.txt";
my ($exonquants_anti, $intronquants_anti, $sensedir, $antisensedir, $linecountfile_exon_anti, $linecountfile_intron_anti);
my $exon_sam_out = $samfile;
$exon_sam_out =~ s/.sam.gz$/_exonmappers.sam.gz/g;
$exon_sam_out =~ s/.sam$/_exonmappers.sam/g;
my $intron_sam_out = $samfile;
$intron_sam_out =~ s/.sam.gz$/_intronmappers.sam.gz/g;
$intron_sam_out =~ s/.sam$/_intronmappers.sam/g;
my $intergenic_sam_out = $samfile;
$intergenic_sam_out =~ s/.sam.gz$/_intergenicmappers.sam.gz/;
$intergenic_sam_out =~ s/.sam$/_intergenicmappers.sam/;
my $exon_inconsistent_sam_out = $samfile;
$exon_inconsistent_sam_out =~ s/.sam.gz$/_exon_inconsistent_reads.sam.gz/;
$exon_inconsistent_sam_out =~ s/.sam$/_exon_inconsistent_reads.sam/;
my ($exon_sam_out_anti, $intron_sam_out_anti, $linecountfile_anti);
if ($stranded eq "true"){
    if ($print eq "false"){
	$exonquants = "$directory/$samname";
        $exonquants =~ s/.sam.gz$/.sense.exonquants/;
        $exonquants =~ s/.sam$/.sense.exonquants/;
        $intronquants = "$directory/$samname";
        $intronquants =~ s/.sam.gz$/.sense.intronquants/;
        $intronquants =~ s/.sam$/.sense.intronquants/;
	$exonquants_anti = "$directory/$samname";
        $exonquants_anti =~ s/.sam.gz$/.antisense.exonquants/;
        $exonquants_anti =~ s/.sam$/.antisense.exonquants/;
        $intronquants_anti = "$directory/$samname";
        $intronquants_anti =~ s/.sam.gz$/.antisense.intronquants/;
        $intronquants_anti =~ s/.sam$/.antisense.intronquants/;

        $linecountfile = "$directory/linecounts.txt";
        $linecountfile_anti = "$directory/linecounts.txt";

        $exon_sam_out = "$directory/$samname";
        $exon_sam_out =~ s/.sam.gz$/_exonmappers.sam.gz/g;
        $exon_sam_out =~ s/.sam$/_exonmappers.sam.gz/g;
        $intron_sam_out = "$directory/$samname";
        $intron_sam_out =~ s/.sam.gz$/_intronmappers.sam.gz/g;
        $intron_sam_out =~ s/.sam$/_intronmappers.sam.gz/g;

        $exon_sam_out_anti = "$directory/$samname";
        $exon_sam_out_anti =~ s/.sam.gz$/_exonmappers.sam.gz/g;
        $exon_sam_out_anti =~ s/.sam$/_exonmappers.sam.gz/g;
        $intron_sam_out_anti = "$directory/$samname";
        $intron_sam_out_anti =~ s/.sam.gz$/_intronmappers.sam.gz/g;
        $intron_sam_out_anti =~ s/.sam$/_intronmappers.sam.gz/g;
    }
    if ($print eq "true"){
	$sensedir = "$directory/sense";
	$antisensedir = "$directory/antisense";
	unless (-d "$sensedir"){
	    `mkdir -p $sensedir`;
	}
	unless (-d "$antisensedir"){
	    `mkdir -p $antisensedir`;
	}
	$exonquants = "$sensedir/$samname";
	$exonquants =~ s/.sam.gz$/.sense.exonquants/;
	$exonquants =~ s/.sam$/.sense.exonquants/;
	$intronquants = "$sensedir/$samname";
	$intronquants =~ s/.sam.gz$/.sense.intronquants/;
	$intronquants =~ s/.sam$/.sense.intronquants/;

	$exonquants_anti = "$antisensedir/$samname";
	$exonquants_anti =~ s/.sam.gz$/.antisense.exonquants/;
	$exonquants_anti =~ s/.sam$/.antisense.exonquants/;
	$intronquants_anti = "$antisensedir/$samname";
	$intronquants_anti =~ s/.sam.gz$/.antisense.intronquants/;
	$intronquants_anti =~ s/.sam$/.antisense.intronquants/;
	
	$linecountfile = "$sensedir/linecounts.txt";
	$linecountfile_anti = "$antisensedir/linecounts.txt";

	$exon_sam_out = "$sensedir/$samname";
	$exon_sam_out =~ s/.sam.gz$/_exonmappers.sam.gz/g;
	$exon_sam_out =~ s/.sam$/_exonmappers.sam.gz/g;
	$intron_sam_out = "$sensedir/$samname";
	$intron_sam_out =~ s/.sam.gz$/_intronmappers.sam.gz/g;
	$intron_sam_out =~ s/.sam$/_intronmappers.sam.gz/g;
	
	$exon_sam_out_anti = "$antisensedir/$samname";
	$exon_sam_out_anti =~ s/.sam.gz$/_exonmappers.sam.gz/g;
	$exon_sam_out_anti =~ s/.sam$/_exonmappers.sam.gz/g;
	$intron_sam_out_anti = "$antisensedir/$samname";
	$intron_sam_out_anti =~ s/.sam.gz$/_intronmappers.sam.gz/g;
	$intron_sam_out_anti =~ s/.sam$/_intronmappers.sam.gz/g;
    }
}
my (@exon_sam_outfile, @anti_exon_sam_outfile,  @OUTFILE_EXON, @OUTFILE_EXON_A);
my (@intron_sam_outfile, @anti_intron_sam_outfile,  @OUTFILE_INTRON, @OUTFILE_INTRON_A);
my $statsfile = "$directory/stats.txt";
my $total_lc = 0;
my $total_lc_a = 0;
my ($ex_only, $int_only, $ig_only, $ex_int, $ex_inc_only) = (0,0,0,0,0,0,0,0);
my ($ex_only_a, $int_only_a, $ex_int_a) = (0,0,0,0,0,0);

my $max_exon = 20;
my $max_intron = 10;
unless ($i_exon eq $max_exon){
    $max_exon = $i_exon;
}
unless ($i_intron eq $max_intron){
    $max_intron = $i_intron;
}
my ($EXONSAMOUT,$INTRONSAMOUT,$INTERGENIC,$EXON_INCONSISTENT, $ANTIEXONSAMOUT, $ANTIINTRONSAMOUT);
if ($print eq "true"){
    open($EXONSAMOUT, "| /bin/gzip -c > $exon_sam_out") or die "error starting gzip $!";
    open(LC, ">$linecountfile");
    open($INTRONSAMOUT, "| /bin/gzip -c >$intron_sam_out") or die "error starting gzip $!";
    open($INTERGENIC, "| /bin/gzip -c >$intergenic_sam_out") or die "error starting gzip $!";
    open($EXON_INCONSISTENT, "| /bin/gzip -c >$exon_inconsistent_sam_out") or die "error starting gzip $!";
    for (my $i=1; $i<=$max_exon;$i++){
        $exon_sam_outfile[$i] = $exon_sam_out;
        $exon_sam_outfile[$i] =~ s/.sam.gz$/.$i.sam.gz/;
        open($OUTFILE_EXON[$i], "| /bin/gzip -c >$exon_sam_outfile[$i]") or die "error starting gzip $!";
    }
    for (my $i=1; $i<=$max_intron;$i++){
        $intron_sam_outfile[$i] = $intron_sam_out;
        $intron_sam_outfile[$i] =~ s/.sam.gz$/.$i.sam.gz/;
        open($OUTFILE_INTRON[$i], "| /bin/gzip -c >$intron_sam_outfile[$i]") or die "error starting gzip $!";
    }
    if ($stranded eq "true"){
        open(LC_A, ">$linecountfile_anti");
        open($ANTIEXONSAMOUT, "| /bin/gzip -c >$exon_sam_out_anti") or die "error starting gzip $!";
        open($ANTIINTRONSAMOUT, "| /bin/gzip -c >$intron_sam_out_anti") or die "error starting gzip $!";
        for (my $i=1; $i<=$max_exon;$i++){
            $anti_exon_sam_outfile[$i] = $exon_sam_out_anti;
            $anti_exon_sam_outfile[$i] =~ s/.sam.gz$/.$i.sam.gz/;
            open($OUTFILE_EXON_A[$i], "| /bin/gzip -c >$anti_exon_sam_outfile[$i]") or die "error starting gzip $!";
        }
        for (my $i=1; $i<=$max_intron;$i++){
            $anti_intron_sam_outfile[$i] = $intron_sam_out_anti;
            $anti_intron_sam_outfile[$i] =~ s/.sam.gz$/.$i.sam.gz/;
            open($OUTFILE_INTRON_A[$i], "| /bin/gzip -c >$anti_intron_sam_outfile[$i]") or die "error starting gzip $!";
        }
    }
}

my %HIGHEXP_E = ();
my %HIGHEXP_E_A = ();
my %HIGHEXP_I = ();
my %HIGHEXP_I_A = ();

my (%CNT_HIGH_E, %CNT_HIGH_E_A, %CNT_HIGH_I, %CNT_HIGH_I_A);
my (%OUT_HIGH_E, %OUT_HIGH_E_A, %OUT_HIGH_I, %OUT_HIGH_I_A);
if ($filter eq "true"){
    #highly expressed exons
    my $highexp_file = "$LOC/high_expressers_exon.txt";
    if ($stranded eq "true"){
	$highexp_file = "$LOC/high_expressers_exon_sense.txt";
    }
    open(HIGH, $highexp_file) or die "cannot find file '$highexp_file'.\n";
    while(my $line = <HIGH>){
	chomp($line);
	if ($line =~ /([^:\t\s]+):(\d+)-(\d+)/) {
	    my $chr = $1;
	    my $start = $2;
	    my $end = $3;
	    my $exon = "$chr:$start-$end";
	    if ($line =~ /\.[1]$/){
		$exon = $exon . ".1";
	    }
	    $HIGHEXP_E{$exon} = 1;
	}
	else{
	    next;
	}
    }
    close(HIGH);
    if ($stranded eq "true"){
	my $highexp_file_a = "$LOC/high_expressers_exon_antisense.txt";
	open(HIGH, $highexp_file_a) or die "cannot find file '$highexp_file_a'.\n";
	while(my $line = <HIGH>){
	    chomp($line);
	    if ($line =~ /([^:\t\s]+):(\d+)-(\d+)/) {
		my $chr = $1;
		my $start = $2;
		my $end = $3;
		my $exon = "$chr:$start-$end";
		if ($line =~ /\.[1]$/){
		    $exon = $exon . ".1";
		}
		$HIGHEXP_E_A{$exon} = 1;
	    }
	    else{
		next;
	    }
	}
	close(HIGH);
    }
    if ($print eq "true"){
	foreach my $exon (keys %HIGHEXP_E){
	    my $highexp = $exon_sam_out;
	    my $tmp = $exon;
	    $tmp =~ s/:/./;
	    $highexp =~ s/.sam.gz$/.$tmp.sam.gz/;
	    open($OUT_HIGH_E{$exon}, "| /bin/gzip -c >$highexp") or die "error starting gzip $!";
	    $CNT_HIGH_E{$exon} = 0;
	}
	foreach my $exon (keys %HIGHEXP_E_A){
	    my $highexp = $exon_sam_out_anti;
	    my $tmp = $exon;
	    $tmp =~ s/:/./;
	    $highexp =~ s/.sam.gz$/.$tmp.sam.gz/;
	    open($OUT_HIGH_E_A{$exon}, "| /bin/gzip -c >$highexp") or die "error starting gzip $!";
	    $CNT_HIGH_E_A{$exon} = 0;
	}
    }
    #introns
    my $highexp_file_i = "$LOC/high_expressers_intron.txt";
    if ($stranded eq "true"){
	$highexp_file_i = "$LOC/high_expressers_intron_sense.txt";
    }
    open(HIGH, $highexp_file_i) or die "cannot find file '$highexp_file_i'.\n";
    while(my $line = <HIGH>){
	chomp($line);
	if ($line =~ /([^:\t\s]+):(\d+)-(\d+)/) {
	    my $chr = $1;
	    my $start = $2;
	    my $end = $3;
	    my $intron = "$chr:$start-$end";
	    if ($line =~ /\.[1]$/){
		$intron = $intron . ".1";
	    }
	    $HIGHEXP_I{$intron} = 1;
	}
	else{
	    next;
	}
    }
    close(HIGH);
    if ($stranded eq "true"){
	my $highexp_file_i_a = "$LOC/high_expressers_intron_antisense.txt";
	open(HIGH, $highexp_file_i_a) or die "cannot find file '$highexp_file_i_a'.\n";
	while(my $line = <HIGH>){
	    chomp($line);
	    if ($line =~ /([^:\t\s]+):(\d+)-(\d+)/) {
		my $chr = $1;
		my $start = $2;
		my $end = $3;
		my $intron = "$chr:$start-$end";
		if ($line =~ /\.[1]$/){
			$intron = $intron . ".1";
		}
		$HIGHEXP_I_A{$intron} = 1;
	    }
	    else{
		next;
	    }
	}
	close(HIGH);
    }
    if ($print eq "true"){
	foreach my $intron (keys %HIGHEXP_I){
	    my $highexp = $intron_sam_out;
	    my $tmp = $intron;
	    $tmp =~ s/:/./;
	    $highexp =~ s/.sam.gz$/.$tmp.sam.gz/;
	    open($OUT_HIGH_I{$intron}, "| /bin/gzip -c >$highexp") or die "error starting gzip $!";
	    $CNT_HIGH_I{$intron} = 0;
	}
	foreach my $intron (keys %HIGHEXP_I_A){
	    my $highexp = $intron_sam_out_anti;
	    my $tmp = $intron;
	    $tmp =~ s/:/./;
	    $highexp =~ s/.sam.gz$/.$tmp.sam.gz/;
	    open($OUT_HIGH_I_A{$intron}, "| /bin/gzip -c >$highexp") or die "error starting gzip $!";
	    $CNT_HIGH_I_A{$intron} = 0;
	}
    }
}

my (%exonHASH, %exSTART, %exEND, %exonSTR, %exon_uniqueCOUNT, %exon_nuCOUNT, %doneEXON, %doneEXON_ANTI, %exon_uniqueCOUNT_anti, %exon_nuCOUNT_anti);
my (%ML_E, %ML_E_A);
# master list of exons
my $exonsfile = $ARGV[1];
open(EXONS, $exonsfile) or die "cannot find '$exonsfile'\n";
while(my $line = <EXONS>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $line1 = $a[0];
    my $strand = $a[1];
    my ($chr, $start, $end);
    if ($line1 =~ /([^:\t\s]+):(\d+)-(\d+)/){
	$chr = $1;
	$start = $2;
	$end = $3;
    }
    my $exon = "$chr:$start-$end";
    if ($line1 =~ /\.[1]$/){
	$exon = $exon . ".1";
    }
    my $index_st = int($start/1000);
    my $index_end = int($end/1000);
    if (exists $exonSTR{$exon}){
	next;
    }
    for (my $index = $index_st; $index <= $index_end; $index++){
	push (@{$exonHASH{$chr}[$index]}, $exon);
    }
    my @exonStArray = ();
    my @exonEndArray = ();
    $exonSTR{$exon} = $strand;
    $ML_E{$exon} = 1;
    push (@exonStArray, $start);
    push (@exonEndArray, $end);
    $exSTART{$exon} = \@exonStArray;
    $exEND{$exon} = \@exonEndArray;
    $exon_uniqueCOUNT{$exon} = 0;
    $exon_nuCOUNT{$exon} = 0;
    if ($stranded eq "true"){
	$exon_uniqueCOUNT_anti{$exon} = 0;
	$exon_nuCOUNT_anti{$exon} = 0;
	$ML_E_A{$exon} = 1;
    }
}
my (%intronHASH, %intSTART, %intEND, %intronSTR, %intron_uniqueCOUNT, %intron_nuCOUNT, %intron_uniqueCOUNT_anti, %intron_nuCOUNT_anti, %doneINTRON, %doneINTRON_ANTI);
my (%ML_I, %ML_I_A);
# master list of introns
my $intronsfile = $ARGV[2];
open(INTRONS, $intronsfile) or die "cannot find '$intronsfile'\n";
while(my $line = <INTRONS>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $line1 = $a[0];
    my $strand = $a[1];
    my ($chr, $start, $end);
    if ($line1 =~ /([^:\t\s]+):(\d+)-(\d+)/){
	$chr = $1;
	$start = $2;
	$end = $3;
    }
    my $intron = "$chr:$start-$end";
    if ($line1 =~ /\.[1]$/){
	$intron = $intron . ".1";
    }
    my $index_st = int($start/1000);
    my $index_end = int($end/1000);
    if (exists $intronSTR{$intron}){
	next;
    }
    for (my $index = $index_st; $index <= $index_end; $index++){
	push (@{$intronHASH{$chr}[$index]}, $intron);
    }
    my @intronStArray = ();
    my @intronEndArray = ();
    $intronSTR{$intron} = $strand;
    $ML_I{$intron} = 1;
    push (@intronStArray, $start);
    push (@intronEndArray, $end);
    $intSTART{$intron} = \@intronStArray;
    $intEND{$intron} = \@intronEndArray;
    $intron_uniqueCOUNT{$intron} = 0;
    $intron_nuCOUNT{$intron} = 0;
    if ($stranded eq "true"){
	$intron_uniqueCOUNT_anti{$intron} = 0;
	$intron_nuCOUNT_anti{$intron} = 0;
	$ML_I_A{$intron}=1;
    }
}
my (%igHASH, %igSTART, %igEND, %doneIG);
if ($print eq "true"){ 
    # master list of intergenic regions
    my $igsfile = $ARGV[3];
    open(IG, $igsfile) or die "cannot find '$igsfile'\n";
    while(my $line = <IG>){
	chomp($line);
	my ($chr, $start, $end);
	if ($line =~ /([^:\t\s]+):(\d+)-(\d+)/){
	    $chr = $1;
	    $start = $2;
	    $end = $3;
	}
	my $ig = "$chr:$start-$end";
	my $index_st = int($start/1000);
	my $index_end = int($end/1000);
	if (exists $igHASH{$ig}){
	    next;
	}
	for (my $index = $index_st; $index <= $index_end; $index++){
	    push (@{$igHASH{$chr}[$index]}, $ig);
	}
	my @igStArray = ();
	my @igEndArray = ();
	push (@igStArray, $start);
	push (@igEndArray, $end);
	$igSTART{$ig} = \@igStArray;
	$igEND{$ig} = \@igEndArray;
    }
}

my $CNT_OF_FRAGS_WHICH_HIT_EXONS = 0;
my $CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI = 0;
my $CNT_OF_FRAGS_WHICH_HIT_INTRONS = 0;
my $CNT_OF_FRAGS_WHICH_HIT_INTRONS_ANTI = 0;
my (@EXON_FLAG_DIST, @EXON_FLAG_DIST_ANTI, @INTRON_FLAG_DIST, @INTRON_FLAG_DIST_ANTI);
my (@exon_outfile_cnt, @A_exon_outfile_cnt, @intron_outfile_cnt, @A_intron_outfile_cnt);
my $ig_outfile_cnt = 0;
my $exon_inconsistent_outfile_cnt = 0;


for (my $i=0;$i<=$max_exon;$i++){
    $exon_outfile_cnt[$i] = 0;
    $EXON_FLAG_DIST[$i] = 0;
    if ($stranded eq "true"){
	$A_exon_outfile_cnt[$i] = 0;
	$EXON_FLAG_DIST_ANTI[$i] = 0;
    }
}
for (my $i=0;$i<=$max_intron;$i++){
    $intron_outfile_cnt[$i] = 0;
    $INTRON_FLAG_DIST[$i] = 0;
    if ($stranded eq "true"){
        $A_intron_outfile_cnt[$i] = 0;
	$INTRON_FLAG_DIST_ANTI[$i] = 0;
    }
}
if ($samfile =~ /.gz$/){
    my $pipecmd = "zcat $samfile";
    open(SAM, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
}
else{
    open(SAM, $samfile) or die "cannot open $samfile\n";
}
while(my $line = <SAM>){
    chomp($line);
    $total_lc++;
    if ($line =~ /^@/){
	next;
    }
    my $sense = "false";
    
    my $exonFlag = 0;
    my $AexonFlag = 0;
    my $intronFlag = 0;
    my $AintronFlag = 0;
    my $igFlag = 0;
    my $eiFlag = 0;
    my $print_exon = "true";
    my $print_exon_A = "true";
    my $print_intron = "true";
    my $print_intron_A = "true";
    my $UNIQUE = "false";
    my $NU = "false";
    my $tag = 0;
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$tag = $2;
    }
    if ($tag == 1){
	$UNIQUE = "true";
    }
    else {
	$NU = "true";
    }
    my @readStarts = ();
    my @readEnds = ();
    my @a = split(/\t/, $line);
    my $read_id = $a[0];
    my $bitflag = $a[1];
    my $chr = $a[2];
    my $readSt = $a[3];
    my $cigar = $a[5];
    while ($cigar =~ /(\d+)M(\d+)D(\d+)M/){
	my $N = $1+$2+$3;
	my $str = $1 . "M" . $2 . "D" . $3 . "M";
	my $new_str = $N . "M";
	$cigar =~ s/$str/$new_str/;
    }
    my $spans = &cigar2spans($readSt, $cigar);
#    print "===============\n$read_id\t"; #debug
    my %EXONS = (); #debug
    my %A_EXONS = (); #debug
    my %INTRONS = (); #debug
    my %A_INTRONS = (); #debug
    my %IGS = (); #debug
#    print "$spans\n"; #debug
    my @b = split (",", $spans);
    for (my $i=0; $i<@b; $i++){
	my @c = split("-", $b[$i]);
	my $read_st = $c[0];
	$read_st =~ s/^\s*(.*?)\s*$/$1/;
	my $read_end = $c[1];
	$read_end =~ s/^\s*(.*?)\s*$/$1/;
	push (@readStarts, $read_st);
	push (@readEnds, $read_end);
    }
    undef %doneEXON;
    undef %doneINTRON;
    undef %doneEXON_ANTI;
    undef %doneINTRON_ANTI;
    undef %doneIG;
    
    #set highexp feature to 0
    foreach my $exon (keys %HIGHEXP_E){
	$HIGHEXP_E{$exon} = 0;
    }
    foreach my $intron (keys %HIGHEXP_I){
        $HIGHEXP_I{$intron} = 0;
    }
    foreach my $exon (keys %HIGHEXP_E_A){
	$HIGHEXP_E_A{$exon} = 0;
    }
    foreach my $intron (keys %HIGHEXP_I_A){
	$HIGHEXP_I_A{$intron} = 0;
    }
    # if stranded, check read orientation using exon
    if ($stranded eq "true"){
	for(my $i=0;$i<@b;$i++){
	    $b[$i] =~ /(\d+)-(\d+)/;
	    my $read_segment_start = $1;
	    my $read_segment_end = $2;
	    my $read_segment_start_block = int($read_segment_start / 1000);
	    my $read_segment_end_block = int($read_segment_end / 1000);
	    for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
		if (exists $exonHASH{$chr}[$index]){
		    my $hashsize = @{$exonHASH{$chr}[$index]};
		    for (my $j=0; $j<$hashsize; $j++){
			my $exon = $exonHASH{$chr}[$index][$j];
			my $check = &checkCompatibility($chr, $exSTART{$exon}, $exEND{$exon}, $chr, \@readStarts, \@readEnds);
			my $read_strand = "";
			if ($FWD eq "true"){
			    if ($bitflag & 16){
				$read_strand = "-";
			    }
			    else{
				$read_strand = "+";
			    }
			}
			if ($REV eq "true"){
			    if ($bitflag & 16){
				$read_strand = "+";
			    }
			    else{
				$read_strand = "-";
			    }
			}
			if ($check eq "1"){
			    if ($read_strand eq $exonSTR{$exon}){ #sense
				$sense = "true";
			    }
			}
		    }
		}
	    }
	}
	# if not mapped to sense-exon, check intron orientation
	if ($sense eq "false"){
	    for(my $i=0;$i<@b;$i++){
		$b[$i] =~ /(\d+)-(\d+)/;
		my $read_segment_start = $1;
		my $read_segment_end = $2;
		my $read_segment_start_block = int($read_segment_start / 1000);
		my $read_segment_end_block = int($read_segment_end / 1000);
		for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
		    if (exists $intronHASH{$chr}[$index]){
			my $hashsize = @{$intronHASH{$chr}[$index]};
			for (my $j=0; $j<$hashsize; $j++){
			    my $intron = $intronHASH{$chr}[$index][$j];
			    my $check = &compareSegments_overlap($chr, $chr, $intSTART{$intron}->[0], $intEND{$intron}->[0], \@readStarts, \@readEnds);
			    my $read_strand = "";
			    if ($FWD eq "true"){
				if ($bitflag & 16){
				    $read_strand = "-";
				}
				else{
				    $read_strand = "+";
				}
			    }
			    if ($REV eq "true"){
				if ($bitflag & 16){
				    $read_strand = "+";
				}
				else{
				    $read_strand = "-";
				}
			    }
			    if ($check eq "1"){
				if ($read_strand eq $intronSTR{$intron}){ #sense
				    $sense = "true";
				}
			    }
			}
		    }
		}
	    }
	}
    }
    for(my $i=0;$i<@b;$i++){
	# NON-STRANDED: if a span is an exonmapper, it cannot be an intronmapper.
	# STRANDED: if a span is a sense-exonmapper, it cannot be anything else. [priority: sense-exon > sense-intron > (anti-exon and anti-intron)]

	#check one span at a time
	my @readStarts_span = ();
	my @readEnds_span = ();
	my @c = split("-", $b[$i]);
	my $read_st = $c[0];
        $read_st =~ s/^\s*(.*?)\s*$/$1/;
	my $read_end = $c[1];
        $read_end =~ s/^\s*(.*?)\s*$/$1/;
        push (@readStarts_span, $read_st);
        push (@readEnds_span, $read_end);

	my $exon_mapper = 0;
	my $intron_mapper = 0;
	$b[$i] =~ /(\d+)-(\d+)/;
	my $read_segment_start = $1;
	my $read_segment_end = $2;
	my $read_segment_start_block = int($read_segment_start / 1000);
	my $read_segment_end_block = int($read_segment_end / 1000);
	#print "\n$b[$i]\n------\n";
	my %temp_AE = ();
	for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
	    # check if read span maps to exon
	    if (exists $exonHASH{$chr}[$index]){
		my $hashsize = @{$exonHASH{$chr}[$index]};
		for (my $j=0; $j<$hashsize; $j++){
		    my $exon = $exonHASH{$chr}[$index][$j];
		    my $check_all = &checkCompatibility($chr, $exSTART{$exon}, $exEND{$exon}, $chr, \@readStarts, \@readEnds);
		    my $check_span = &checkCompatibility($chr, $exSTART{$exon}, $exEND{$exon}, $chr, \@readStarts_span, \@readEnds_span);
		    my $check = $check_all + $check_span;
		    my $check_anti = &compareSegments_overlap($chr, $chr, $exSTART{$exon}->[0], $exEND{$exon}->[0], \@readStarts, \@readEnds);
		    #print "all:$check_all\tspan:$check_span\tanti:$check_anti\n"; #debug
		    if ($stranded eq "true"){
			my $read_strand = "";
			if ($FWD eq "true"){
			    if ($bitflag & 16){
				$read_strand = "-";
			    }
			    else{
				$read_strand = "+";
			    }
			}
			if ($REV eq "true"){
			    if ($bitflag & 16){
				$read_strand = "+";
			    }
			    else{
				$read_strand = "-";
			    }
			}
			if ($check eq "2"){ #read span maps to sense-exon
			    if ($read_strand eq $exonSTR{$exon}){ #sense
				if (!(defined $doneEXON{$exon})){
				    $EXONS{$exon} = 1; #debug
				    if (exists $HIGHEXP_E{$exon}){
					$print_exon = "false";
					$HIGHEXP_E{$exon}++;
					#delete $ML_E{$exon};
				    }
				    else{
					$exonFlag++;
					$exon_mapper++;
					if($exonFlag == 1) {
					    $CNT_OF_FRAGS_WHICH_HIT_EXONS++;
					}
					if ($UNIQUE eq "true"){
					    $exon_uniqueCOUNT{$exon}++;
					}
					if ($NU eq "true"){
					    $exon_nuCOUNT{$exon}++;
					}
				    }
				}
				$doneEXON{$exon} = 1;
			    }
			    elsif ($sense eq "false"){ # antisense
				if (!(defined $doneEXON_ANTI{$exon})){
				    $A_EXONS{$exon} = 1; #debug
				    if (exists $HIGHEXP_E_A{$exon}){
					$print_exon_A = "false";
					$HIGHEXP_E_A{$exon}++;
					#delete $ML_E_A{$exon};
				    }
				    else{
					$AexonFlag++;
					$temp_AE{$exon} = 1;
					if ($AexonFlag == 1){
					    $CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI++;
					}
					if ($UNIQUE eq "true"){
					    $exon_uniqueCOUNT_anti{$exon}++;
					}
					if ($NU eq "true"){
					    $exon_nuCOUNT_anti{$exon}++;
					}
				    }
				}
				$doneEXON_ANTI{$exon}=1;
			    }
			}
			elsif (($sense eq "false") && ($check_anti eq "1") && ($read_strand ne $exonSTR{$exon})){ # antisense
			    if (!(defined $doneEXON_ANTI{$exon})){
				$A_EXONS{$exon} = 1; #debug
				if (exists $HIGHEXP_E_A{$exon}){
				    $print_exon_A = "false";
				    $HIGHEXP_E_A{$exon}++;
				    #delete $ML_E_A{$exon};
				}
				else{
				    $AexonFlag++;
				    $temp_AE{$exon} = 1;
				    if ($AexonFlag == 1){
					$CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI++;
				    }
				    if ($UNIQUE eq "true"){
					$exon_uniqueCOUNT_anti{$exon}++;
				    }
				    if ($NU eq "true"){
					$exon_nuCOUNT_anti{$exon}++;
				    }
				}
			    }
			    $doneEXON_ANTI{$exon}=1;
			}
		    }
		    if ($stranded eq "false"){
			if ($check eq "2"){
			    if (!(defined $doneEXON{$exon})){
				$EXONS{$exon} = 1; #debug
				if (exists $HIGHEXP_E{$exon}){
				    $print_exon = "false";
				    $HIGHEXP_E{$exon}++;
				    #delete $ML_E{$exon};
				}
				else{
				    $exonFlag++;
				    $exon_mapper++;
				    if($exonFlag == 1) {
					$CNT_OF_FRAGS_WHICH_HIT_EXONS++;
				    }
				    if ($UNIQUE eq "true"){
					$exon_uniqueCOUNT{$exon}++;
				    }
				    elsif ($NU eq "true"){
					$exon_nuCOUNT{$exon}++;
				    }
				}
			    }
			    $doneEXON{$exon}=1;
			}
		    }
		}
	    }
	    # check if read span maps to introns
	    if ($exon_mapper == 0){ #only if span not mapped to exon/sense-exon
		if (exists $intronHASH{$chr}[$index]){
		    my $hashsize = @{$intronHASH{$chr}[$index]};
		    for (my $j=0; $j<$hashsize; $j++){
			my $intron = $intronHASH{$chr}[$index][$j];
			my $check = &compareSegments_overlap($chr, $chr, $intSTART{$intron}->[0], $intEND{$intron}->[0], \@readStarts, \@readEnds);
			if ($stranded eq "false"){
			    if ($check eq "1"){
				if (!(defined $doneINTRON{$intron})){                            
				    $INTRONS{$intron} = 1; #debug
				    if (exists $HIGHEXP_I{$intron}){
                                        $print_intron = "false";
					$HIGHEXP_I{$intron}++;
					#delete $ML_I{$intron};
                                    }
                                    else{
					$intronFlag++;
					$intron_mapper++;
					if($intronFlag == 1) {
					    $CNT_OF_FRAGS_WHICH_HIT_INTRONS++;
					}
					if ($UNIQUE eq "true"){
					    $intron_uniqueCOUNT{$intron}++;
					}
					elsif ($NU eq "true"){
					    $intron_nuCOUNT{$intron}++;
					}
				    }
				}
				$doneINTRON{$intron}=1;
			    }
			}
			if ($stranded eq "true"){
			    my $read_strand = "";
			    if ($FWD eq "true"){
				if ($bitflag & 16){
				    $read_strand = "-";
				}
				else{
				    $read_strand = "+";
				}
			    }
			    if ($REV eq "true"){
				if ($bitflag & 16){
				    $read_strand = "+";
				}
				else{
				    $read_strand = "-";
				}
			    }
			    if ($check eq "1"){
				if ($sense eq "true"){
				    if ($read_strand eq $intronSTR{$intron}){ #sense
					if (!(defined $doneINTRON{$intron})){
					    $INTRONS{$intron} = 1; #debug
					    if (exists $HIGHEXP_I{$intron}){
						$print_intron = "false";
						$HIGHEXP_I{$intron}++;
						#delete $ML_I{$intron};
					    }
					    else{
						$intronFlag++;
						$intron_mapper++;
						if($intronFlag == 1) {
						    $CNT_OF_FRAGS_WHICH_HIT_INTRONS++;
						}
						if ($UNIQUE eq "true"){
						    $intron_uniqueCOUNT{$intron}++;
						}
						elsif ($NU eq "true"){
						    $intron_nuCOUNT{$intron}++;
						}
					    }
					}
					$doneINTRON{$intron} = 1;
				    }
				}
				else { #antisense
				    if (!(defined $doneINTRON_ANTI{$intron})){
					$A_INTRONS{$intron} = 1; #debug				
					if (exists $HIGHEXP_I_A{$intron}){
					    $print_intron_A = "false";
					    $HIGHEXP_I_A{$intron}++;
					    #delete $ML_I_A{$intron};
					}
					else{
					    $AintronFlag++;
					    if($AintronFlag == 1) {
						$CNT_OF_FRAGS_WHICH_HIT_INTRONS_ANTI++;
					    }
					    if ($UNIQUE eq "true"){
						$intron_uniqueCOUNT_anti{$intron}++;
					    }
					    elsif ($NU eq "true"){
						$intron_nuCOUNT_anti{$intron}++;
					    }
					}
				    }
				    $doneINTRON_ANTI{$intron} = 1;
				}
			    }
			}
		    }
		}
	    }
	}
	# if span is sense-intron mapper AND antisense-exon mapper, uncount antisense exon
	if ($stranded eq "true"){
	    if ($intron_mapper == 1){ #sense intronmapper
		# un-count antisense-exon
		if ($AexonFlag > 0){
		    foreach my $exon (keys %temp_AE){
#			print "ANTI:$exon\t";
			delete $A_EXONS{$exon};
			if (exists $HIGHEXP_E_A{$exon}){
			    $print_exon_A = "true";
			    $HIGHEXP_E_A{$exon}--;
			}
			else{
			    if ($AexonFlag == 1){
				$CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI--;
			    }
			    if ($AexonFlag > 0){
				$AexonFlag--;
			    }
			    if ($UNIQUE eq "true"){
				$exon_uniqueCOUNT_anti{$exon}--;
			    }
			    elsif ($NU eq "true"){
				$exon_nuCOUNT_anti{$exon}--;
			    }
			}
			delete $doneEXON_ANTI{$exon};
		    }
		}
	    }
	}
#	print "exonmapper:$exon_mapper\tintronmapper:$intron_mapper\n"; #debug
    }
    # intergenic mapper?
    # check if read span maps to intergenic region only if it didn't map to anything
    if ($print eq "true"){
	if (($exonFlag == 0) && ($intronFlag == 0) && ($AexonFlag == 0) && ($AintronFlag == 0)){
	    for(my $i=0;$i<@b;$i++){
		$b[$i] =~ /(\d+)-(\d+)/;
		my $read_segment_start = $1;
		my $read_segment_end = $2;
		my $read_segment_start_block = int($read_segment_start / 1000);
		my $read_segment_end_block = int($read_segment_end / 1000);
		for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
		    if (exists $igHASH{$chr}[$index]){
			my $hashsize = @{$igHASH{$chr}[$index]};
			for (my $j=0;$j<$hashsize;$j++){
			    my $interg = $igHASH{$chr}[$index][$j];
			    my $check = &compareSegments_overlap($chr,$chr,$igSTART{$interg}->[0], $igEND{$interg}->[0], \@readStarts, \@readEnds);
			    if ($check eq "1"){
				$IGS{$interg} = 1; #debug
				if (!(defined $doneIG{$interg})){
				    $igFlag++;
				}
				$doneIG{$interg}=1;
			    }
			}
		    }
		}
	    }
	}
    }
    # START PRINTING : READ LEVEL NOW
    #exon
    if (($print eq "true") && ($print_exon eq "true")){
	if ($exonFlag >= 1){
	    print $EXONSAMOUT "$line\n";
	    for (my $i=1; $i<$max_exon;$i++){
		if ($exonFlag == $i){
		    $exon_outfile_cnt[$i]++;
		    print {$OUTFILE_EXON[$i]} "$line\n";
		}
	    }
	    if ($exonFlag >= $max_exon){
		$exon_outfile_cnt[$max_exon]++;
		print {$OUTFILE_EXON[$max_exon]} "$line\n";
	    }
	    if ($intronFlag >= 1){
		$ex_int++; #exon-intron
	    }
	    else{
		$ex_only++; #exon-only
	    }
	}
    }
    #antisense-exon
    if (($print eq "true") && ($print_exon_A eq "true")){
	if ($AexonFlag >= 1){
	    print $ANTIEXONSAMOUT "$line\n";
	    for (my $i=1; $i<$max_exon;$i++){
                if ($AexonFlag == $i){
                    $A_exon_outfile_cnt[$i]++;
                    print {$OUTFILE_EXON_A[$i]} "$line\n";
                }
            }
            if ($AexonFlag >= $max_exon){
		$A_exon_outfile_cnt[$max_exon]++;
		print {$OUTFILE_EXON_A[$max_exon]} "$line\n";
            }
	    if ($AintronFlag >= 1){
		$ex_int_a++; #antisense exon and antisense intron
	    }
	    else{
		$ex_only_a++; #antisense exon only
	    }
	}
    }
    #intron
    if (($print eq "true") && ($print_intron eq "true")){
        if ($intronFlag >= 1){
            print $INTRONSAMOUT "$line\n";
            for (my $i=1; $i<$max_intron;$i++){
                if ($intronFlag == $i){
		    $intron_outfile_cnt[$i]++;
                    print {$OUTFILE_INTRON[$i]} "$line\n";
                }
            }
            if ($intronFlag >= $max_intron){
		$intron_outfile_cnt[$max_intron]++;
                print {$OUTFILE_INTRON[$max_intron]} "$line\n";
            }
	    if ($exonFlag == 0){
		$int_only++; #intron only
	    }
        }
    }
    #antisense-intron
    if (($print eq "true") && ($print_intron_A eq "true")){
        if ($AintronFlag >= 1){
            print $ANTIINTRONSAMOUT "$line\n";
            for (my $i=1; $i<$max_intron;$i++){
                if ($AintronFlag == $i){
                    $A_intron_outfile_cnt[$i]++;
                    print {$OUTFILE_INTRON_A[$i]} "$line\n";
                }
            }
            if ($AintronFlag >= $max_intron){
                $A_intron_outfile_cnt[$max_intron]++;
                print {$OUTFILE_INTRON_A[$max_intron]} "$line\n";
            }
	    if ($AexonFlag == 0){
		$int_only_a++; #antisense-intron only
	    }
        }
    }
    if ($print eq "true"){
	if (($print_exon eq "true") && ($print_intron eq "true")&& ($print_exon_A eq "true")&& ($print_intron_A eq "true")){ # read doesn't map to high expressers
	    #exon_inconsistent reads
	    if (($intronFlag eq '0') && ($exonFlag eq '0') && ($igFlag eq '0') && ($AexonFlag eq '0') && ($AintronFlag eq "0")){
		print $EXON_INCONSISTENT "$line\n";
		$eiFlag++;
		$exon_inconsistent_outfile_cnt++;
		$ex_inc_only++; #exon-inconsistent-only
	    }
	    #intergenic region
	    if ($igFlag >= 1){           
		print $INTERGENIC "$line\n";
		$ig_outfile_cnt++;
		$ig_only++; #intergenic only
	    }
	}
    }
    #high exp reads
    if ($print eq "true"){
	foreach my $exon (keys %HIGHEXP_E){
	    if ($HIGHEXP_E{$exon} > 0){
                print {$OUT_HIGH_E{$exon}} "$line\n";
		$CNT_HIGH_E{$exon}++;
	    }
	}
        foreach my $exon (keys %HIGHEXP_E_A){
            if ($HIGHEXP_E_A{$exon} > 0){
                print {$OUT_HIGH_E_A{$exon}} "$line\n";
		$CNT_HIGH_E_A{$exon}++;
            }
	}
        foreach my $intron (keys %HIGHEXP_I){
            if ($HIGHEXP_I{$intron} > 0){
		print {$OUT_HIGH_I{$intron}} "$line\n";
		$CNT_HIGH_I{$intron}++;
            }
	}
	foreach my $intron (keys %HIGHEXP_I_A){
            if ($HIGHEXP_I_A{$intron} > 0){
                print {$OUT_HIGH_I_A{$intron}} "$line\n";
		$CNT_HIGH_I_A{$intron}++;
            }
        }
    }
    if ($exonFlag > $max_exon){
	$exonFlag = $max_exon;
    }
    if ($AexonFlag > $max_exon){
	$AexonFlag = $max_exon;
    }
    if ($intronFlag > $max_intron){
	$intronFlag = $max_intron;
    }
    if ($AintronFlag > $max_intron){
	$AintronFlag = $max_intron;
    }
    $EXON_FLAG_DIST[$exonFlag]++;
    $EXON_FLAG_DIST_ANTI[$AexonFlag]++;
    $INTRON_FLAG_DIST[$intronFlag]++;
    $INTRON_FLAG_DIST_ANTI[$AintronFlag]++;
=debug
    foreach my $exon (sort keys %EXONS){
	print "EXON:$exon; ";
    }

    foreach my $exon (sort keys %A_EXONS){
	print "anti_EXON:" . "$exon; ";
    }
    foreach my $int (sort keys %INTRONS){
	print "INTRON:$int; ";
    }

    foreach my $int (sort keys %A_INTRONS){
	print "anti_INTRON:" . "$int; ";
    }
    foreach my $ig (sort keys %IGS){
	print "IG:$ig; ";
    }
    print"\n";
=cut
}
close(SAM);

if ($print eq "true"){
    for (my $i=1;$i<=$max_exon;$i++){
	print LC "$exon_sam_outfile[$i]\t$exon_outfile_cnt[$i]\n";
	print {$OUTFILE_EXON[$i]} "line count = $exon_outfile_cnt[$i]\n";
	close($OUTFILE_EXON[$i]);
	if ($stranded eq "true"){
	    print LC_A "$anti_exon_sam_outfile[$i]\t$A_exon_outfile_cnt[$i]\n";
	    print {$OUTFILE_EXON_A[$i]} "line count = $A_exon_outfile_cnt[$i]\n";
	    close($OUTFILE_EXON_A[$i]);
	}
    }
    for (my $i=1;$i<=$max_intron;$i++){
        print LC "$intron_sam_outfile[$i]\t$intron_outfile_cnt[$i]\n";
        print {$OUTFILE_INTRON[$i]} "line count = $intron_outfile_cnt[$i]\n";
        close($OUTFILE_INTRON[$i]);
        if ($stranded eq "true"){
            print LC_A "$anti_intron_sam_outfile[$i]\t$A_intron_outfile_cnt[$i]\n";
            print {$OUTFILE_INTRON_A[$i]} "line count = $A_intron_outfile_cnt[$i]\n";
            close($OUTFILE_INTRON_A[$i]);
        }
    }
    print LC "$intergenic_sam_out\t$ig_outfile_cnt\n";
    print $INTERGENIC "line count = $ig_outfile_cnt\n";

    print LC "$exon_inconsistent_sam_out\t$exon_inconsistent_outfile_cnt\n";
    print $EXON_INCONSISTENT "line count = $exon_inconsistent_outfile_cnt\n";

    foreach my $exon (keys %HIGHEXP_E){
	print {$OUT_HIGH_E{$exon}} "line count = $CNT_HIGH_E{$exon}\n";
	print LC "$exon\t$CNT_HIGH_E{$exon}\n";
    }
    foreach my $exon (keys %HIGHEXP_E_A){
	print {$OUT_HIGH_E_A{$exon}} "line count = $CNT_HIGH_E_A{$exon}\n";
	print LC_A "$exon\t$CNT_HIGH_E_A{$exon}\n";
    }
    foreach my $intron (keys %HIGHEXP_I){
	print {$OUT_HIGH_I{$intron}} "line count = $CNT_HIGH_I{$intron}\n";
	print LC "$intron\t$CNT_HIGH_I{$intron}\n";
    }
    foreach my $intron (keys %HIGHEXP_I_A){
	print {$OUT_HIGH_I_A{$intron}} "line count = $CNT_HIGH_I_A{$intron}\n";
        print LC_A "$intron\t$CNT_HIGH_I_A{$intron}\n";
    }
    #stats
    open(STATS, ">$statsfile");
    if ($stranded eq "false"){ #not stranded
	print STATS "total-linecount-standard-chr\t$total_lc\nexon-only\t$ex_only\nintron-only\t$int_only\nexon-intron\t$ex_int\nintergenic-only\t$ig_only\nexon-inconsistent-only\t$ex_inc_only\n";
    }
    else{ #stranded
	print STATS "total-linecount-standard-chr\t$total_lc\nsense-exon-only\t$ex_only\nsense-intron-only\t$int_only\nsense-exon-intron\t$ex_int\nantisense-exon-only\t$ex_only_a\nantisense-intron-only\t$int_only_a\nantisense-exon-intron\t$ex_int_a\nintergenic-only\t$ig_only\nexon-inconsistent-only\t$ex_inc_only\n";
    }
    close(STATS);
}
#exonquants
if ($qexon eq "true"){
    open(OUT, ">$exonquants");
    print OUT "total number of reads which incremented at least one exon: $CNT_OF_FRAGS_WHICH_HIT_EXONS\n";
    print OUT "feature\tmin\tmax\n";
    print OUT "num exons dist:\n";
    for(my $i=0; $i<=$max_exon; $i++) {
	print OUT "$i\t$EXON_FLAG_DIST[$i]\n";
    }
    foreach my $exon (sort {&cmpChrs($a,$b)} keys %ML_E){
	my $maxcount = $exon_uniqueCOUNT{$exon} + $exon_nuCOUNT{$exon};
	print OUT "$exon\t$exon_uniqueCOUNT{$exon}\t$maxcount\n";
    }
    close(OUT);
}

#intronquants
if ($qintron eq "true"){
    open(OUT, ">$intronquants");
    print OUT "total number of reads which incremented at least one intron: $CNT_OF_FRAGS_WHICH_HIT_INTRONS\n";
    print OUT "feature\tmin\tmax\n";
    print OUT "num introns dist:\n";
    for(my $i=0; $i<=$max_intron; $i++) {
	print OUT "$i\t$INTRON_FLAG_DIST[$i]\n";
    }
    foreach my $intron (sort {&cmpChrs($a,$b)} keys %ML_I){
    my $maxcount = $intron_uniqueCOUNT{$intron} + $intron_nuCOUNT{$intron};
    print OUT "$intron\t$intron_uniqueCOUNT{$intron}\t$maxcount\n";
    }
    close(OUT);
}
if ($stranded eq "true"){
    if ($qexon eq "true"){
	open (OUTA, ">$exonquants_anti");
	print OUTA "total number of reads which incremented at least one exon: $CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI\n";
	print OUTA "feature\tmin\tmax\n";
	print OUTA "num exons dist:\n";
	for(my $i=0; $i<=$max_exon; $i++) {
	    print OUTA "$i\t$EXON_FLAG_DIST_ANTI[$i]\n";
	}
	foreach my $exon (sort {&cmpChrs($a,$b)} keys %ML_E_A){
	    my $maxcount = $exon_uniqueCOUNT_anti{$exon} + $exon_nuCOUNT_anti{$exon};
	    print OUTA "$exon\t$exon_uniqueCOUNT_anti{$exon}\t$maxcount\n";
	}
	close(OUTA);
    }
    
    if ($qintron eq "true"){
	open (OUTAI, ">$intronquants_anti");
	print OUTAI "total number of reads which incremented at least one intron: $CNT_OF_FRAGS_WHICH_HIT_INTRONS_ANTI\n";
	print OUTAI "feature\tmin\tmax\n";
	print OUTAI "num introns dist:\n";
	for(my $i=0; $i<=$max_intron; $i++) {
	    print OUTAI "$i\t$INTRON_FLAG_DIST_ANTI[$i]\n";
	}
	foreach my $intron (sort {&cmpChrs($a,$b)} keys %ML_I_A){
	    my $maxcount = $intron_uniqueCOUNT_anti{$intron} + $intron_nuCOUNT_anti{$intron};
	    print OUTAI "$intron\t$intron_uniqueCOUNT_anti{$intron}\t$maxcount\n";
	}
	close(OUTAI);
    }
}
if ($print eq "true"){
    close($EXONSAMOUT);
    close(LC);
    close($INTRONSAMOUT);
    close($INTERGENIC);
    if ($stranded eq "true"){
	close($ANTIEXONSAMOUT);
	close(LC_A);
	close($ANTIINTRONSAMOUT);
    }
}
print "got here\n";

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
sub cigar2spans {
    my ($start, $matchstring) = @_;
    my $spans = "";
    my $current_loc = $start;
    if($matchstring =~ /^(\d+)S/) {
        $matchstring =~ s/^(\d+)S//;
    }
    if($matchstring =~ /(\d+)S$/) {
        $matchstring =~ s/(\d+)S$//;
    }
    $matchstring =~ s/(\d+)I//g;
    while($matchstring =~ /(\d+)M(\d+)M/) {
        my $n1 = $1;
        my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "M" . $n2 . "M";
        my $str2 = $n . "M";
        $matchstring =~ s/$str1/$str2/;
    }
    while($matchstring =~ /(\d+)N(\d+)D/) {
        my $n1 = $1;
	my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "N" . $n2 . "D";
        my $str2 = $n . "N";
        $matchstring =~ s/$str1/$str2/;
    }
    while($matchstring =~ /(\d+)D(\d+)N/) {
        my $n1 = $1;
        my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "D" . $n2 . "N";
        my $str2 = $n . "N";
        $matchstring =~ s/$str1/$str2/;
    }
    if($matchstring =~ /D/) {
        while ($matchstring =~ /(\d+)M(\d+)D(\d+)M/){
	    my $l1 = $1;
	    my $l2 = $2;
	    my $l3 = $3;
	    my $L = $1 + $2 + $3;
	    $L = $L . "M";
	    $matchstring =~ s/\d+M\d+D\d+M/$L/;
	}
    }
    while($matchstring =~ /(\d+)M(\d+)M/) {
        my $n1 = $1;
        my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "M" . $n2 . "M";
        my $str2 = $n . "M";
        $matchstring =~ s/$str1/$str2/;
    }
    while($matchstring =~ /^(\d+)([^\d])/) {
        my $num = $1;
        my $type = $2;
        if($type eq 'M') {
            my $E = $current_loc + $num - 1;
            if($spans =~ /\S/) {
                $spans = $spans . ", " .  $current_loc . "-" . $E;
            } else {
                $spans = $current_loc . "-" . $E;
            }
            $current_loc = $E;
        }
        if($type eq 'D' || $type eq 'N') {
            $current_loc = $current_loc + $num + 1;
        }
        if($type eq 'I') {
            $current_loc++;
        }
        $matchstring =~ s/^\d+[^\d]//;
    }
    my $spans2 = "";
    while($spans2 ne $spans) {
        $spans2 = $spans;
        my @b = split(/, /, $spans);
        for(my $i=0; $i<@b-1; $i++) {
            my @c1 = split(/-/, $b[$i]);
            my @c2 = split(/-/, $b[$i+1]);
            if($c1[1] + 1 >= $c2[0]) {
                my $str = "-$c1[1], $c2[0]";
                $spans =~ s/$str//;
            }
        }
    }
    return $spans;
}

sub cmpChrs ($$) {
    my $a2_c = lc($_[1]);
    my $b2_c = lc($_[0]);
    if($a2_c eq 'finished1234') {
        return 1;
    }
    if($b2_c eq 'finished1234') {
        return -1;
    }
    if ($a2_c =~ /^\d+$/ && !($b2_c =~ /^\d+$/)) {
        return 1;
    }
    if ($b2_c =~ /^\d+$/ && !($a2_c =~ /^\d+$/)) {
        return -1;
    }
    if ($a2_c =~ /^[ivxym]+$/ && !($b2_c =~ /^[ivxym]+$/)) {
        return 1;
    }
    if ($b2_c =~ /^[ivxym]+$/ && !($a2_c =~ /^[ivxym]+$/)) {
        return -1;
    }
    if ($a2_c eq 'm' && ($b2_c eq 'y' || $b2_c eq 'x')) {
        return -1;
    }
    if ($b2_c eq 'm' && ($a2_c eq 'y' || $a2_c eq 'x')) {
        return 1;
    }
    if ($a2_c =~ /^[ivx]+$/ && $b2_c =~ /^[ivx]+$/) {
        $a2_c = "chr" . $a2_c;
        $b2_c = "chr" . $b2_c;
    }
    if ($a2_c =~ /$b2_c/) {
        return -1;
    }
    if ($b2_c =~ /$a2_c/) {
        return 1;
    }
    # dealing with roman numerals starts here
    if ($a2_c =~ /chr([ivx]+)/ && $b2_c =~ /chr([ivx]+)/) {
        $a2_c =~ /chr([ivx]+)/;
        my $a2_roman = $1;
        $b2_c =~ /chr([ivx]+)/;
        my $b2_roman = $1;
        my $a2_arabic = arabic($a2_roman);
        my $b2_arabic = arabic($b2_roman);
        if ($a2_arabic > $b2_arabic) {
            return -1;
        }
        if ($a2_arabic < $b2_arabic) {
            return 1;
        }
        if ($a2_arabic == $b2_arabic) {
            my $tempa = $a2_c;
            my $tempb = $b2_c;
            $tempa =~ s/chr([ivx]+)//;
            $tempb =~ s/chr([ivx]+)//;
            my %temphash;
            $temphash{$tempa}=1;
            $temphash{$tempb}=1;
            foreach my $tempkey (sort {&cmpChrs($a,$b)} keys %temphash) {
                if ($tempkey eq $tempa) {
                    return 1;
                } else {
                    return -1;
                }
            }
        }
    }
    if ($b2_c =~ /chr([ivx]+)/ && !($a2_c =~ /chr([a-z]+)/) && !($a2_c =~ /chr(\d+)/)) {
        return -1;
    }
    if ($a2_c =~ /chr([ivx]+)/ && !($b2_c =~ /chr([a-z]+)/) && !($b2_c =~ /chr(\d+)/)) {
        return 1;
    }

    if ($b2_c =~ /m$/ && $a2_c =~ /vi+/) {
        return 1;
    }
    if ($a2_c =~ /m$/ && $b2_c =~ /vi+/) {
        return -1;
    }

    # roman numerals ends here
    if ($a2_c =~ /chr(\d+)$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if ($b2_c =~ /chr(\d+)$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z])$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if ($b2_c =~ /chr([a-z])$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if ($a2_c =~ /chr(\d+)/) {
        my $numa = $1;
        if ($b2_c =~ /chr(\d+)/) {
            my $numb = $1;
            if ($numa < $numb) {
                return 1;
            }
            if ($numa > $numb) {
                return -1;
            }
            if ($numa == $numb) {
                my $tempa = $a2_c;
                my $tempb = $b2_c;
                $tempa =~ s/chr\d+//;
                $tempb =~ s/chr\d+//;
                my %temphash;
                $temphash{$tempa}=1;
                $temphash{$tempb}=1;
                foreach my $tempkey (sort {&cmpChrs($a,$b)} keys %temphash) {
                    if ($tempkey eq $tempa) {
                        return 1;
                    } else {
                        return -1;
                    }
                }
            }
        } else {
            return 1;
        }
    }
    if ($a2_c =~ /chrx(.*)/ && ($b2_c =~ /chr(y|m)$1/)) {
        return 1;
    }
    if ($b2_c =~ /chrx(.*)/ && ($a2_c =~ /chr(y|m)$1/)) {
        return -1;
    }
    if ($a2_c =~ /chry(.*)/ && ($b2_c =~ /chrm$1/)) {
        return 1;
    }
    if ($b2_c =~ /chry(.*)/ && ($a2_c =~ /chrm$1/)) {
        return -1;
    }
    if ($a2_c =~ /chr\d/ && !($b2_c =~ /chr[^\d]/)) {
        return 1;
    }
    if ($b2_c =~ /chr\d/ && !($a2_c =~ /chr[^\d]/)) {
        return -1;
    }
    if ($a2_c =~ /chr[^xy\d]/ && (($b2_c =~ /chrx/) || ($b2_c =~ /chry/))) {
        return -1;
    }
    if ($b2_c =~ /chr[^xy\d]/ && (($a2_c =~ /chrx/) || ($a2_c =~ /chry/))) {
        return 1;
    }
    if ($a2_c =~ /chr(\d+)/ && !($b2_c =~ /chr(\d+)/)) {
        return 1;
    }
    if ($b2_c =~ /chr(\d+)/ && !($a2_c =~ /chr(\d+)/)) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z])/ && !($b2_c =~ /chr(\d+)/) && !($b2_c =~ /chr[a-z]+/)) {
        return 1;
    }
    if ($b2_c =~ /chr([a-z])/ && !($a2_c =~ /chr(\d+)/) && !($a2_c =~ /chr[a-z]+/)) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z]+)/) {
        my $letter_a = $1;
        if ($b2_c =~ /chr([a-z]+)/) {
            my $letter_b = $1;
            if ($letter_a lt $letter_b) {
                return 1;
            }
            if ($letter_a gt $letter_b) {
                return -1;
            }
        } else {
            return -1;
        }
    }
    my $flag_c = 0;
    while ($flag_c == 0) {
        $flag_c = 1;
        if ($a2_c =~ /^([^\d]*)(\d+)/) {
            my $stem1_c = $1;
            my $num1_c = $2;
            if ($b2_c =~ /^([^\d]*)(\d+)/) {
                my $stem2_c = $1;
                my $num2_c = $2;
                if ($stem1_c eq $stem2_c && $num1_c < $num2_c) {
                    return 1;
                }
                if ($stem1_c eq $stem2_c && $num1_c > $num2_c) {
                    return -1;
                }
                if ($stem1_c eq $stem2_c && $num1_c == $num2_c) {
                    $a2_c =~ s/^$stem1_c$num1_c//;
                    $b2_c =~ s/^$stem2_c$num2_c//;
                    $flag_c = 0;
                }
            }
        }
    }
    if ($a2_c le $b2_c) {
        return 1;
    }
    if ($b2_c le $a2_c) {
        return -1;
    }


    return 1;
}
sub arabic($) {
    my $arg = shift;
    my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
    my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    my  @figure = reverse sort keys %roman_digit;
    $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
    isroman($arg) or return undef;
    my ($last_digit) = 1000;
    my $arabic=0;
    foreach (split(//, uc $arg)) {
	my ($digit) = $roman2arabic{$_};
	$arabic -= 2 * $last_digit if $last_digit < $digit;
	$arabic += ($last_digit = $digit);
    }
    $arabic;
}
sub isroman($) {
    my $arg = shift;
    return ($arg ne '' &&
	$arg =~ /^(?: M{0,3})
                 (?: D?C{0,3} | C[DM])
                 (?: L?X{0,3} | X[LC])
                 (?: V?I{0,3} | I[VX])$/ix);
}


# The *Starts and *Ends variables are references to arrays of starts and ends
# for one transcript and one read respectively. 
# Coordinates are assumed to be 1-based/right closed.
sub checkCompatibility {
    my ($txChr, $txStarts, $txEnds, $readChr, $readStarts, $readEnds) = @_;
    my $singleSegment  = scalar(@{$readStarts})==1 ? 1: 0;
    my $singleExon = scalar(@{$txStarts})==1 ? 1 : 0;
    # Check whether read overlaps transcript
    if ($txChr ne $readChr || $readEnds->[scalar(@{$readEnds})-1]<$txStarts->[0] || $readStarts->[0]>$txEnds->[scalar(@{$txEnds})-1]) {
	#print STDERR  "Read does not overlap transcript\n";
	return(0);
    }
  
    # Check whether read stradles transcript
    elsif (!$singleSegment) {
	my $stradle;
	for (my $i=0; $i<scalar(@{$readStarts})-1; $i++) {
	    if ($readEnds->[$i]<$txStarts->[0] && $readStarts->[$i+1]>$txEnds->[scalar(@{$txEnds})-1]) {
		$stradle = 1;
		last;
	    }
	}
	if ($stradle) {
	    #print STDERR  "Read stradles transcript\n";
	    return(0);
	}
	elsif ($singleExon) {
	    my $compatible;
	    $compatible = &compareSegments2($txStarts->[0], $txEnds->[0], $readStarts, $readEnds);
	    if ($compatible){
		return(1);
	    }
	    else{
		#print STDERR "HERE\n";
		return(0);
	    }
	}
	else {
	    my $readJunctions = &getJunctions($readStarts, $readEnds);
	    my $txJunctions = &getJunctions($txStarts, $txEnds);
	    my ($intronStarts, $intronEnds) = &getIntrons($txStarts, $txEnds);
	    my $intron = &overlaps($readStarts, $readEnds, $intronStarts, $intronEnds );
	    my $compatible = &compareJunctions($txJunctions, $readJunctions);
	    if (!$intron && $compatible) {
		#print STDERR "Read is compatible with transcript\n";
		return(1);
	    }
	    else{
		#print STDERR "Read overlaps intron(s) or is incompatible with junctions\n";
		return(0);
	    }
	}
    }
    else {
	my $intron = 0;
	if (!$singleExon) {
	    my ($intronStarts, $intronEnds) = &getIntrons($txStarts, $txEnds);
	    $intron = &overlaps($readStarts, $readEnds, $intronStarts, $intronEnds ); 
	}
	my $compatible = &compareSegments($txStarts, $txEnds, $readStarts->[0], $readEnds->[0]);
	if (!$intron && $compatible) {
	    #print STDERR "Read is compatible with transcript\n";
	    return(1);
	}
	else{
	    #print STDERR "Read overlaps intron(s) or is incompatible with junctions\n";
	    return(0);
	}
    }
}

sub getJunctions {
  my ($starts, $ends) = @_;
  my $junctions = "s: $ends->[0], e: $starts->[1]";
  for (my $i=1; $i<@{$ends}-1; $i++) {
    $junctions .= ", s: $ends->[$i], e: $starts->[$i+1]";
  }
  return($junctions);
}

sub getIntrons {
  my ($txStarts, $txEnds) = @_;
  my ($intronStarts, $intronEnds);
  for (my $i=0; $i<@{$txStarts}-1; $i++) {
    push(@{$intronStarts}, $txEnds->[$i]+1);
    push(@{$intronEnds}, $txStarts->[$i+1]-1);
  }
  return($intronStarts, $intronEnds);
}

sub overlaps {
  my ($starts1, $ends1, $starts2, $ends2) = @_;
  my $overlap = 0;

  if (!($ends1->[@{$ends1}-1]<$starts2->[0]) && !($ends2->[@{$ends2}-1]<$starts1->[0])) {
    for (my $i=0; $i<@{$starts1}; $i++) {
      for (my $j=0; $j<@{$starts2}; $j++) {
	if ($starts1->[$i]<$ends2->[$j] && $starts2->[$j]<$ends1->[$i]) {
	  $overlap =  1;
	  last;
	}
      }
    }
  }
  return($overlap);
}

sub compareJunctions {
  my ($txJunctions, $readJunctions) = @_;
  my $compatible = 0; 
  if (index($txJunctions, $readJunctions)!=-1) {
    $compatible = 1;
  } 
  return($compatible);
}

sub compareSegments {
  my ($txStarts, $txEnds, $readStart, $readEnd) = @_;
  my $compatible = 0;
  for (my $i=0; $i<scalar(@{$txStarts}); $i++) {
    if ($readStart>=$txStarts->[$i] && $readEnd<=$txEnds->[$i] ) {
      $compatible = 1;
      last;
    }
  }
  return($compatible);
}

sub compareSegments2 { #1exon case
    my ($exonStart, $exonEnd, $readStarts, $readEnds) = @_;
    my $compatible = 0;
    for (my $i=0; $i<scalar(@{$readStarts});$i++){
	if (((($i==0) && ($readStarts->[$i] >= $exonStart)) || (($i>0) && ($readStarts->[$i] == $exonStart))) && ((($i==scalar(@{$readStarts}-1)) && ($readEnds->[$i] <= $exonEnd)) || (($i<scalar(@{$readStarts}-1)) && ($readEnds->[$i] == $exonEnd)))){
	    $compatible = 1;
	}
    }
    return($compatible);
}

# The *Starts and *Ends variables are references to arrays of starts and ends
sub compareSegments_overlap {
    my ($exonChr, $readChr, $exonStart, $exonEnd, $readStarts, $readEnds) = @_;
    my $compatible = 0;
    if ($exonChr eq $readChr){
	for (my $i=0; $i<scalar(@{$readStarts});$i++){
	    if (($readEnds->[$i] >= $exonStart) && ($readStarts->[$i] <= $exonEnd)){ # if read overlaps exon
		$compatible = 1;
	    }
	}
    }
    return($compatible);
}
