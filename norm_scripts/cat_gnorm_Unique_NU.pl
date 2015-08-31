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
 -stranded: set this if your data are strand-specific.

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
for(my$i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-stranded') {
	$option_found = "true";
	$stranded = "true";
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


my $LOC = $ARGV[1];
my $samfilename = $ARGV[2];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $gnorm_dir = $loc_study."NORMALIZED_DATA/GENE/FINAL_SAM/";
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
my $id = $ARGV[0];
chomp($id);
my $original = "$LOC/$id/$samfilename";
my $header = `grep ^@ $original`;
if ($stranded eq "false"){
    my $file_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.norm.sam";
    my $file_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.norm.sam";
    my $outfile = "$gnorm_dir/$id.gene.norm.sam";
    if ($numargs ne 0){
	if ($U eq "true"){
	    $outfile =~ s/.sam$/_u.sam/i;
	}
	if ($NU eq "true"){
	    $outfile =~ s/.sam$/_nu.sam/i;
	}
    }
    open (OUT, ">$outfile");
    print OUT $header;
    close(OUT);
    if ($numargs eq '0'){
	unless (-e $file_U){
	    die "input file $file_U does not exist.\n";
	}
	unless (-e $file_NU){
	    die "input file $file_NU does not exist.\n";
	}
	`cat $file_U $file_NU >> $outfile`;
    }
    elsif ($U eq "true"){
	unless (-e $file_U){
            die "input file $file_U does not exist.\n";
	}
	`cat $file_U >> $outfile`;
    }
    elsif ($NU eq "true"){
        unless (-e $file_NU){
            die "input file $file_NU does not exist.\n";
        }
	`cat $file_NU >> $outfile`;
    }
}
if ($stranded eq "true"){
    my $file_U = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.sense.norm.sam";
    my $file_NU = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.sense.norm.sam";
    my $file_U_A = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.antisense.norm.sam";
    my $file_NU_A = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.antisense.norm.sam";
    my $outfile = "$sense_dir/$id.gene.norm.sam";
    my $outfile_a = "$antisense_dir/$id.gene.norm.sam";
    if ($numargs ne 0){
	if ($U eq "true"){
	    $outfile =~ s/.sam$/_u.sam/i;
	    $outfile_a =~ s/.sam$/_u.sam/i;
	}
	if ($NU eq "true"){
	    $outfile =~ s/.sam$/_nu.sam/i;
	    $outfile_a =~ s/.sam$/_nu.sam/i;
	}
    }
    open (OUT, ">$outfile");
    print OUT $header;
    close(OUT);
    open (OUT_A, ">$outfile_a");
    print OUT_A $header;
    close(OUT_A);
    if ($numargs eq '0'){
	unless (-e $file_U){
	    die "input file $file_U does not exist.\n";
        }
        unless (-e $file_NU){
	    die "input file $file_NU does not exist.\n";
        }
        unless (-e $file_U_A){
	    die "input file $file_U_A does not exist.\n";
        }
        unless (-e $file_NU_A){
	    die "input file $file_NU_A does not exist.\n";
        }
	`cat $file_U $file_NU >> $outfile`;
	`cat $file_U_A $file_NU_A >> $outfile_a`;
    }
    elsif ($U eq "true"){
        unless (-e $file_U){
	    die "input file $file_U does not exist.\n";
        }
        unless (-e $file_U_A){
            die "input file $file_U_A does not exist.\n";
        }
	`cat $file_U >> $outfile`;
	`cat $file_U_A >> $outfile_a`;
    }
    elsif ($NU eq "true"){
	unless (-e $file_NU){
            die "input file $file_NU does not exist.\n";
        }
        unless (-e $file_NU_A){
            die "input file $file_NU_A does not exist.\n";
        }
	`cat $file_NU >> $outfile`;
	`cat $file_NU_A >> $outfile_a`;
    }
}
print "got here\n";
