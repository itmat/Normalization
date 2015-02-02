#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "perl cat_genes_files.pl <sample dirs> <loc> [options]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are


options:
 -stranded : set this if the data are strand-specific.

 -u  :  set this if you are using unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -nu  :  set this if you are using non-unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -norm : set this to get genes file for the gene-normalized sam files.

";

if (@ARGV<2){
    die $USAGE;
}

my $norm = "false";
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $stranded = "false";

for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq "-norm"){
	$norm = "true";
	$U = "false";
	$NU = "false";
	$option_found = "true";
    }
    if ($ARGV[$i] eq "-stranded"){
	$stranded = "true";
	$option_found = "true";
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
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot use both -u and -nu\n.
";
}

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $gnormdir = $study_dir . "NORMALIZED_DATA/GENE/FINAL_SAM";
open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my $genedir = "$LOC/$id/GNORM";
    my $filedir_u = "$genedir/Unique/";
    my $filedir_nu = "$genedir/NU/";
    my $filename_u = "$genedir/Unique/$id.filtered_u.sam";
    my $filename_nu = "$genedir/NU/$id.filtered_nu.sam";
    my $filedir = "$gnormdir/";
    my $filename = "$gnormdir/$id.gene.norm.sam";
    my ($filename_a, $filedir_a);
    if ($stranded eq "true"){
	$filedir = "$gnormdir/sense/";
	$filedir_a = "$gnormdir/antisense/";
	$filename = "$gnormdir/sense/$id.gene.norm.sam";
	$filename_a = "$gnormdir/antisense/$id.gene.norm.sam";
    }
    if ($U eq "true"){
	my $temp_prefix = "$filedir_u/sam2genes_temp.0";
	my $outfile = $filename_u;
	$outfile =~ s/.sam$/.txt/;
	if (-e $outfile){
	    `rm $outfile`;
	}
	my $infile0 = $temp_prefix . "0.txt";
	my $x = `cat $infile0 > $outfile`;
	for (my $i=1;$i<=5;$i++){
	    my $infile = $temp_prefix . "$i.txt";
	    if (-e $infile){
		$x = `cat $infile | grep -v readID >> $outfile`;
	    }
	}
    }
    if ($NU eq "true"){
        my $temp_prefix = "$filedir_nu/sam2genes_temp.0";
        my $outfile = $filename_nu;
        $outfile =~ s/.sam$/.txt/;
        if (-e $outfile){
            `rm $outfile`;
        }
	my $infile0 = $temp_prefix . "0.txt";
        my $x = `cat $infile0 > $outfile`;
        for (my $i=1;$i<=5;$i++){
            my $infile = $temp_prefix . "$i.txt";
	    if (-e $infile){
		$x = `cat $infile | grep -v readID >> $outfile`;
	    }
	}
    }
    if ($norm eq "true"){
	my $temp_prefix = "$filedir/$id.sam2genes_temp.0";
        my $outfile = $filename;
        $outfile =~ s/.sam$/.txt/;
        if (-e $outfile){
            `rm $outfile`;
        }
	my $infile0 = $temp_prefix . "0.txt";
        my $x = `cat $infile0 > $outfile`;
        for (my $i=1;$i<=5;$i++){
            my $infile = $temp_prefix . "$i.txt";
	    if (-e $infile){
		$x = `cat $infile | grep -v readID >> $outfile`;
	    }
	}
	if ($stranded eq "true"){
	    my $temp_prefix = "$filedir_a/$id.sam2genes_temp.0";
	    my $outfile = $filename_a;
	    $outfile =~ s/.sam$/.txt/;
	    if (-e $outfile){
		`rm $outfile`;
	    }
	    my $infile0 = $temp_prefix . "0.txt";
	    my $x = `cat $infile0 > $outfile`;
	    for (my $i=1;$i<=5;$i++){
		my $infile = $temp_prefix . "$i.txt";
		if (-e $infile){
		    $x = `cat $infile | grep -v readID >> $outfile`;
		}
	    }
	}
    }
}
close(IN);


print "got here\n";

