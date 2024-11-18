#!/usr/bin/env perl
use strict;
use warnings;

$| = 1;
if(@ARGV<3) {
    die "Usage: perl filter_sam_gnorm.pl <sam infile> <sam U outfile> <sam NU outfile> [options]

where 
<sam infile> is input sam file (aligned sam) to be filtered 
<sam U outfile> output sam file name (e.g. path/to/sampledirectory/sampleid.filtered.sam) for Unique reads
<sam NU outfile> output sam file name (e.g. path/to/sampledirectory/sampleid.filtered.sam) for non-unique reads

option:
  -chromnames <file> : a file of chromosome names

  -mito \"<name>, <name>, ... ,<name>\": name(s) of mitochondrial chromosomes

  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.
 
This will remove all rows from <sam infile> except those that satisfy all of the following:
1. Unique mapper / Non-Unique mapper
2. Both forward and reverse map consistently
3. a) Default: chromosome is one of the numbered ones, or X, or Y (e.g. chr1, chr2, chrX, chrY OR 1, 2, X, Y)
               and chromosome in -mito list.
   b) with -chromnames option: chromosome is listed in -chromnames <file>, chromosome in -mito list.

";
}

my $infile = $ARGV[0];
my $outfileU = $ARGV[1];
my $outfileNU = $ARGV[2];

