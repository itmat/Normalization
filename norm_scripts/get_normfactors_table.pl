#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: perl get_normfactors_table.pl <sample_dirs> <loc> [options]

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

option:
 
 -stranded : set this if your data are stranded

";

if (@ARGV < 2){
    die $USAGE;
}
my $stranded = "false";
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
	$option_found = "true";
	$stranded = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
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

my ($total_num, $chrM_num, $chrM_num_m, $NU_num, $NU_num_m, $ribo_num, $exonic_u,  $exonic_nu, $one_u, $one_nu, $intergenic_u, $intergenic_nu, $gene_u, $gene_nu, $und_u, $und_nu);
my ($exonic_u_a, $exonic_nu_a, $one_u_a, $one_nu_a, $sense_ex_u, $sense_int_u, $sense_ex_nu, $sense_int_nu);
my ($gene_u_a, $gene_nu_a,$sense_g_u, $sense_g_nu);
if ($gnorm eq "true"){
    open(OUT, ">$out_gnorm");
    print OUT "sample\t";
    if (-e "$study_dir/STATS/mappingstats_summary.txt"){
        print OUT "totalnumreads\t%chrM\t%NU\t";
        $total = "true";
        $chrM = "true";
        $NU = "true";
    }
    if (-e "$study_dir/STATS/ribo_percents.txt"){
        print OUT "%ribo\t";
        $ribo = "true";
    }
    if ($stranded eq "false"){
	if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique.txt"){
	    print OUT "%geneU\t";
	    $geneU = "true";
	}
	if (-e "$study_dir/STATS/GENE/percent_genemappers_NU.txt"){
	    print OUT "%geneNU\t";
	    $geneNU = "true";
	}
    }
    if ($stranded eq "true"){
        if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique_sense.txt"){
            print OUT "%geneU-sense\t";
            $geneU = "true";
        }
        if (-e "$study_dir/STATS/GENE/percent_genemappers_NU_sense.txt"){
            print OUT "%geneNU-sense\t";
            $geneNU = "true";
        }
	if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique_antisense.txt"){
            print OUT "%geneU-anti\t";
            $geneU_A = "true";
        }
        if (-e "$study_dir/STATS/GENE/percent_genemappers_NU_antisense.txt"){
            print OUT "%geneNU-anti\t";
            $geneNU_A = "true";
        }
	if (-e "$study_dir/STATS/GENE/sense_vs_antisense_genemappers_Unique.txt"){
	    print OUT "%senseGeneU\t";
	    $senseG_U = "true";
	}
	if (-e "$study_dir/STATS/GENE/sense_vs_antisense_genemappers_NU.txt"){
            print OUT "%senseGeneNU\t";
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
	#chrM
	if ($chrM eq "true"){
            $chrM_num = `cut -f 1,5 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($chrM_num);
            $chrM_num =~ s/$line//g;
            $chrM_num =~ s/^\s*(.*?)\s*$/$1/;
            $chrM_num =~ m/\((.*)\%\)/;
            $chrM_num_m = $1;
        }
        #NU
        if ($NU eq "true"){
            $NU_num = `cut -f 1,8 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($NU_num);
            $NU_num =~ s/$line//g;
            $NU_num =~ s/^\s*(.*?)\s*$/$1/;
            $NU_num =~ m/\((.*)\%\)/;
            $NU_num_m = $1;
        }
        #ribo
        if ($ribo eq "true"){
	    $ribo_num = `cut -f 3,4 $study_dir/STATS/ribo_percents.txt | grep -w $line`;
            chomp($ribo_num);
            $ribo_num =~ s/$line//g;
            $ribo_num =~ s/^\s*(.*?)\s*$/$1/;
            $ribo_num = $ribo_num * 100;
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
	if ($stranded eq "false"){
	    print OUT "$line\t$total_num\t$chrM_num_m\t$NU_num_m\t$ribo_num\t$gene_u\t$gene_nu\n";
	}
	if ($stranded eq "true"){
	    print OUT "$line\t$total_num\t$chrM_num_m\t$NU_num_m\t$ribo_num\t$gene_u\t$gene_u_a\t$gene_nu\t$gene_nu_a\t$sense_g_u\t$sense_g_nu\n";
	}
    }
    close(OUT);
    close(IN);
}	
if ($eij eq "true"){
    open(OUT, ">$out_eij");
    print OUT "sample\t";

    if (-e "$study_dir/STATS/mappingstats_summary.txt"){
	print OUT "totalnumreads\t%chrM\t%NU\t";
	$total = "true";
	$chrM = "true";
	$NU = "true";
    }
    if (-e "$study_dir/STATS/ribo_percents.txt"){
	print OUT "%ribo\t";
	$ribo = "true";
    }
    if ($stranded eq "false"){
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique.txt"){
	    print OUT "%exonicU\t";
	    $exonicU = "true";
	}    
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU.txt"){
	    print OUT "%exonicNU\t";
	    $exonicNU = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique.txt"){
	    print OUT "%1exonmappersU\t";
	    $oneexonmappersU = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU.txt"){
	    print OUT "%1exonmappersNU\t";
	    $oneexonmappersNU = "true";
	}
    }
    if ($stranded eq "true"){
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique_sense.txt"){
            print OUT "%exonicU_sense\t";
            $exonicU = "true";
        }
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique_antisense.txt"){
            print OUT "%exonicU_anti\t";
            $exonicU_A = "true";
        }
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU_sense.txt"){
            print OUT "%exonicNU_sense\t";
            $exonicNU = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU_antisense.txt"){
            print OUT "%exonicNU_anti\t";
            $exonicNU_A = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique_sense.txt"){
            print OUT "%1exonmappersU_sense\t";
            $oneexonmappersU = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique_antisense.txt"){
            print OUT "%1exonmappersU_anti\t";
            $oneexonmappersU_A = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU_sense.txt"){
            print OUT "%1exonmappersNU_sense\t";
            $oneexonmappersNU = "true";
	}
        if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU_antisense.txt"){
            print OUT "%1exonmappersNU_anti\t";
            $oneexonmappersNU_A = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_exonmappers_Unique.txt"){
	    print OUT "%senseExonU\t";
	    $senseE_U = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_exonmappers_NU.txt"){
	    print OUT "%senseExonNU\t";
	    $senseE_NU = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_intronmappers_Unique.txt"){
	    print OUT "%senseIntronU\t";
	    $senseI_U = "true";
	}
	if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/sense_vs_antisense_intronmappers_NU.txt"){
	    print OUT "%senseIntronNU\t";
	    $senseI_NU = "true";
	}
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_Unique.txt"){
	print OUT "%intergenicU\t";
	$intergenicU = "true";
    }    
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_NU.txt"){
        print OUT "%intergenicNU\t";
	$intergenicNU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_undetermined_Unique.txt"){
        print OUT "%undeterminedU\t";
        $undU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_undetermined_NU.txt"){
        print OUT "%undeterminedNU\t";
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
	#chrM
	if ($chrM eq "true"){
	    $chrM_num = `cut -f 1,5 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($chrM_num);
	    $chrM_num =~ s/$line//g;
	    $chrM_num =~ s/^\s*(.*?)\s*$/$1/;
	    $chrM_num =~ m/\((.*)\%\)/;
	    $chrM_num_m = $1;
	}
	#NU
	if ($NU eq "true"){
	    $NU_num = `cut -f 1,8 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($NU_num);
	    $NU_num =~ s/$line//g;
	    $NU_num =~ s/^\s*(.*?)\s*$/$1/;
	    $NU_num =~ m/\((.*)\%\)/;
	    $NU_num_m = $1;
	}
	#ribo
	if ($ribo eq "true"){
	    $ribo_num = `cut -f 3,4 $study_dir/STATS/ribo_percents.txt | grep -w $line`; 
	    chomp($ribo_num);
	    $ribo_num =~ s/$line//g;
	    $ribo_num =~ s/^\s*(.*?)\s*$/$1/;
	    $ribo_num = $ribo_num * 100;
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
	if ($stranded eq "false"){
	    print OUT "$line\t$total_num\t$chrM_num_m\t$NU_num_m\t$ribo_num\t$exonic_u\t$exonic_nu\t$one_u\t$one_nu\t$intergenic_u\t$intergenic_nu\t$und_u\t$und_nu\n";
	}
	if ($stranded eq "true"){
#	    print OUT "\$line\t\$total_num\t\$chrM_num_m\t\$NU_num_m\t\$ribo_num\t\$exonic_u\t\$exonic_u_a\t\$exonic_nu\t\$exonic_nu_a\t\$one_u\t\$one_u_a\t\$one_nu\t\$one_nu_a\t\$sense_ex_u\t\$sense_ex_nu\t\$sense_int_u\t\$sense_int_nu\t\$intergenic_u\t\$intergenic_nu\t\$und_u\t\$und_nu\n";
	    print OUT "$line\t$total_num\t$chrM_num_m\t$NU_num_m\t$ribo_num\t$exonic_u\t$exonic_u_a\t$exonic_nu\t$exonic_nu_a\t$one_u\t$one_u_a\t$one_nu\t$one_nu_a\t$sense_ex_u\t$sense_ex_nu\t$sense_int_u\t$sense_int_nu\t$intergenic_u\t$intergenic_nu\t$und_u\t$und_nu\n";

	}
    }
    close(OUT);
    close(IN);
}

print "got here\n";
