#!/usr/bin/env perl
use strict;
use warnings;
if (@ARGV < 2){
    die "usage: perl cat_shuffiles.pl <sample id> <loc> [options]

where:
<sample id> is sample id (directory name)
<loc> is the path to the sample directories

option:
  -normdir <s>

  -stranded : set this if your data are strand-specific.

  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.
";
}


my $NU = "true";
my $U = "true";
my $numargs = 0;
my $stranded = "false";
my $normdir = "";
my $ncnt = 0;
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-normdir'){
	$option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$numargs++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}
if ($ncnt ne '1'){
    die "please specify -normdir path\n";
}
my $LOC = $ARGV[1];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $norm_dir = "$normdir/EXON_INTRON_JUNCTION/FINAL_SAM/";
unless (-d $norm_dir){
    `mkdir -p $norm_dir`;
}
my $norm_exon_dir = $norm_dir . "/exonmappers";
unless (-d $norm_exon_dir){
    `mkdir -p $norm_exon_dir`;
}

my $norm_intron_dir = $norm_dir . "/intronmappers";
unless (-d $norm_intron_dir){
    `mkdir -p $norm_intron_dir`;
}
my $norm_ig_dir = $norm_dir . "/intergenicmappers";
unless (-d $norm_ig_dir){
    `mkdir -p $norm_ig_dir`;
}
my $norm_und_dir = $norm_dir . "/exon_inconsistent";
unless (-d $norm_und_dir){
    `mkdir -p $norm_und_dir`;
}