my $NU = "true";
my $U = "true";
my $pe = "true";
my $numargs = 0;
my $use_chr_names = "false";
my $chromnames;
my %MITO;
my $count = 0;
my $samtools = "";
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-chromnames'){
	$option_found = "true";
	$chromnames = $ARGV[$i+1];
	$use_chr_names = "true";
	$i++;
    }
    if ($ARGV[$i] eq '-mito'){
        my $argv_all = $ARGV[$i+1];
        chomp($argv_all);
        unless ($argv_all =~ /^$/){
            $count=1;
        }
        $option_found = "true";
        my @a = split(",", $argv_all);
        for(my $i=0;$i<@a;$i++){
            my $name = $a[$i];
            chomp($name);
            $name =~ s/^\s+|\s+$//g;
            $MITO{$name}=1;
        }
        $i++;
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
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
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
my ($OUTFILEU, $OUTFILENU);
if ($U eq "true"){
    open($OUTFILEU, "| /bin/gzip -c > $outfileU") or die "file '$outfileU' cannot open for writing\n"; # the output file
}
if ($NU eq "true"){
    open($OUTFILENU, "| /bin/gzip -c > $outfileNU") or die "file '$outfileNU' cannot open for writing\n";
}


my %CHR_NAMES;
if ($use_chr_names eq "true"){
    if($count == 0){
	die "please provide mitochondrial chromosome name using -mito \"<name>\" option.\n";
    }
    open(CHR, $chromnames) or die "file '$chromnames' cannot open for reading\n";
    while(my $line = <CHR>){
	chomp($line);
	$line =~ s/^\s+|\s+$//g;
	$CHR_NAMES{$line} = 1;
    }
    close(CHR);
}

my $pipecmd = "samtools view $infile";
open(INFILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
my $cnt = 0;
my $line = <INFILE>;
my @a = split(/\t/,$line);
my $n = @a;
until($n > 8) {
    $line = <INFILE>;
    chomp($line);
    @a = split(/\t/,$line);
    $n = @a;
    $cnt++;
}
close(INFILE);
open(INFILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
for(my $i=0; $i<$cnt; $i++) { # skip header
    my $line = <INFILE>;
}
my $cntU = 0;
my $cntNU = 0;
my $id;
while(my $forward = <INFILE>) {
    my $len;
    if ($pe eq "true"){
	chomp($forward);
	if($forward eq '') {
	    my $forward = <INFILE>;
	    chomp($forward);
	}
	my $reverse = <INFILE>;
	chomp($reverse);
	if($reverse eq '') {
	    $reverse = <INFILE>;
	    chomp($reverse);
	}
	my @F = split(/\t/,$forward);
	my @R = split(/\t/,$reverse);
	my $id2 = $F[0];
	if($F[0] ne $R[0]) {
	    die "ERROR: I read two consecutive reads but the read ids were different.\nPaired End data -- mated alignments need to be in adjacent lines.\n$F[0]\n$R[0]\n\n";
=comment
	    $len = -1 * (1 + length($reverse));
	    seek(INFILE, $len, 1);
	    next;

=cut
	}
	if($R[1] & 64) {
	    my $temp = $forward;
	    $forward = $reverse;
	    $reverse = $temp;
	    @F = split(/\t/,$forward);
	    @R = split(/\t/,$reverse);
	    if($R[1] & 64) {
		print "Warning: I read two reads consecutive but neither were a reverse read...\n\nforward=$forward\n\nreverse=$reverse\n\nPrevious was id='$id'\n\nI am skipping read '$id2'.\n\n";
		my $line = <INFILE>;
		chomp($line);
		my @a = split(/\t/,$line);
		while($a[0] eq $id2) {
		    $line = <INFILE>;
		    chomp($line);
		    @a = split(/\t/,$line);
		}
		$len = -1 * (1 + length($line));
		seek(INFILE, $len, 1);
		next;
	    }
	}
	if ($use_chr_names eq "false"){
	    if(!($F[2] =~ /^chr\d+$/ || $F[2] =~ /^chrX$/ || $F[2] =~ /^chrY$/ || $F[2] =~ /^\d+$/ || $F[2] eq 'Y' || $F[2] eq 'X')) {
                my $flag = 0;
                foreach my $mito (keys %MITO){
                    if ($F[2] eq $mito){
                        $flag++;
                    }
                }
                if ($flag == 0){
                    next;
                }
	    }
	}
	if ($use_chr_names eq "true"){
	    unless (exists $CHR_NAMES{$F[2]}){
                my $flag = 0;
                foreach my $mito (keys %MITO){
                    if ($F[2] eq $mito){
                        $flag++;
                    }
                }
                if ($flag == 0){
                    next;
                }
	    }
	}
=comment
	if (exists $MITO{$F[2]}){
	    next;
	}
=cut
	$id = $F[0];
	
	my $Nf = "";
	my $Nr = "";
	$forward =~ /(N|I)H:i:(\d+)/;
	$Nf = $2;
	$reverse =~ /(N|I)H:i:(\d+)/;
	$Nr = $2;
	if($U eq "true") {
	    if($Nf == 1 && $Nr == 1 && $F[5] ne '*' && $R[5] ne '*') {
		print $OUTFILEU "$forward\n";
		print $OUTFILEU "$reverse\n";
		$cntU++;
	    }
	} 
	if($NU eq "true") {
	    if($Nf != 1 && $Nr != 1 && $F[5] ne '*' && $R[5] ne '*') {
		print $OUTFILENU "$forward\n";
		print $OUTFILENU "$reverse\n";
		$cntNU++;
	    }
	}
    }
    else{
	chomp($forward);
	if($forward eq '') {
            $forward = <INFILE>;
            chomp($forward);
        }
	my @F = split(/\t/,$forward);
	if ($use_chr_names eq "false"){
            if(!($F[2] =~ /^chr\d+$/ || $F[2] =~ /^chrX$/ || $F[2] =~ /^chrY$/ || $F[2] =~ /^\d+$/ || $F[2] eq 'Y' || $F[2] eq 'X')) {
                my $flag = 0;
                foreach my $mito (keys %MITO){
                    if ($F[2] eq $mito){
                        $flag++;
                    }
                }
                if ($flag == 0){
                    next;
                }
            }
	}
        if ($use_chr_names eq "true"){
	    unless (exists $CHR_NAMES{$F[2]}){
                my $flag = 0;
                foreach my $mito (keys %MITO){
                    if ($F[2] eq $mito){
                        $flag++;
                    }
                }
                if ($flag == 0){
                    next;
                }
            }
	}
=comment
	if (exists $MITO{$F[2]}){
	    next;
	}
=cut
	$id = $F[0];
	
	my $Nf = "";
	$forward =~ /(N|I)H:i:(\d+)/;
        $Nf = $2;
	if($U eq "true") {
            if($Nf == 1  && $F[5] ne '*') {
                print $OUTFILEU "$forward\n";
		$cntU++;
            }
        }
	if($NU eq "true") {
            if($Nf != 1 && $F[5] ne '*') {
                print $OUTFILENU "$forward\n";
                $cntNU++;
            }
	}
    }
}
close(INFILE);
if ($U eq "true"){
    close($OUTFILEU);
}
if ($NU eq "true"){
    close($OUTFILENU);
}
