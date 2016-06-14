#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<3) {
    die "usage: perl cat_gnorm_Unique_NU.pl <sample id> <loc> <samfilename> [option]

where:
<sample id> is sample id (directory name)
<loc> is the path to the sample directories
<samfilename> 

option:
 -filter_highexp

 -normdir <s> 

 -stranded: set this if your data are strand-specific.

 -u  :  set this if you want to return only unique mappers, otherwise by default
        it will return both unique and non-unique mappers.

 -nu :  set this if you want to return only non-unique mappers, otherwise by default
        it will return both unique and non-unique mappers.

 -bam <samtools> : bam input


";
}
my $NU = "true";
my $U = "true";
my $numargs = 0;
my $stranded = "false";
my $bam = "false";
my $samtools = "";
my $normdir = "";
my $ncnt = 0;
my $filter = "false";
for(my$i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-filter_highexp'){
	$filter = "true";
	$option_found = "true";
    }
    if($ARGV[$i] eq '-stranded') {
	$option_found = "true";
	$stranded = "true";
    }
    if($ARGV[$i] eq '-normdir') {
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
    if ($ARGV[$i] eq "-bam"){
	$bam = "true";
	$samtools = $ARGV[$i+1];
	$option_found = "true";
	$i++;
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
my $samfilename = $ARGV[2];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $gnorm_dir = "$normdir/GENE/FINAL_SAM/";
unless (-d $gnorm_dir){
    `mkdir -p $gnorm_dir`;
}
my $sense_dir = $gnorm_dir . "/sense/";
my $antisense_dir = $gnorm_dir . "/antisense/";
if ($stranded eq "true"){
    unless (-d $sense_dir){
	`mkdir -p $sense_dir`;
    }
    unless (-d $antisense_dir){
	`mkdir -p $antisense_dir`;
    }
}
my $hefile = "$LOC/high_expressers_gene.txt";
my $hefile_a = ""; 
if ($stranded eq "true"){
    $hefile = "$LOC/high_expressers_gene_sense.txt";
    $hefile_a = "$LOC/high_expressers_gene_antisense.txt";
}
my (%HE, %HE_A);
if ($filter eq "true"){
    open(IN, $hefile) or die "cannot find $hefile\n";
    while(my $line = <IN>){
	chomp($line);
	$HE{$line} = 1;
    }
    close(IN);
    if ($stranded eq "true"){
	open(IN, $hefile_a) or die "cannot find $hefile_a\n";
	while(my $line = <IN>){
	    chomp($line);
	    $HE_A{$line}=1;
	}
	close(IN);
    }
}
my $id = $ARGV[0];
chomp($id);
my $original = "$LOC/$id/$samfilename";
my $header = "";
if ($bam eq "true"){
    $header = `$samtools view -H $original`;
}
else{
    $header = `grep ^@ $original`;
}
if ($stranded eq "false"){
    my @a = glob("$LOC/$id/GNORM/*/*.filtered_*u.genes.norm.sam");
    my $string = "";
    foreach my $file (@a){
	$string .= "$file\t";
    }
    foreach my $key (keys %HE){
	my @b = glob("$LOC/$id/GNORM/*/*$key.norm.sam");
	foreach my $file (@b){
	    $string .= "$file\t";
	}
    }
    my $outfile = "$gnorm_dir/$id.gene.norm.sam";
    open (OUT, ">$outfile");
    print OUT $header;
    close(OUT);
    my $x = `cat $string >> $outfile`;
}
if ($stranded eq "true"){
    my @s = glob("$LOC/$id/GNORM/*/*.filtered_*u.genes.sense.norm.sam");
    my $string_s = "";
    foreach my $file (@s){
        $string_s .= "$file\t";
    }
    foreach my $key (keys %HE){
        my @b = glob("$LOC/$id/GNORM/*/*$key.sense.norm.sam");
	foreach my $file (@b){
            $string_s .= "$file\t";
        }
    }
    my @a = glob("$LOC/$id/GNORM/*/*.filtered_*u.genes.antisense.norm.sam");
    my $string_a = "";
    foreach my $file (@a){
        $string_a .= "$file\t";
    }
    foreach my $key (keys %HE_A){
        my @b = glob("$LOC/$id/GNORM/*/*$key.antisense.norm.sam");
        foreach my $file (@b){
            $string_a .= "$file\t";
	}
    }
    my $outfile = "$sense_dir/$id.gene.norm.sam";
    my $outfile_a = "$antisense_dir/$id.gene.norm.sam";
    open (OUT, ">$outfile");
    print OUT $header;
    close(OUT);
    open (OUT_A, ">$outfile_a");
    print OUT_A $header;
    close(OUT_A);
    `cat $string_s >> $outfile`;
    `cat $string_a >> $outfile_a`;
}
print "got here\n";
