#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: perl get_normfactors_table.pl <sample_dirs> <loc> [options]

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

option:
 
 -stranded : set this if your data are stranded
 -mito \"<name>, <name>, ... ,<name>\": name(s) of mitochondrial chromosomes

";

if (@ARGV < 2){
    die $USAGE;
}
my $count = 0;
my $stranded = "false";
my %MITO;
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
	$option_found = "true";
	$stranded = "true";
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
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($count == 0){
    die "please provide mitochondrial chromosome name using -mito \"<name>\" option.\n";
}

my $dirs = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $eij = "false";
my $gnorm = "false";

my $out_eij = "$study_dir/STATS/exon-intron-junction_normalization_factors.txt";
my $out_gnorm = "$study_dir/STATS/gene_normalization_factors.txt";

if (-d "$study_dir/STATS/EXON_INTRON_JUNCTION"){
    $eij = "true";
}
if (-d "$study_dir/STATS/GENE"){
    $gnorm = "true";
}
my $total = "false"; 
my $chrM = "false";
my $NU = "false";
my $ribo = "false";
my $exonicU = "false";
my $exonicNU = "false"; 
my $oneexonmappersU = "false";
my $oneexonmappersNU = "false";
my $intergenicU = "false";
my $intergenicNU = "false";
my $geneU = "false";
my $geneNU = "false";
my $undU = "false";
my $undNU = "false";

