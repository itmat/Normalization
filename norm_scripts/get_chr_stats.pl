#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: perl get_chr_stats.pl <sample dirs> <loc> [option]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are

options:
 -GENE: set this if you're running GENE normalization

 -EIJ: set this if you're running EXON-INTRON-JUNCTION normalization

";

if (@ARGV < 2){
    die $USAGE;
}

my $gnorm = "false";
my $eij = "false";
my $numargs = 0;
for(my $i=2;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-GENE'){
	$gnorm = "true";
	$numargs++;
    }
    if ($ARGV[$i] eq '-EIJ'){
	$eij = "true";
	$numargs++;
    }
}

if ($numargs ne '1'){
    die "you have to specify what type of normalization you're running. choose -GENE or -EIJ \n\n";
}


my $samples = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $statsdir = $study_dir . "/STATS/";
my $gstatsdir = $study_dir . "/STATS/GENE";
my $outfile;
if ($gnorm eq "true"){
    unless (-d $gstatsdir){
	my $make = `mkdir -p $gstatsdir`;
    }

    $outfile = $statsdir . "/percent_reads_chr_gene.txt";
}
if ($eij eq "true"){
    unless (-d $statsdir){
	my $make = `mkdir -p $statsdir`;
    }

    $outfile = $statsdir . "/percent_reads_chr_exon-intron-junction.txt";
}

my %CHR;
open(IN, $samples);
while (my $line = <IN>){
    chomp($line);
    my $file;
    if ($gnorm eq "true"){
	$file = "$LOC/$line/GNORM/Unique/$line.filtered_u.numchr_count.txt";
    }
    if ($eij eq "true"){
	$file = "$LOC/$line/EIJ/Unique/$line.filtered_u.numchr_count.txt";
    }
    open(FILE, $file);
    my $total = <FILE>;
    my $header = <FILE>;
    while(my $line2 = <FILE>){
	chomp($line2);
	my @c = split(/\t/, $line2);
	my $chr = $c[0];
	chomp($chr);
	$CHR{$chr} = 1;
    }
    close(FILE);
}
close(IN);

open(OUT, ">$outfile");
print OUT "sample\t";
foreach my $key (sort {cmpChrs($a,$b)} keys %CHR){
    print OUT "%".$key."\t";
}
print OUT "\n";

open(INFILE, $samples);
while(my $line = <INFILE>){
    chomp($line);
    my $file;
    print OUT "$line\t";
    if ($gnorm eq "true"){
        $file = "$LOC/$line/GNORM/Unique/$line.filtered_u.numchr_count.txt";
    }
    if ($eij eq "true"){
        $file = "$LOC/$line/EIJ/Unique/$line.filtered_u.numchr_count.txt";
    }
    foreach my $key (sort {cmpChrs($a,$b)} keys %CHR){
	my $find = `grep -w $key $file`;
	my $count = "0.00";
	if ($find !~ /^$/){
	    my @f = split(/\t/,$find);
	    $count = $f[2];
	    chomp($count);
	}
	print OUT "$count\t";
    }
    print OUT "\n";
}
close(OUT);
close(INFILE);

print "got here\n";

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
	    foreach my $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
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
		foreach my $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
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
	    1;
	}
	if ($b2_c le $a2_c) {
	    return -1;
	}


	return 1;
    }
}