my @g;
my $id = $ARGV[0];
chomp($id);
my $dir = $id;
my $current_LOC = "$LOC/$dir";
if ($stranded eq "false"){
    if ($numargs eq '0'){
	unless (-d "$current_LOC/EIJ/Unique/"){
	    die "Input directory $current_LOC/EIJ/Unique/ doesn't exist\n";
	}
	unless (-d "$current_LOC/EIJ/NU/"){
	    die "Input directory $current_LOC/EIJ/NU/ doesn't exist\n";
	}
	#exonmappers
	@g = glob("$current_LOC/EIJ/*/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intronmappers
	@g = glob("$current_LOC/EIJ/*/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intergenicmappers
	@g = glob("$current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam.gz > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam.gz does not exist\n";
	}
	#exon_inconsistent_reads
	@g = glob("$current_LOC/EIJ/*/$id.exon_inconsistent_reads.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/$id.exon_inconsistent_reads.norm_*.sam.gz > $norm_und_dir/$id.exon_inconsistent_reads.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/$id.exon_inconsistent_reads.norm_*.sam.gz does not exist\n";
	}
    }
    elsif ($U eq "true"){
	unless (-d "$current_LOC/EIJ/Unique/"){
            die "Input directory $current_LOC/EIJ/Unique/ doesn't exist\n";
	}
	#exonmappers
	@g = glob("$current_LOC/EIJ/Unique/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intronmappers
	@g = glob("$current_LOC/EIJ/Unique/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intergenicmappers
	@g = glob("$current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam.gz > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam.gz does not exist\n";
	}
	#exon_inconsistent_reads
	@g = glob("$current_LOC/EIJ/Unique/$id.exon_inconsistent_reads.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/$id.exon_inconsistent_reads.norm_*.sam.gz > $norm_und_dir/$id.exon_inconsistent_reads.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/$id.exon_inconsistent_reads.norm_*.sam.gz does not exist\n";
	}
	
    }
    elsif ($NU eq "true"){
	unless (-d "$current_LOC/EIJ/NU/"){
            die "Input directory $current_LOC/EIJ/NU/ doesn't exist\n";
	}
	#exonmappers
	@g = glob("$current_LOC/EIJ/NU/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intronmappers
	@g = glob("$current_LOC/EIJ/NU/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intergenicmappers
	@g = glob("$current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam.gz > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	}        
	else{
	    print "WARNING: $current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam.gz does not exist\n";
	}
	#exon_inconsistent_reads
	@g = glob("$current_LOC/EIJ/NU/$id.exon_inconsistent_reads.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/$id.exon_inconsistent_reads.norm_*.sam.gz > $norm_und_dir/$id.exon_inconsistent_reads.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/$id.exon_inconsistent_reads.norm_*.sam.gz does not exist\n";
	}
    }
}
if ($stranded eq "true"){
    unless (-d "$norm_exon_dir/sense"){
        `mkdir -p $norm_exon_dir/sense`;
    }
    unless (-d "$norm_exon_dir/antisense"){
        `mkdir -p $norm_exon_dir/antisense`;
    }
    unless (-d "$norm_intron_dir/sense"){
        `mkdir -p $norm_intron_dir/sense`;
    }
    unless (-d "$norm_intron_dir/antisense"){
        `mkdir -p $norm_intron_dir/antisense`;
    }
   if ($numargs eq "0"){
	unless (-d "$current_LOC/EIJ/Unique/sense/"){
	    die "Input directory $current_LOC/EIJ/Unique/sense/ doesn't exist\n";
	}
	unless (-d "$current_LOC/EIJ/NU/sense/"){
	    die "Input directory $current_LOC/EIJ/NU/sense/ doesn't exist\n";
	}
	unless (-d "$current_LOC/EIJ/Unique/antisense/"){
	    die "Input directory $current_LOC/EIJ/Unique/antisense/ doesn't exist\n";
	}
	unless (-d "$current_LOC/EIJ/NU/antisense/"){
	    die "Input directory $current_LOC/EIJ/NU/antisense/ doesn't exist\n";
	}
	#exonmappers
	@g = glob("$current_LOC/EIJ/*/sense/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/sense/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/sense/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/sense/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	@g = glob("$current_LOC/EIJ/*/antisense/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/antisense/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/antisense/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/antisense/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intronmappers
	@g = glob("$current_LOC/EIJ/*/sense/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/sense/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/sense/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/sense/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	@g = glob("$current_LOC/EIJ/*/antisense/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/antisense/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/antisense/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/antisense/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intergenicmappers
	@g = glob("$current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam.gz > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam.gz does not exist\n";
	}
	#exon_inconsistent_reads
	@g = glob("$current_LOC/EIJ/*/$id.exon_inconsistent_reads.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/*/$id.exon_inconsistent_reads.norm_*.sam.gz > $norm_und_dir/$id.exon_inconsistent_reads.norm.sam`;
	    }
	else{
	    print "WARNING: $current_LOC/EIJ/*/$id.exon_inconsistent_reads.norm_*.sam.gz does not exist\n";
	}
    }
    elsif($U eq "true"){
        unless (-d "$current_LOC/EIJ/Unique/sense/"){
            die "Input directory $current_LOC/EIJ/Unique/sense/ doesn't exist\n";
        }
        unless (-d "$current_LOC/EIJ/Unique/antisense/"){
            die "Input directory $current_LOC/EIJ/Unique/antisense/ doesn't exist\n";
	}
	#exonmappers
	@g = glob("$current_LOC/EIJ/Unique/sense/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/sense/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/sense/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/sense/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	@g = glob("$current_LOC/EIJ/Unique/antisense/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/antisense/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/antisense/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/antisense/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intronmappers
	@g = glob("$current_LOC/EIJ/Unique/sense/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/sense/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/sense/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/sense/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	@g = glob("$current_LOC/EIJ/Unique/antisense/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/antisense/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/antisense/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/antisense/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intergenicmappers
	@g = glob("$current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam.gz > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam.gz does not exist\n";
	}
	#exon_inconsistent_reads
	@g = glob("$current_LOC/EIJ/Unique/$id.exon_inconsistent_reads.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/Unique/$id.exon_inconsistent_reads.norm_*.sam.gz > $norm_und_dir/$id.exon_inconsistent_reads.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/Unique/$id.exon_inconsistent_reads.norm_*.sam.gz does not exist\n";
	}
    }
    elsif($NU eq "true"){
        unless (-d "$current_LOC/EIJ/NU/sense/"){
            die "Input directory $current_LOC/EIJ/NU/sense/ doesn't exist\n";
        }
        unless (-d "$current_LOC/EIJ/NU/antisense/"){
            die "Input directory $current_LOC/EIJ/NU/antisense/ doesn't exist\n";
        }
	#exonmappers
	@g = glob("$current_LOC/EIJ/NU/sense/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/sense/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/sense/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/sense/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	@g = glob("$current_LOC/EIJ/NU/antisense/$id.*_exonmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/antisense/$id.*_exonmappers.*_shuf_*.sam.gz > $norm_exon_dir/antisense/$id.exonmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/antisense/$id.*_exonmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intronmappers
	@g = glob("$current_LOC/EIJ/NU/sense/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/sense/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/sense/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/sense/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	@g = glob("$current_LOC/EIJ/NU/antisense/$id.*_intronmappers.*_shuf_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/antisense/$id.*_intronmappers.*_shuf_*.sam.gz > $norm_intron_dir/antisense/$id.intronmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/antisense/$id.*_intronmappers.*_shuf_*.sam.gz does not exist\n";
	}
	#intergenicmappers
	@g = glob("$current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam.gz > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam.gz does not exist\n";
	}
	#exon_inconsistent_reads
	@g = glob("$current_LOC/EIJ/NU/$id.exon_inconsistent_reads.norm_*.sam.gz");
	if (@g ne '0'){
	    `zcat $current_LOC/EIJ/NU/$id.exon_inconsistent_reads.norm_*.sam.gz > $norm_und_dir/$id.exon_inconsistent_reads.norm.sam`;
	}
	else{
	    print "WARNING: $current_LOC/EIJ/NU/$id.exon_inconsistent_reads.norm_*.sam.gz does not exist\n";
	}
    }
}

print "got here\n";