my $exonicU_A = "false";
my $exonicNU_A = "false";
my $oneexonmappersU_A = "false";
my $oneexonmappersNU_A = "false";
my $senseE_U = "false";
my $senseI_U = "false";
my $senseE_NU = "false";
my $senseI_NU = "false";
my $geneU_A = "false";
my $geneNU_A = "false";
my $senseG_U = "false";
my $senseG_NU = "false";
my $footer = "";
my ($total_num, @chrM_num, @chrM_num_m, $NU_num, $NU_num_m, $ribo_num, $exonic_u,  $exonic_nu, $one_u, $one_nu, $intergenic_u, $intergenic_nu, $gene_u, $gene_nu, $und_u, $und_nu);
my ($exonic_u_a, $exonic_nu_a, $one_u_a, $one_nu_a, $sense_ex_u, $sense_int_u, $sense_ex_nu, $sense_int_nu);
my ($gene_u_a, $gene_nu_a,$sense_g_u, $sense_g_nu);
if ($gnorm eq "true"){
    $footer = "----------\n";
    open(OUT, ">$out_gnorm");
    print OUT "sample\t";
    if (-e "$study_dir/STATS/mappingstats_summary.txt"){
        print OUT "totalnumreads\t%NU\t";
        $total = "true";
        $NU = "true";
    }
    if (-e "$study_dir/STATS/mitochondrial_percents.txt"){
	foreach my $key (sort keys %MITO){
	    print OUT "%$key\t";
	}
	$chrM= "true";
    }
    if (-e "$study_dir/STATS/ribo_percents.txt"){
        print OUT "%ribo\t";
        $ribo = "true";
    }
    if ($stranded eq "false"){
	if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique.txt"){
	    print OUT "%geneU\t";
	    $footer .= "# %geneU : %unique genemappers out of total unique mappers\n";
	    $geneU = "true";
	}
	if (-e "$study_dir/STATS/GENE/percent_genemappers_NU.txt"){
	    print OUT "%geneNU\t";
	    $footer .= "# %geneNU : %non-unique genemappers out of total non-unique mappers\n";
	    $geneNU = "true";
	}
    }
    if ($stranded eq "true"){
        if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique_sense.txt"){
            print OUT "%geneU-sense\t";
	    $footer .= "# %geneU-sense : # %unique genemappers-sense out of total unique mappers\n";
            $geneU = "true";
        }
        if (-e "$study_dir/STATS/GENE/percent_genemappers_NU_sense.txt"){
            print OUT "%geneNU-sense\t";
	    $footer .= "# %geneNU-sense : %non-unique genemappers-sense out of total non-unique mappers\n";
            $geneNU = "true";
        }
	if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique_antisense.txt"){
            print OUT "%geneU-anti\t";
	    $footer .= "# %geneU-anti : %unique genemappers-antisense out of total unique mappers\n";
            $geneU_A = "true";
        }
        if (-e "$study_dir/STATS/GENE/percent_genemappers_NU_antisense.txt"){
            print OUT "%geneNU-anti\t";
	    $footer .= "# %geneNU-anti : %non-unique genemappers-antisense out of total non-unique mappers\n";
            $geneNU_A = "true";
        }
	if (-e "$study_dir/STATS/GENE/sense_vs_antisense_genemappers_Unique.txt"){
	    print OUT "%senseGeneU\t";
	    $footer .= "# %senseGeneU : %unique sense genemappers out of unique sense + antisense genemappers\n";
	    $senseG_U = "true";
	}
	if (-e "$study_dir/STATS/GENE/sense_vs_antisense_genemappers_NU.txt"){
            print OUT "%senseGeneNU\t";
	    $footer .= "# %senseGeneNU : %non-unique sense genemappers out of non-unique sense + antisense genemappers\n";
            $senseG_NU ="true";
	}
    }
	
    print OUT "\n";
    open(IN, $dirs);
    while (my $line = <IN>){
        chomp($line);
        #totalnumreads
	if ($total eq "true"){
	    $total_num = `cut -f 1,2 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($total_num);
            $total_num =~ s/$line//g;
	    $total_num =~ s/^\s*(.*?)\s*$/$1/;
            $total_num =~ s/\,//g;
        }
        #NU
        if ($NU eq "true"){
            $NU_num = `cut -f 1,7 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($NU_num);
            $NU_num =~ s/$line//g;
            $NU_num =~ s/^\s*(.*?)\s*$/$1/;
            $NU_num =~ m/\((.*)\%\)/;
            $NU_num_m = $1;
        }
	#chrM
	if ($chrM eq "true"){
	    my $size = keys %MITO;
	    for (my $i=2;$i<$size+2;$i++){
		$chrM_num[$i] = `cut -f 1,$i $study_dir/STATS/mitochondrial_percents.txt | grep -w $line`;
		chomp($chrM_num[$i]);
		$chrM_num[$i] =~ s/$line//g;
		$chrM_num[$i] =~ s/^\s*(.*?)\s*$/$1/;
		$chrM_num[$i] =~ m/\((.*)\%\)/;
		$chrM_num_m[$i] = $1;
	    }
        }

        #ribo
        if ($ribo eq "true"){
	    $ribo_num = `cut -f 3,4 $study_dir/STATS/ribo_percents.txt | grep -w $line`;
            chomp($ribo_num);
            $ribo_num =~ s/$line//g;
            $ribo_num =~ s/^\s*(.*?)\s*$/$1/;
	}
        #gene u
        if ($geneU eq "true"){
	    if ($stranded eq "false"){
		$gene_u = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_Unique.txt`;
	    }
	    if ($stranded eq "true"){
		$gene_u = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_Unique_sense.txt`;
	    }
            chomp($gene_u);
            $gene_u =~ s/$line//g;
            $gene_u =~ s/^\s*(.*?)\s*$/$1/;
        }
	#gene u anti
	if ($geneU_A eq "true"){
	    $gene_u_a = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_Unique_antisense.txt`;
	    chomp($gene_u_a);
            $gene_u_a =~ s/$line//g;
            $gene_u_a =~ s/^\s*(.*?)\s*$/$1/;
	}
        #gene nu
        if ($geneNU eq "true"){
	    if ($stranded eq "false"){
		$gene_nu = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_NU.txt`;
	    }
	    if ($stranded eq "true"){
		$gene_nu = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_NU_sense.txt`;
            }
            chomp($gene_nu);
            $gene_nu =~ s/$line//g;
            $gene_nu =~ s/^\s*(.*?)\s*$/$1/;
        }
	#gene nu anti        
	if ($geneNU_A eq "true"){
	    $gene_nu_a = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_NU_antisense.txt`;
	    chomp($gene_nu_a);
	    $gene_nu_a =~ s/$line//g;
            $gene_nu_a =~ s/^\s*(.*?)\s*$/$1/;
	}
	#senseU
	if ($senseG_U eq "true"){
	    $sense_g_u = `grep -w $line $study_dir/STATS/GENE/sense_vs_antisense_genemappers_Unique.txt`;
	    chomp($sense_g_u);
            $sense_g_u =~ s/$line//g;
            $sense_g_u =~ s/^\s*(.*?)\s*$/$1/;
	}
	#senseNU
	if ($senseG_NU eq "true"){
            $sense_g_nu = `grep -w $line $study_dir/STATS/GENE/sense_vs_antisense_genemappers_NU.txt`;
            chomp($sense_g_nu);
            $sense_g_nu =~ s/$line//g;
            $sense_g_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	print OUT "$line\t$total_num\t$NU_num_m\t";
	my $size = keys %MITO;
	for (my$i=2;$i<$size+2;$i++){
	    print OUT "$chrM_num_m[$i]\t";
	}
	print OUT "$ribo_num\t";
	if ($stranded eq "false"){
	    print OUT "$gene_u\t$gene_nu\n";
	}
	if ($stranded eq "true"){
	    print OUT "$gene_u\t$gene_u_a\t$gene_nu\t$gene_nu_a\t$sense_g_u\t$sense_g_nu\n";
	}
    }
    print OUT $footer;
    close(OUT);
    close(IN);
}	

