#!/usr/bin/env perl
use strict;


$| = 1;
if(@ARGV<3) {
    die "Usage: perl filter_sam_gnorm.pl <sam infile> <sam outfile> <more ids> [options]

where 
<sam infile> is input sam file (aligned sam) to be filtered 
<sam outfile> output sam file name (e.g. path/to/sampledirectory/sampleid.filtered.sam)
<more ids> ribosomalids file

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.
 
This will remove all rows from <sam infile> except those that satisfy all of the following:
1. Unique mapper / Non-Unique mapper
2. Both forward and reverse map consistently
3. id not in file <more ids>
4. chromosome is one of the numbered ones, or X, or Y

";
}

my $outfile = $ARGV[1];
my @fields = split("/", $outfile);
my $outname = $fields[@fields-1];
my $outfiledir = $outfile;
$outfiledir =~ s/\/$outname//;
my $outfileU = "$outfiledir/Unique/$outname";
$outfileU =~ s/.sam$/_u.sam/;
my $outfileNU = "$outfiledir/NU/$outname";
$outfileNU =~ s/.sam$/_nu.sam/;

my $NU = "true";
my $U = "true";
my $pe = "true";
my $numargs = 0;
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
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
unless (-d $outfiledir){
    `mkdir $outfiledir`;
}

if ($U eq "true"){
    unless(-d "$outfiledir/Unique"){
	`mkdir $outfiledir/Unique`;
    }
    open(OUTFILEU, ">$outfileU") or die "file '$outfileU' cannot open for writing\n"; # the output file
}
if ($NU eq "true"){
    unless(-d "$outfiledir/NU"){
        `mkdir $outfiledir/NU`;
    }
    open(OUTFILENU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing\n";
}

my $ribofile = $ARGV[2]; # file with id's that have the ribo reads
my %RIBO_IDs;
open(INFILE2, $ribofile) or die "file '$ribofile' cannot open for reading\n";
while(my $line = <INFILE2>) {
    chomp($line);
    $RIBO_IDs{$line} = 1;
}
close(INFILE2);

open(INFILE, $ARGV[0]) or die "file '$ARGV[0]' cannot open for reading\n";  # the sam file
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

open(INFILE, $ARGV[0]);  # the sam file
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
	    $len = -1 * (1 + length($reverse));
	    seek(INFILE, $len, 1);
	    next;
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
	if(!($F[2] =~ /^chr\d+$/ || $F[2] =~ /^chrX$/ || $F[2] =~ /^chrY$/ || $F[2] =~ /^\d+$/ || $F[2] eq 'Y' || $F[2] eq 'X')) {
	    next;
	}
	$id = $F[0];
	
	if(exists $RIBO_IDs{$id}) {
	    next;
	}
	my $Nf = "";
	my $Nr = "";
	$forward =~ /(N|I)H:i:(\d+)/;
	$Nf = $2;
	$reverse =~ /(N|I)H:i:(\d+)/;
	$Nr = $2;
	if($U eq "true") {
	    if($Nf == 1 && $Nr == 1 && $F[5] ne '*' && $R[5] ne '*') {
		print OUTFILEU "$forward\n";
		print OUTFILEU "$reverse\n";
		$cntU++;
	    }
	} 
	if($NU eq "true") {
	    if($Nf != 1 && $Nr != 1 && $F[5] ne '*' && $R[5] ne '*') {
		print OUTFILENU "$forward\n";
		print OUTFILENU "$reverse\n";
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
	if(!($F[2] =~ /^chr\d+$/ || $F[2] =~ /^chrX$/ || $F[2] =~ /^chrY$/ || $F[2] =~ /^\d+$/ || $F[2] eq 'Y' || $F[2] eq 'X')) {
	    next;
	}
	$id = $F[0];
	
	if(exists $RIBO_IDs{$id}) {
	    next;
	}
	my $Nf = "";
	$forward =~ /(N|I)H:i:(\d+)/;
        $Nf = $2;
	if($U eq "true") {
            if($Nf == 1  && $F[5] ne '*') {
                print OUTFILEU "$forward\n";
		$cntU++;
            }
        }
	if($NU eq "true") {
            if($Nf != 1 && $F[5] ne '*') {
                print OUTFILENU "$forward\n";
                $cntNU++;
            }
	}
    }
}
close(INFILE);
close(OUTFILEU);
close(OUTFILENU);

print "got here\n";
