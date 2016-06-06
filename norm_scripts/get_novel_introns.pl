#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
if(@ARGV<2) {
    die "Usage: perl get_novel_introns.pl <junctions_all.rum file> <output file> [options]

where
<junctions_all.rum file> input junctions file
<output file> output file (full path)

";
}

my $file = $ARGV[0];
my $output = $ARGV[1];
my $temp1 = "$output.temp1";
my %INF_INTRONS;
my %STR;
open(IN, $file) or die "cannot find file '$file'\n";
open(TEMP1, ">$temp1");
my $header = <IN>;
while(my $line = <IN>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $intron = $a[0];
    my $strand = $a[1];
    my $score = $a[2];
    my $known = $a[3];
    # novel intron if depth >=10 and unannotated
    if (($score >= 10) && ($known == 0)){ 
	(my $int_chr, my $int_start, my $int_end) = $intron =~  /^(.*):(\d*)-(\d*)$/g;
	my $size = $int_end - $int_start + 1;
	# keep novel intron only if it's smaller than 75,000
	if ($size < 75000){
	    $INF_INTRONS{$intron} = $score;
	    $STR{$intron} = $strand;
	    print TEMP1 "$intron\n";
	}
    }
    
}
close(IN);
close(TEMP1);

#sort inferred introns by location
my $path = abs_path($0);
$path =~ s/get_novel_introns.pl//g;
my $sort_script = "$path/rum-2.0.5_05/bin/sort_by_location.pl";
my $temp2 = "$output.temp2";
`perl $sort_script -o $temp2 --location 1 $temp1`;

my $curr_chr = "";
my %temp_hash;
open(TEMP2, $temp2);
open(OUT, ">$output") or die "cannot open '$output'\n";
while(my $line = <TEMP2>){
    chomp($line);
    (my $int_chr, my $int_start, my $int_end) = $line =~  /^(.*):(\d*)-(\d*)$/g;
    if ($curr_chr ne $int_chr){
	for my $key (keys %temp_hash){
	    print OUT "$key\t$STR{$key}\n";
	}
	for (keys %temp_hash){
	    delete $temp_hash{$_};
	}
    }
    # for every inferred intron in hash,
    # if intron end is smaller than new intron_start (not overlapping),
    # write that intron out to a final list and remove from temp_hash
    foreach my $key (keys %temp_hash){
        (my $temp_chr, my $temp_start, my $temp_end) = $key =~  /^(.*):(\d*)-(\d*)$/g;
        my $overlap = $temp_end - $int_start;
        if ($overlap < 0){
            print OUT "$key\t$STR{$key}\n";
            delete $temp_hash{$key};
        }
    }
    # add intron to temp_hash
    $temp_hash{$line} = $INF_INTRONS{$line};
    
    my $count = scalar keys %temp_hash;
    if ($count >= 5){
	my @temp_keys = sort{
	    $temp_hash{$b} <=> $temp_hash{$a}
	} keys %temp_hash;
        # only keep introns with 5 highest scores
        for(my $i=5; $i<@temp_keys; $i++){
            delete $temp_hash{$temp_keys[$i]};
        }
    }
    $curr_chr = $int_chr;
}
    
close(OUT);
`rm $temp1 $temp2`;