if ($eij eq "true"){
    $footer = "----------\n";
    open(OUT, ">$out_eij");
    print OUT "sample\t";

    if (-e "$study_dir/STATS/mappingstats_summary.txt"){
	print OUT "totalnumreads\t%NU\t";
	$total = "true";
	$NU = "true";
    }
    if (-e "$study_dir/STATS/mitochondrial_percents.txt"){
        foreach my $key (sort keys %MITO){
            print OUT "%$key\t";
        }
        $chrM= "true";
    }
    if (-e "$study_dir/STATS/ribo_percents.txt"){
	print OUT "%ribo\t";
	$ribo = "true";
    }
    if ($stranded eq "false"){
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique.txt"){
	    print OUT "%exonicU\t";
	    $footer .= "# %exonicU : %unique exonmapppers out of total unique mappers\n";
	    $exonicU = "true";
	}    
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU.txt"){
	    print OUT "%exonicNU\t";
	    $footer .= "# %exonicNU : %non-unique exonmapppers out of total non-unique mappers\n";
	    $exonicNU = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique.txt"){
	    print OUT "%1exonmappersU\t";
	    $footer .= "# %1exonmappersU : %unique one-exonmapppers out of total unique exonmappers\n";
	    $oneexonmappersU = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU.txt"){
	    print OUT "%1exonmappersNU\t";
	    $footer .= "# %1exonmappersNU : %non-unique one-exonmapppers out of total non-unique exonmappers\n";
	    $oneexonmappersNU = "true";
	}
    }
    if ($stranded eq "true"){
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique_sense.txt"){
            print OUT "%exonicU_sense\t";
	    $footer .= "# %exonicU_sense : %unique exonmapppers-sense out of total unique mappers\n";
            $exonicU = "true";
        }
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique_antisense.txt"){
            print OUT "%exonicU_anti\t";
	    $footer .= "# %exonicU_anti : %unique exonmapppers-antisense out of total unique mappers\n";
            $exonicU_A = "true";
        }
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU_sense.txt"){
            print OUT "%exonicNU_sense\t";
	    $footer .= "# %exonicNU_sense : %non-unique exonmapppers-sense out of total non-unique mappers\n";
            $exonicNU = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU_antisense.txt"){
            print OUT "%exonicNU_anti\t";
	    $footer .= "# %exonicNU_anti : %non-unique exonmapppers-antisense out of total non-unique mappers\n";
            $exonicNU_A = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique_sense.txt"){
            print OUT "%1exonmappersU_sense\t";
	    $footer .= "# %1exonmappersU_sense : %unique one-exonmapppers-sense out of total unique exonmappers-sense\n";
            $oneexonmappersU = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique_antisense.txt"){
            print OUT "%1exonmappersU_anti\t";
	    $footer .= "# %1exonmappersU_anti : %unique one-exonmapppers-antisense out of total unique exonmappers-antisense\n";
            $oneexonmappersU_A = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU_sense.txt"){
            print OUT "%1exonmappersNU_sense\t";
	    $footer .= "# %1exonmappersNU_sense : %non-unique one-exonmapppers-sense out of total non-unique exonmappers-sense\n";
            $oneexonmappersNU = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU_antisense.txt"){
            print OUT "%1exonmappersNU_anti\t";
	    $footer .= "# %1exonmappersNU_anti : %non-unique one-exonmapppers-antisense out of total non-unique exonmappers-antisense\n";
            $oneexonmappersNU_A = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_exonmappers_Unique.txt"){
	    print OUT "%senseExonU\t";
	    $footer .= "# %senseExonU : %unique sense exonmappers out of unique sense + antisense exonmappers\n";
	    $senseE_U = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_exonmappers_NU.txt"){
	    print OUT "%senseExonNU\t";
	    $footer .= "# %senseExonNU : %non-unique sense exonmappers out of non-unique sense + antisense exonmappers\n";
	    $senseE_NU = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_intronmappers_Unique.txt"){
	    print OUT "%senseIntronU\t";
	    $footer .= "# %senseIntronU : %unique sense intronmappers out of unique sense + antisense intronmappers\n";
	    $senseI_U = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_intronmappers_NU.txt"){
	    print OUT "%senseIntronNU\t";
	    $footer .= "# %senseIntronNU : %non-unique sense intronmappers out of non-unique sense + antisense intronmappers\n";
	    $senseI_NU = "true";
	}
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_Unique.txt"){
	print OUT "%intergenicU\t";
	$footer .= "# %intergenicU : %unique intergenic mappers out of total unique mappers\n";
	$intergenicU = "true";
    }    
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_NU.txt"){
        print OUT "%intergenicNU\t";
	$footer .= "# %intergenicNU : %non-unique intergenic mappers out of total non-unique mappers\n";
	$intergenicNU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_undetermined_Unique.txt"){
        print OUT "%undeterminedU\t";
	$footer .= "# %undeterminedU : %unique undetermined reads out of total unique mappers\n";
        $undU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_undetermined_NU.txt"){
        print OUT "%undeterminedNU\t";
	$footer .= "# %undeterminedNU : %non-unique undetermined reads out of total non-unique mappers\n";
        $undNU = "true";
    }
    print OUT "\n";
    open(IN, $dirs);
    while (my $line = <IN>){
	chomp($line);
	#totalnumreads
	if ($total eq "true"){
	    $total_num = `cut -f 1,2 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($total_num);
	    $total_num =~ s/$line//g;
	    $total_num =~ s/^\s*(.*?)\s*$/$1/;
	    $total_num =~ s/\,//g;
	}
	#NU
	if ($NU eq "true"){
	    $NU_num = `cut -f 1,7 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($NU_num);
	    $NU_num =~ s/$line//g;
	    $NU_num =~ s/^\s*(.*?)\s*$/$1/;
	    $NU_num =~ m/\((.*)\%\)/;
	    $NU_num_m = $1;
	}
	#chrM
        if ($chrM eq "true"){
            my $size = keys %MITO;
	    for (my $i=2;$i<$size+2;$i++){
		$chrM_num[$i] = `cut -f 1,$i $study_dir/STATS/mitochondrial_percents.txt | grep -w $line`;
		chomp($chrM_num[$i]);
		$chrM_num[$i] =~ s/$line//g;
		$chrM_num[$i] =~ s/^\s*(.*?)\s*$/$1/;
		$chrM_num[$i] =~ m/\((.*)\%\)/;
		$chrM_num_m[$i] = $1;
	    }
        }
	#ribo
	if ($ribo eq "true"){
	    $ribo_num = `cut -f 3,4 $study_dir/STATS/ribo_percents.txt | grep -w $line`; 
	    chomp($ribo_num);
	    $ribo_num =~ s/$line//g;
	    $ribo_num =~ s/^\s*(.*?)\s*$/$1/;
	}

	#exonic u
	if ($exonicU eq "true"){
	    if ($stranded eq "false"){
		$exonic_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique.txt`;
	    }
	    if ($stranded eq "true"){
		$exonic_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique_sense.txt`;
	    }
	    chomp($exonic_u);
	    $exonic_u =~ s/$line//g;
	    $exonic_u =~ s/^\s*(.*?)\s*$/$1/;
	}
	#exonic u anti
	if ($exonicU_A eq "true"){
            $exonic_u_a = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique_antisense.txt`;
            chomp($exonic_u_a);
            $exonic_u_a =~ s/$line//g;
            $exonic_u_a =~ s/^\s*(.*?)\s*$/$1/;
        }
	
	#exonic nu
	if ($exonicNU eq "true"){
	    if ($stranded eq "false"){
		$exonic_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU.txt`;
	    }
	    if ($stranded eq "true"){
		$exonic_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU_sense.txt`;
	    }
	    chomp($exonic_nu);
	    $exonic_nu =~ s/$line//g;
	    $exonic_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	#exonic nu anti
	if ($exonicNU_A eq "true"){
            $exonic_nu_a = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU_antisense.txt`;
            chomp($exonic_nu_a);
            $exonic_nu_a =~ s/$line//g;
            $exonic_nu_a =~ s/^\s*(.*?)\s*$/$1/;
        }

	#one-vs-multi u
	if ($oneexonmappersU eq "true"){
	    if ($stranded eq "false"){
		$one_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique.txt`;
	    }
	    if ($stranded eq "true"){
		$one_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique_sense.txt`;
	    }
	    chomp($one_u);
	    $one_u =~ s/$line//g;
	    $one_u =~ s/^\s*(.*?)\s*$/$1/;
	}
        #one-vs-multi u anti
        if ($oneexonmappersU_A eq "true"){
            $one_u_a = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique_antisense.txt`;
            chomp($one_u_a);
            $one_u_a =~ s/$line//g;
            $one_u_a =~ s/^\s*(.*?)\s*$/$1/;
        }
	#one-vs-multi nu
	if ($oneexonmappersNU eq "true"){
	    if ($stranded eq "false"){
		$one_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU.txt`;
	    }
	    if ($stranded eq "true"){
		$one_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU_sense.txt`;
	    }
	    chomp($one_nu);
	    $one_nu =~ s/$line//g;
	    $one_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	#one-vs-multi nu anti
        if ($oneexonmappersNU_A eq "true"){
            $one_nu_a = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU_antisense.txt`;
            chomp($one_nu_a);
            $one_nu_a =~ s/$line//g;
            $one_nu_a =~ s/^\s*(.*?)\s*$/$1/;
        }
	#sense exon u
	if ($senseE_U eq "true"){
	    $sense_ex_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_exonmappers_Unique.txt`;
	    chomp($sense_ex_u);
            $sense_ex_u =~ s/$line//g;
            $sense_ex_u =~ s/^\s*(.*?)\s*$/$1/;
	}
        #sense exon nu
	if ($senseE_NU eq "true"){
            $sense_ex_nu= `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_exonmappers_NU.txt`;
            chomp($sense_ex_nu);
            $sense_ex_nu =~ s/$line//g;
            $sense_ex_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
        #sense intron u
	if ($senseI_U eq "true"){
            $sense_int_u= `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_intronmappers_Unique.txt`;
            chomp($sense_int_u);
            $sense_int_u =~ s/$line//g;
            $sense_int_u =~ s/^\s*(.*?)\s*$/$1/;
	}
        #sense intron nu
        if ($senseI_NU eq "true"){
            $sense_int_nu= `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_intronmappers_NU.txt`;
            chomp($sense_int_nu);
            $sense_int_nu =~ s/$line//g;
            $sense_int_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	#intergenic u
	if ($intergenicU eq "true"){
	    $intergenic_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_Unique.txt`;
	    chomp($intergenic_u);
	    $intergenic_u =~ s/$line//g;
	    $intergenic_u =~ s/^\s*(.*?)\s*$/$1/;
	}
	#intergenic nu
	if ($intergenicNU eq "true"){
	    $intergenic_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_NU.txt`;
	    chomp($intergenic_nu);
	    $intergenic_nu =~ s/$line//g;
	    $intergenic_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
        #undetermined u
        if ($undU eq "true"){
            $und_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/percent_undetermined_Unique.txt`;
            chomp($und_u);
            $und_u =~ s/$line//g;
            $und_u =~ s/^\s*(.*?)\s*$/$1/;
        }
        #undetermined nu
        if ($undNU eq "true"){
            $und_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/percent_undetermined_NU.txt`;
            chomp($und_nu);
            $und_nu =~ s/$line//g;
            $und_nu =~ s/^\s*(.*?)\s*$/$1/;
        }
	print OUT "$line\t$total_num\t$NU_num_m\t";
        my $size = keys %MITO;
        for (my$i=2;$i<$size+2;$i++){
            print OUT "$chrM_num_m[$i]\t";
        }
        print OUT "$ribo_num\t";
	if ($stranded eq "false"){
	    print OUT "$exonic_u\t$exonic_nu\t$one_u\t$one_nu\t$intergenic_u\t$intergenic_nu\t$und_u\t$und_nu\n";
	}
	if ($stranded eq "true"){
#	    print OUT "\$line\t\$total_num\t\$chrM_num_m\t\$NU_num_m\t\$ribo_num\t\$exonic_u\t\$exonic_u_a\t\$exonic_nu\t\$exonic_nu_a\t\$one_u\t\$one_u_a\t\$one_nu\t\$one_nu_a\t\$sense_ex_u\t\$sense_ex_nu\t\$sense_int_u\t\$sense_int_nu\t\$intergenic_u\t\$intergenic_nu\t\$und_u\t\$und_nu\n";
	    print OUT "$exonic_u\t$exonic_u_a\t$exonic_nu\t$exonic_nu_a\t$one_u\t$one_u_a\t$one_nu\t$one_nu_a\t$sense_ex_u\t$sense_ex_nu\t$sense_int_u\t$sense_int_nu\t$intergenic_u\t$intergenic_nu\t$und_u\t$und_nu\n";

	}
    }
    print OUT $footer;
    close(OUT);
    close(IN);
}

print "got here\n";
