#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl add_highexp_counts.pl <loc> [options]

where:
<loc> is where the sample directories are

options:
-stranded: set this for stranded data

";


if (@ARGV<1){
    die $USAGE;
}


my $stranded = "false";
for(my $i=1;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
	$option_found = "true";
	$stranded = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $loc = $ARGV[0];
my @a = split(/\//,$loc);
my $study_name = $a[@a-2];
my $reads_dir = $a[@a-1];
my $study_dir = $loc;
$study_dir =~ s/$reads_dir//;
my $gnorm_dir = "$study_dir/NORMALIZED_DATA/GENE/";
my $spread_dir = "$gnorm_dir/SPREADSHEETS/";
my $gstats_dir = "$study_dir/STATS/GENE/";

my $numreads = "$gstats_dir/expected_num_reads_gnorm.after_filter_high_expressers.txt";
unless (-e $numreads){
    $numreads = "$gstats_dir/expected_num_reads_gnorm.txt";
}


# get total unique reads from expected num reads file
my ($num_unique, $num_unique_a);
if ($stranded eq "false"){
    $num_unique = `grep unique $numreads | grep -v non`;
    if ($num_unique =~ /\:/){
	my @a = split(":", $num_unique);
	$num_unique = $a[1];
    }
    $num_unique =~ s/\,//g;
    $num_unique =~ s/unique//;
    $num_unique =~ s/reads//;
    $num_unique =~ s/^\s*(.*?)\s*$/$1/;
}

if ($stranded eq "true"){
    my $x = `grep unique $numreads | grep -v non`;
    if ($x =~ /\:/){
        my @a = split(":", $x);
        $x = $a[1];
    }
    $x =~ s/\,//g;
    $x =~ m/(\d+)\ sense unique/;
    $num_unique = $1;
    my $y = `grep unique $numreads | grep -v non`;
    $y =~ s/\,//g;
    $y =~ m/(\d+)\ antisense unique/;
    $num_unique_a = $1;
}

#master list of genes file
my $master = $loc . "/master_list_of_genes.txt";

# percent high expressers file
my $high = "$gstats_dir/percent_high_expresser_gene.txt";
my $high_a;

if ($stranded eq "true"){
    $high =~ s/.txt$/_sense.txt/;
    $high_a = $high;
    $high_a =~ s/_sense.txt$/_antisense.txt/;
}

# master list of genes counts (min) spreadsheet
my $ssheet = "$spread_dir/FINAL_master_list_of_genes_counts_MIN.$study_name.txt";
my $ssheet_a;
if ($stranded eq "true"){
    $ssheet = "$spread_dir/FINAL_master_list_of_genes_counts_MIN.sense.$study_name.txt";
    $ssheet_a = "$spread_dir/FINAL_master_list_of_genes_counts_MIN.antisense.$study_name.txt";
}

# check if high expressers exist 
my $check = "false";
my $check_a = "false";
if ($stranded eq "true"){
    my $count = `head -1 $high | wc -w`;
    if ($count > 1){
	$check = "true";
    }
    my $count_a = `head -1 $high_a | wc -w`;
    if ($count_a > 1){
	$check_a = "true";
    }
}
if ($stranded eq "false"){
    my $count = `head -1 $high | wc -w`;
    chomp($count);
    if ($count > 1){
	$check = "true";
    }
}

my (%HASH, %GENE);
my (%HASH_A, %GENE_A);
if ($check eq "true"){
    open(HIGH, $high) or die 'cannot find \"$high\"\n';
    my $header = <HIGH>;
    chomp($header);
    my @h = split(/\t/, $header);
    for (my $i=1;$i<@h;$i++){
	$GENE{$i}=$h[$i];
    }
=debug
    print "$header\n";
    foreach my $key (keys %GENE){
	print "$key\t$GENE{$key}\n";
    }
    print "\n\n";
=cut
    while(my $line = <HIGH>){
	chomp($line);
	if ($line =~ /^geneSymbol/){
	    next;
	}
	my @a = split(/\t/, $line);
	my $id = $a[0];
	for (my $i=1;$i<@a;$i++){
	    $HASH{$id}[$i] = $a[$i];
	}
    }
    close(HIGH);

    my $new = $ssheet;
    $new =~ s/.txt$/.highExp.txt/;
    open(IN, $ssheet) or die "cannot open '$ssheet'\n";
    open(NEW, ">$new") or die "cannot open '$new'\n";
    my $header2 = <IN>;
    chomp($header2);
    my @k = split(/\t/, $header2);
    print NEW "$header2\thighExp\n";
    for (my $i=1;$i<@h;$i++){
	print NEW "$GENE{$i}\t";
	for (my $j=1;$j<@k-2;$j++){
	    my $percent = $HASH{$k[$j]}[$i];
	    my $value = int($num_unique * $percent / 100);
	    print NEW "$value\t";
	}
	my $annot = `grep $GENE{$i} $master`;
	chomp($annot);
	my @c = split(/\t/, $annot);
	my $symbol = $c[1];
	my $coord = $c[2];
	print NEW "$coord\t$symbol\t*\n"
    }
    while(my $line = <IN>){
	chomp($line);
	print NEW "$line\n";
    }
    close(NEW);
    close(IN);
}

if ($check_a eq "true"){
    open(HIGH_A, $high_a) or die 'cannot find \"$high_a\"\n';
    my $header_a = <HIGH_A>;
    chomp($header_a);
    my @h_a = split(/\t/, $header_a);
    for (my $i=1;$i<@h_a;$i++){
	$GENE_A{$i}=$h_a[$i];
    }
    while(my $line = <HIGH_A>){
        chomp($line);
        if ($line =~ /^geneSymbol/){
            next;
        }
        my @a = split(/\t/, $line);
	my $id = $a[0];
        for (my $i=1;$i<@a;$i++){
            $HASH_A{$id}[$i] = $a[$i];
        }
    }
    close(HIGH_A);
    my $new_a = $ssheet_a;
    $new_a =~ s/.txt$/.highExp.txt/;
    open(IN_A, $ssheet_a) or die "cannot open '$ssheet_a'\n";
    open(NEW_A, ">$new_a") or die "cannot open '$new_a'\n";
    my $header2 = <IN_A>;
    chomp($header2);
    my @k = split(/\t/, $header2);
    print NEW_A "$header2\thighExp\n";
    for (my $i=1;$i<@h_a;$i++){
        print NEW_A "$GENE_A{$i}\t";
        for (my $j=1;$j<@k-2;$j++){
            my $percent = $HASH_A{$k[$j]}[$i];
            my $value = int($num_unique_a * $percent / 100);
            print NEW_A "$value\t";
        }
        my $annot = `grep $GENE_A{$i} $master`;
	chomp($annot);
        my @c = split(/\t/, $annot);
        my $symbol = $c[1];
        my $coord = $c[2];
	print NEW_A "$coord\t$symbol\t*\n"
    }
    while(my $line = <IN_A>){
        chomp($line);
        print NEW_A "$line\n";
    }
    close(NEW_A);
    close(IN_A);
}


print "got here\n";
