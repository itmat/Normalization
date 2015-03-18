#!/usr/bin/env perl
use warnings;
use strict;
$| = 1;
if(@ARGV<6) {
    die "Usage: perl filter_and_resolve.pl <sam infile> <exons file> <introns file> <intergenic regions file> <ribo ids> <sam outfile> [options]

where 
<sam infile> is input sam file (aligned sam) to be filtered 
<exons file> master list of exons file (full path)
<introns file> master list of introns file (full path)
<intergenic regions file> master list of intergenic regions file (full path)
<ribo ids> ribosomalids file
<sam outfile> output sam file name (e.g. path/to/sampledirectory/sampleid.filtered.sam)

option:
  -str_f : if forward read is in the same orientation as the transcripts/genes.
  -str_r : if reverse read is in the same orientation as the transcripts/genes.
  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.
 
This will remove all rows from <sam infile> except those that satisfy all of the following:
1. Both forward and reverse map consistently
2. chromosome is one of the numbered ones, or X, or Y
3. Is a forward mapper (script outputs forward mappers only)
4. id not in file <ribo ids>
5. Unique and Non-Unique mappers (after resolving non-unique mappers)

Also, this script will resolve the multimappers.

";
}

my $pe = "true";
my $FWD = "false";
my $REV = "false";
my $numargs = 0;
my $stranded = "false";
for(my $i=6; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
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
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($stranded eq "true"){
    if($numargs ne '1') {
        die "You can only use one of the options \"-str_f\" or \"-str_r\".\n";
    }
}
my $samfile = $ARGV[0];
my $outfile = $ARGV[5];
my @fields = split("/", $outfile);
my $outname = $fields[@fields-1];
my $outfiledir = $outfile;
$outfiledir =~ s/\/$outname//;
my $outdir = $outfiledir . "/EIJ/";
my $outfileU = "$outdir/Unique/$outname";
$outfileU =~ s/.sam$/_u.sam/;
my $outfileNU = "$outdir/NU/$outname";
$outfileNU =~ s/.sam$/_nu.sam/;
unless (-d "$outdir/Unique"){
    `mkdir -p $outdir/Unique`;
}
unless (-d "$outdir/NU"){
    `mkdir -p $outdir/NU`;
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

my %RIBO_IDs;
my $ribofile = $ARGV[4]; # file with id's that have the ribo reads
open(RIBO, $ribofile) or die "file '$ribofile' cannot open for reading\n";
while(my $line = <RIBO>) {
    chomp($line);
    $RIBO_IDs{$line} = 1;
}
close(RIBO);

my $CNT_OF_FRAGS_WHICH_HIT_EXONS = 0;
my $CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI = 0;
my $CNT_OF_FRAGS_WHICH_HIT_INTRONS = 0;
my $CNT_OF_FRAGS_WHICH_HIT_INTRONS_ANTI = 0;
my $ig_outfile_cnt = 0;
my $undetermined_outfile_cnt = 0;

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

my %NU;
my (%EXON, %INTRON, %IG, %EXON_A, %INTRON_A);
open(INFILE, $ARGV[0]);  # the sam file
open(OUT, ">$outfile");
for(my $i=0; $i<$cnt; $i++) { # skip header
    $line = <INFILE>;
}
while(my $forward = <INFILE>) {
    my $alignment = "";
    my $Nf = "";
    if ($pe eq "true"){
	chomp($forward);
	if($forward eq '') {
	    $forward = <INFILE>;
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
	    my $len = -1 * (1 + length($reverse));
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
		print "Warning: I read two reads consecutive but neither were a reverse read...\n\n"; #forward=$forward\n\nreverse=$reverse\n\nPrevious was id='$id'\n\nI am skipping read '$id2'.\n\n";
		$line = <INFILE>;
		chomp($line);
		my @a = split(/\t/,$line);
		while($a[0] eq $id2) {
		    $line = <INFILE>;
		    chomp($line);
		    @a = split(/\t/,$line);
		}
		my $len = -1 * (1 + length($line));
		seek(INFILE, $len, 1);
		next;
	    }
	}
	if(!($F[2] =~ /^chr\d+$/ || $F[2] =~ /^chrX$/ || $F[2] =~ /^chrY$/ || $F[2] =~ /^\d+$/ || $F[2] eq 'Y' || $F[2] eq 'X')) {
	    next;
	}
	my $id = $F[0];
	if (exists $RIBO_IDs{$id}) {
	    next;
	}
	my $Nr = "";
	$forward =~ /(N|I)H:i:(\d+)/;
	$Nf = $2;
	$reverse =~ /(N|I)H:i:(\d+)/;
	$Nr = $2;
	if($F[5] ne '*' && $R[5] ne '*') {
	    $alignment = $forward;
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
	my $id = $F[0];
	if(exists $RIBO_IDs{$id}) {
	    next;
	}
	my $Nf = "";
	$forward =~ /(N|I)H:i:(\d+)/;
        $Nf = $2;
	if($F[5] ne '*') {
	    $alignment = $forward;
        }
    }
    if ($Nf == 1){ #unique
	print OUT "$alignment\n";
    }
    elsif ($Nf > 1){ #multimapper
	unless ($alignment =~ /^$/){
	    my @a = split(/\t/, $alignment);
	    my $read_id = $a[0];
	    my $bitflag = $a[1];
	    my $chr = $a[2];
	    my $readSt = $a[3];
	    my $cigar = $a[5];
	    $NU{$read_id} = 1;

	    my $sense = "false";
	    my $exonFlag = 0;
	    my $AexonFlag = 0;
	    my $intronFlag = 0;
	    my $AintronFlag = 0;
	    my $igFlag = 0;
    
	    my @readStarts = ();
	    my @readEnds = ();

	    while ($cigar =~ /(\d+)M(\d+)D(\d+)M/){
		my $N = $1+$2+$3;
		my $str = $1 . "M" . $2 . "D" . $3 . "M";
		my $new_str = $N . "M";
		$cigar =~ s/$str/$new_str/;
	    }
	    my $spans = &cigar2spans($readSt, $cigar);
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
	    if ($stranded eq "true"){
		for(my $i=0;$i<@b;$i++){
		    $b[$i] =~ /(\d+)-(\d+)/;
		    my $read_segment_start = $1;
		    my $read_segment_end = $2;
		    my $read_segment_start_block = int($read_segment_start / 1000);
		    my $read_segment_end_block = int($read_segment_end / 1000);
		    for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
			# if stranded, check read orientation using exon
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
		$b[$i] =~ /(\d+)-(\d+)/;
		my $read_segment_start = $1;
		my $read_segment_end = $2;
		my $read_segment_start_block = int($read_segment_start / 1000);
		my $read_segment_end_block = int($read_segment_end / 1000);
		for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
		    # check if read span maps to exon
		    if (exists $exonHASH{$chr}[$index]){
			my $hashsize = @{$exonHASH{$chr}[$index]};
			for (my $j=0; $j<$hashsize; $j++){
			    my $exon = $exonHASH{$chr}[$index][$j];
			    my $check = &checkCompatibility($chr, $exSTART{$exon}, $exEND{$exon}, $chr, \@readStarts, \@readEnds);
			    my $check_anti = &compareSegments_overlap($chr, $chr, $exSTART{$exon}->[0], $exEND{$exon}->[0], \@readStarts, \@readEnds);
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
				    if ($read_strand eq $exonSTR{$exon}){ #sense
					if (!(defined $doneEXON{$exon})){
					    $exonFlag++;
					    if($exonFlag == 1) {
						$CNT_OF_FRAGS_WHICH_HIT_EXONS++;
					    }
					}
					$doneEXON{$exon} = 1;
				    }
				    elsif ($sense eq "false"){ # antisense
					if (!(defined $doneEXON_ANTI{$exon})){
					    $AexonFlag++;
					    if ($AexonFlag == 1){
						$CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI++;
					    }
					}
					$doneEXON_ANTI{$exon}=1;
				    }
				}
				if (($sense eq "false") && ($check_anti eq "1") && ($read_strand ne $exonSTR{$exon})){ # antisense
				    if (!(defined $doneEXON_ANTI{$exon})){
					$AexonFlag++;
					if ($AexonFlag == 1){
					    $CNT_OF_FRAGS_WHICH_HIT_EXONS_ANTI++;
					}
				    }
				    $doneEXON_ANTI{$exon}=1;
				}
			    }
			    if ($stranded eq "false"){
				if ($check eq "1"){
				    if (!(defined $doneEXON{$exon})){
					$exonFlag++;
					if($exonFlag == 1) {
					    $CNT_OF_FRAGS_WHICH_HIT_EXONS++;
					}
				    }
				    $doneEXON{$exon}=1;
				}
			    }
			}
		    }
		    # check if read span maps to intergenic region
		    if (exists $igHASH{$chr}[$index]){
			my $hashsize = @{$igHASH{$chr}[$index]};
			for (my $j=0;$j<$hashsize;$j++){
			    my $interg = $igHASH{$chr}[$index][$j];
			    my $check = &compareSegments_overlap($chr,$chr,$igSTART{$interg}->[0], $igEND{$interg}->[0], \@readStarts, \@readEnds);
			    if ($check eq "1"){
				if (!(defined $doneIG{$interg})){
				    $igFlag++;
				}
				$doneIG{$interg}=1;
			    }
			}
		    }
		    # check if read span maps to introns
		    if (exists $intronHASH{$chr}[$index]){
			my $hashsize = @{$intronHASH{$chr}[$index]};
			for (my $j=0; $j<$hashsize; $j++){
			    my $intron = $intronHASH{$chr}[$index][$j];
			    my $check = &compareSegments_overlap($chr, $chr, $intSTART{$intron}->[0], $intEND{$intron}->[0], \@readStarts, \@readEnds);
			    if ($stranded eq "false"){
				if ($check eq "1"){
				    if (!(defined $doneINTRON{$intron})){
					$intronFlag++;
					if($intronFlag == 1) {
					    $CNT_OF_FRAGS_WHICH_HIT_INTRONS++;
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
						$intronFlag++;
						if($intronFlag == 1) {
						    $CNT_OF_FRAGS_WHICH_HIT_INTRONS++;
						}
					    }
					    $doneINTRON{$intron} = 1;
					}
				    }
				    elsif ($sense eq "false"){ #antisense
					if (!(defined $doneINTRON_ANTI{$intron})){
					    $AintronFlag++;
					    if($AintronFlag == 1) {
						$CNT_OF_FRAGS_WHICH_HIT_INTRONS_ANTI++;
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
	    print OUT "$alignment\t";
	    #exon
	    print OUT "EX:";
	    if ($exonFlag >= 1){
		print OUT "1\t";
		$EXON{$read_id}++;
	    }
	    else{
		print OUT "0\t";
	    }
	    #intron
	    print OUT "INT:";
	    if ($intronFlag >= 1){
		print OUT "1\t";
		$INTRON{$read_id}++;
	    }
	    else{
		print OUT "0\t";
	    }
	    #intergenic region
	    print OUT "IG:";
	    if ($igFlag >=1){
		print OUT "1\t";
		$IG{$read_id}++;
	    }
	    else{
		print OUT "0\t";
	    }
	    if ($stranded eq "true"){
		#antiexon
		print OUT "EX_A:";
		if ($AexonFlag >= 1){
		    print OUT "1\t";
		    $EXON_A{$read_id}++;
		}
		else{
		    print OUT "0\t";
		}
		#antiintron
		print OUT "INT_A:";
		if ($AintronFlag >= 1){
		    print OUT "1\t";
		    $INTRON_A{$read_id}++;
		}
		else{
		    print OUT "0\t";
		}
	    }
	}
	print OUT "\n";
    }
}
close(INFILE);
close(OUT);

foreach my $read (keys %NU){
    unless (defined $EXON{$read}){
        $EXON{$read} = 0;
    }
    unless (defined $INTRON{$read}){
        $INTRON{$read} = 0;
    }
    if ($stranded eq "true"){
	unless (defined $EXON_A{$read}){
	    $EXON_A{$read} = 0;
	}
	unless (defined $INTRON_A{$read}){
	    $INTRON_A{$read} = 0;
	}
    }
    unless (defined $IG{$read}){
        $IG{$read} = 0;
    }
}


open(IN, $outfile); # read filtered file (forward only no ribo ids, only numbered chr and x,y,z)
open(UNIQUE, ">$outfileU") or die "file '$outfileU' cannot open for writing\n"; # the outputU file
open(NU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing\n"; # the outputNU file
while(my $line = <IN>){
    if ($line =~ /^@/){
	next;
    }
    chomp($line);
    my @a = split(/\t/, $line);
    my $id = $a[0];
    my $ih_tag = 0;
    my $i_or_h = "";
    if ($line =~ /(N|I)H:i:(\d+)/){
        $line =~ /(N|I)H:i:(\d+)/;
        $i_or_h = $1;
        $ih_tag = $2;
    }
    my $original_ih = "$i_or_h" . "H:i:$ih_tag";
    my $new_ih = "$i_or_h" . "H:i:1";
    my $hi_tag = 0;
    if ($line =~ /HI:i:(\d+)/){
        $hi_tag = $1;
    }
    my $original_hi = "HI:i:$hi_tag";
    if ($ih_tag == 1){ #unique mapper (determined from alignment (N|I)H tag)
	$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+\s+EX_A:\d+\s+INT_A:\d+//;
	$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+//;
        print UNIQUE "$line\n";
    }
    else{ #resolve non-unique mapper here
        if ($EXON{$id} == 1){ # case 1 - 1 alignment sense exons/exons (only keep the alignment that maps to sense exons/exons)
            if ($line =~ /EX:1\t/){ # fix tag to unique
                $line =~ s/$original_ih/$new_ih/;
                $line =~ s/$original_hi/HI:i:1/;
		$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+\s+EX_A:\d+\s+INT_A:\d+//;
		$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+//;
                print UNIQUE "$line\n";
            }
=debug
            else{
		print "$line\n";
            }
=cut
        }
        elsif ($EXON{$id} > 1){ # case 2 - multiple sense exon/exons
            if ($line =~ /EX:1\t/){ # keep only alignments that map to sense exons/exons - non-unique
		$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+\s+EX_A:\d+\s+INT_A:\d+//;
		$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+//;
                print NU "$line\n";
            }
=debug
            else{ 
                print "$line\n";
            }
=cut
        }
        else{ # case 3 - no sense exon
            if ($INTRON{$id} == 1){ # case 3a - 1 sense intron/intron (only keep the alignment that maps to sense intron/intron)
                if ($line =~ /INT:1\t/){ # fix tag to unique
                    $line =~ s/$original_ih/$new_ih/;
                    $line =~ s/$original_hi/HI:i:1/;
		    $line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+\s+EX_A:\d+\s+INT_A:\d+//;
		    $line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+//;
                    print UNIQUE "$line\n";
                }
=debug
                else{ 
                    print "$line\n";
                }
=cut
            }
            elsif($INTRON{$id} > 1){ # case 3b - multiple sense intron / intron
                if ($line =~ /INT:1\t/){ #keep only alignments that map to sense intron /intron - non-unique
		    $line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+\s+EX_A:\d+\s+INT_A:\d+//;
		    $line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+//;
                    print NU "$line\n";
                }
=debug
                else{ 
                    print "$line\n";
                }
=cut
            }
            else{ # case 3c - no sense intron / intron
		$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+\s+EX_A:\d+\s+INT_A:\d+//;
		$line =~ s/EX:\d+\s+INT:\d+\s+IG:\d+//;
                print NU "$line\n"; #keep all alignments
=debug
		print "$line\n"; 
=cut
            }
        }
    }
}

close(IN);
close(UNIQUE);
close(NU);

print "got here\n";
`rm $outfile`;
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
    if($matchstring =~ /D/) {
        $matchstring =~ /(\d+)M(\d+)D(\d+)M/;
        my $l1 = $1;
        my $l2 = $2;
        my $l3 = $3;
        my $L = $1 + $2 + $3;
        $L = $L . "M";
        $matchstring =~ s/\d+M\d+D\d+M/$L/;

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
    return $arg ne '' and
        $arg =~ /^(?: M{0,3})
                 (?: D?C{0,3} | C[DM])
                 (?: L?X{0,3} | X[LC])
                 (?: V?I{0,3} | I[VX])$/ix;
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
