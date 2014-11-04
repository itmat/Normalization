#!/usr/bin/env perl
use strict;
use warnings;
if (@ARGV < 2){
    die "usage: perl cat_shuffiles.pl <sample dirs> <loc> [options]

where:
<sample dirs> is  a file of sample directories 
<loc> is the path to the sample directories

option:
  -stranded : set this if your data is strand-specific.

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
for(my$i=2; $i<@ARGV; $i++) {
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
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
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
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $norm_dir = $loc_study."NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/";
unless (-d $norm_dir){
    `mkdir -p $norm_dir`;
}
my $norm_exon_dir = $norm_dir . "/exonmappers";
unless (-d $norm_exon_dir){
    `mkdir $norm_exon_dir`;
}

my $norm_intron_dir = $norm_dir . "/intronmappers";
unless (-d $norm_intron_dir){
    `mkdir $norm_intron_dir`;
}
my $norm_ig_dir = $norm_dir . "/intergenicmappers";
unless (-d $norm_ig_dir){
    `mkdir $norm_ig_dir`;
}
my $norm_und_dir = $norm_dir . "/undetermined";
unless (-d $norm_und_dir){
    `mkdir $norm_und_dir`;
}

my @g;
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $dir;
    my $current_LOC = "$LOC/$dir";
    if ($stranded eq "false"){
	if ($numargs eq '0'){
	    #exonmappers
	    print "$current_LOC/EIJ/*/$id.*_exonmappers.*_shuf_*.sam\n";
	    @g = glob("$current_LOC/EIJ/*/$id.*_exonmappers.*_shuf_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/$id.exonmappers.norm.sam`;
	    }
	    #intronmappers
	    @g = glob("$current_LOC/EIJ/*/$id.*_intronmappers.*_shuf_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/$id.intronmappers.norm.sam`;
	    }
	    #intergenicmappers
	    @g = glob("$current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	    }
            #undetermined_reads
            @g = glob("$current_LOC/EIJ/*/$id.undetermined_reads.norm_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/*/$id.undetermined_reads.norm_*.sam > $norm_und_dir/$id.undetermined_reads.norm.sam`;
            }
	}
	elsif ($U eq "true"){
           #exonmappers
            @g = glob("$current_LOC/EIJ/Unique/$id.*_exonmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/Unique/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/$id.exonmappers.norm_u.sam`;
            }
            #intronmappers
            @g = glob("$current_LOC/EIJ/Unique/$id.*_intronmappers.*_shuf_*.sam");
            if (@g ne '0'){
		`cat $current_LOC/EIJ/NU/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/$id.intronmappers.norm_u.sam`;
            }
            #intergenicmappers
            @g = glob("$current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam > $norm_ig_dir/$id.intergenicmappers.norm_u.sam`;
            }
            #undetermined_reads
            @g = glob("$current_LOC/EIJ/Unique/$id.undetermined_reads.norm_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/Unique/$id.undetermined_reads.norm_*.sam > $norm_und_dir/$id.undetermined_reads.norm_u.sam`;
            }

	}
	elsif ($NU eq "true"){
	    #exonmappers
	    @g = glob("$current_LOC/EIJ/NU/$id.*_exonmappers.*_shuf_*.sam");
	    if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/$id.exonmappers.norm_nu.sam`;
            }
            #intronmappers
            @g = glob("$current_LOC/EIJ/NU/$id.*_intronmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/$id.intronmappers.norm_nu.sam`;
            }
            #intergenicmappers
            @g = glob("$current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam");
            if (@g ne '0'){
		`cat $current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam > $norm_ig_dir/$id.intergenicmappers.norm_nu.sam`;
            }        
            #undetermined_reads
            @g = glob("$current_LOC/EIJ/NU/$id.undetermined_reads.norm_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/$id.undetermined_reads.norm_*.sam > $norm_und_dir/$id.undetermined_reads.norm_nu.sam`;
            }
	}
    }
    if ($stranded eq "true"){
	unless (-d "$norm_exon_dir/sense"){
	    `mkdir $norm_exon_dir/sense`;
	}
	unless (-d "$norm_exon_dir/antisense"){
	    `mkdir $norm_exon_dir/antisense`;
	}
	unless (-d "$norm_intron_dir/sense"){
	    `mkdir $norm_intron_dir/sense`;
        }
        unless (-d "$norm_intron_dir/antisense"){
            `mkdir $norm_intron_dir/antisense`;
        }
	if ($numargs eq "0"){
	    #exonmappers
	    @g = glob("$current_LOC/EIJ/*/sense/$id.*_exonmappers.*_shuf_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/sense/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/sense/$id.exonmappers.norm.sam`;
	    }
	    @g = glob("$current_LOC/EIJ/*/antisense/$id.*_exonmappers.*_shuf_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/antisense/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/antisense/$id.exonmappers.norm.sam`;
	    }
	    #intronmappers
	    @g = glob("$current_LOC/EIJ/*/sense/$id.*_intronmappers.*_shuf_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/sense/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/sense/$id.intronmappers.norm.sam`;
	    }
	    @g = glob("$current_LOC/EIJ/*/antisense/$id.*_intronmappers.*_shuf_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/antisense/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/antisense/$id.intronmappers.norm.sam`;
	    }
	    #intergenicmappers
	    @g = glob("$current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/$id.intergenicmappers.norm_*.sam > $norm_ig_dir/$id.intergenicmappers.norm.sam`;
	    }
	    #undetermined_reads
	    @g = glob("$current_LOC/EIJ/*/$id.undetermined_reads.norm_*.sam");
	    if (@g ne '0'){
		`cat $current_LOC/EIJ/*/$id.undetermined_reads.norm_*.sam > $norm_und_dir/$id.undetermined_reads.norm.sam`;
	    }
	}
	elsif($U eq "true"){
	    #exonmappers
	    @g = glob("$current_LOC/EIJ/Unique/sense/$id.*_exonmappers.*_shuf_*.sam");
            if (@g ne '0'){
		`cat $current_LOC/EIJ/Unique/sense/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/sense/$id.exonmappers.norm_u.sam`;
            }
            @g = glob("$current_LOC/EIJ/Unique/antisense/$id.*_exonmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/Unique/antisense/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/antisense/$id.exonmappers.norm_u.sam`;
            }
            #intronmappers
	    @g = glob("$current_LOC/EIJ/Unique/sense/$id.*_intronmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/Unique/sense/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/sense/$id.intronmappers.norm_u.sam`;
            }
            @g = glob("$current_LOC/EIJ/Unique/antisense/$id.*_intronmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/Unique/antisense/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/antisense/$id.intronmappers.norm_u.sam`;
            }
	    #intergenicmappers
	    @g = glob("$current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam");
            if (@g ne '0'){
		`cat $current_LOC/EIJ/Unique/$id.intergenicmappers.norm_*.sam > $norm_ig_dir/$id.intergenicmappers.norm_u.sam`;
            }
	    #undetermined_reads
	    @g = glob("$current_LOC/EIJ/Unique/$id.undetermined_reads.norm_*.sam");
            if (@g ne '0'){
		`cat $current_LOC/EIJ/Unique/$id.undetermined_reads.norm_*.sam > $norm_und_dir/$id.undetermined_reads.norm_u.sam`;
            }
	}
	elsif($NU eq "true"){
	    #exonmappers
	    @g = glob("$current_LOC/EIJ/NU/sense/$id.*_exonmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/sense/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/sense/$id.exonmappers.norm_nu.sam`;
            }
            @g = glob("$current_LOC/EIJ/NU/antisense/$id.*_exonmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/antisense/$id.*_exonmappers.*_shuf_*.sam > $norm_exon_dir/antisense/$id.exonmappers.norm_nu.sam`;
            }
	    #intronmappers
            @g = glob("$current_LOC/EIJ/NU/sense/$id.*_intronmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/sense/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/sense/$id.intronmappers.norm_nu.sam`;
            }
            @g = glob("$current_LOC/EIJ/NU/antisense/$id.*_intronmappers.*_shuf_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/antisense/$id.*_intronmappers.*_shuf_*.sam > $norm_intron_dir/antisense/$id.intronmappers.norm_nu.sam`;
            }
            #intergenicmappers
            @g = glob("$current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/$id.intergenicmappers.norm_*.sam > $norm_ig_dir/$id.intergenicmappers.norm_nu.sam`;
            }
            #undetermined_reads
            @g = glob("$current_LOC/EIJ/NU/$id.undetermined_reads.norm_*.sam");
            if (@g ne '0'){
                `cat $current_LOC/EIJ/NU/$id.undetermined_reads.norm_*.sam > $norm_und_dir/$id.undetermined_reads.norm_nu.sam`;
            }
	}
    }
}
close(INFILE);

print "got here\n";
