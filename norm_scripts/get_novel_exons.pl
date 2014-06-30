#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
if(@ARGV<2) {
    die "Usage: perl get_novel_exons.pl <junctions_all.rum file> <output file>[options]

where
<junctions_all.rum file> input junctions file (needs to be sorted by id)
<output file> output file (full path)

options: -min <n> : min is set at 10 by default
        
         -max <n> : max is set at 1200 by default

";
}

my $min = 10;
my $max = 1200;
my %EXON_START;
my %INF_EXONS;
my $current_n = "1";
my $outfile = $ARGV[1];

for(my $i=2; $i<@ARGV; $i++) {
    my $argument_recognized = 0;
    if($ARGV[$i] eq '-min') {
	$min = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-max') {
	$max = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($argument_recognized == 0) {
	die "ERROR: command line arugument '$ARGV[$i]' not recognized.\n";
    }
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
my $line = <INFILE>;
while($line = <INFILE>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $intron = $a[0];
    my $score = $a[2];
    (my $int_chr, my $int_start, my $int_end) = $intron =~  /^(.*):(\d*)-(\d*)$/g;
    my $ex_end = $int_start - 1;
    my $ex_start = $int_end + 1;
    my $chr_n = $int_chr;
    $chr_n =~ s/chr//;
    #empty %EXON_START hash for new chr
    if ($current_n ne $chr_n){
	for (keys %EXON_START){
	    delete $EXON_START{$_};
	}
    }
    if ($score >= 5){
	foreach my $exon_start (keys %EXON_START){
	    my $ex_start_score = $EXON_START{$exon_start};
	    my $ex_end_score = $score;
	    my @SCORE = ($ex_start_score, $ex_end_score);
	    my $diff = $ex_end - $exon_start + 1;
	    if (($diff >= $min) && ($diff <= $max)){
		my $inferred_exon = "$int_chr:$exon_start-$ex_end";
		#if $inferred_exon is already in hash %INF_EXONS, 
  		# add ex_start_score and ex_end_scores,
		if (exists $INF_EXONS{$inferred_exon}){
		    my $old_start_score = @{$INF_EXONS{$inferred_exon}}[0];
		    my $old_end_score = @{$INF_EXONS{$inferred_exon}}[1];
		    my $new_start_score = $ex_start_score + $old_start_score;
		    my $new_end_score = $ex_end_score + $old_end_score;
		    my @NEW_SCORE = ($new_start_score, $new_end_score);
		    $INF_EXONS{$inferred_exon} = [@NEW_SCORE];
		}
		elsif ($diff <= $max){
		    $INF_EXONS{$inferred_exon} = [@SCORE];
		}
	    }
	}
	$EXON_START{$ex_start} = $score;
    }
    $current_n = $chr_n;
}
close(INFILE);

my $temp1 = "$outfile.temp1";
open(TEMP1, ">$temp1");
foreach my $key (keys %INF_EXONS){ 
    # switch order if score_start is > than score_end;
    if($INF_EXONS{$key}[0] > $INF_EXONS{$key}[1]) {
	my $temp = $INF_EXONS{$key}[0];
	$INF_EXONS{$key}[0] = $INF_EXONS{$key}[1];
	$INF_EXONS{$key}[1] = $temp;
    }
    #inferred exon
    print TEMP1 "$key\n";
}
close(TEMP1);

#sort inferred exons by location
my $path = abs_path($0);
$path =~ s/get_novel_exons.pl//g;
my $sort_script = "$path/rum-2.0.5_05/bin/sort_by_location.pl";
my $temp2 = "$outfile.temp2";
`perl $sort_script -o $temp2 --location 1 $temp1`;

my $curr_chr = "";
my %temp_hash;
open(TEMP2, $temp2);
open(OUT, ">$outfile");
while($line = <TEMP2>){
    chomp($line);
    (my $exon_chr, my $exon_start, my $exon_end) = $line =~  /^(.*):(\d*)-(\d*)$/g;
    # when you get to new chr write out the exons in temp_hash and empty temp_hash 
    if ($curr_chr ne $exon_chr){
        for my $key (keys %temp_hash){
	    print OUT "$key\n";
	}
	for (keys %temp_hash){
	    delete $temp_hash{$_};
	}
    }
    # for every inferred exon in hash, 
    # if exon end is smaller than new exon_start (not overlapping), 
    # write that exon out to a final list and remove from temp_hash
    foreach my $key (keys %temp_hash){
	(my $temp_chr, my $temp_start, my $temp_end) = $key =~  /^(.*):(\d*)-(\d*)$/g;
	my $overlap = $temp_end - $exon_start;
	if ($overlap < 0){
	    print OUT "$key\n";
	    delete $temp_hash{$key};
	}
    }
    # add exon to temp_hash
    $temp_hash{$line} = $INF_EXONS{$line};
    my $count = scalar keys %temp_hash;
    if ($count >= 5){
	# sort -r exons hash by min score and then max score 
	my @temp_keys = sort {
	    $temp_hash{$b}[0] <=> $temp_hash{$a}[0]
		or 
	    $temp_hash{$b}[1] <=> $temp_hash{$a}[1]
	} keys %temp_hash;
	# only keep exons with 5 highest scores
	for(my $i=5; $i<@temp_keys; $i++){
	    delete $temp_hash{$temp_keys[$i]};
	}
    }
    $curr_chr = $exon_chr;
}
close(OUT);
`rm $temp1 $temp2`;

