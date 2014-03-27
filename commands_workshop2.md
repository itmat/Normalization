#  RNA-Seq workshop excercises
---

### Link to GitHub repository:

https://github.com/itmat/Normalization/tree/workshop

### -1
```
ssh pennkey@demohpc.pmacs.upenn.edu
```
### 0. Set up 
```

git clone -b workshop https://github.com/itmat/Normalization.git

cd $HOME/Normalization/norm_scripts/

cp -r /opt/rna_seq/scripts/ncbi-blast-2.2.27+ $HOME/Normalization/norm_scripts/

cp /opt/rna_seq/scripts/ucsc_known_mm9 $HOME/Normalization/norm_scripts/

mkdir $HOME/study

cd $HOME/study

cp -r /opt/rna_seq/data/reads $HOME/study/
```
### 1. STAR
```
bsub -Is bash

module load STAR-2.3.0e

cd $HOME/study/reads

ls -d testdata* > dirs.txt

perl $HOME/Normalization/norm_scripts/runstar_workshop.pl $HOME/study/reads/dirs.txt $HOME/study/reads	

more $HOME/study/shell_scripts/testdata1.runstar.sh
```
### 2. Mapping Statistiscs
```
ls $HOME/study/reads/testdata*/forward* > fqfiles.txt

perl $HOME/Normalization/norm_scripts/get_total_num_reads.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/fqfiles.txt -fq

perl $HOME/Normalization/norm_scripts/runall_sam2mappingstats.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ Aligned.out.sam true -bsub

perl $HOME/Normalization/norm_scripts/getstats.pl $HOME/study/reads/dirs.txt $HOME/study/reads/
```

### 3. BLAST
```
perl $HOME/Normalization/norm_scripts/runall_runblast.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ Aligned.out.sam $HOME/Normalization/norm_scripts/ncbi-blast-2.2.27+/ $HOME/Normalization/norm_scripts/ncbi-blast-2.2.27+/ribomouse -bsub

perl $HOME/Normalization/norm_scripts/runall_get_ribo_percents.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ -bsub
```

### 4. Filter
```
perl $HOME/Normalization/norm_scripts/runall_filter.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ Aligned.out.sam -bsub
```

### 5. Quantify Exons

#####   a. Create Master List of Exons
```
perl $HOME/Normalization/norm_scripts/get_master_list_of_exons_from_geneinfofile.pl /opt/rna_seq/data/star_chr1and2/genes.txt $HOME/study/reads/
```
#####   b. Get novel exons
```
perl $HOME/Normalization/norm_scripts/runall_sam2junctions.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ /opt/rna_seq/data/star_chr1and2/genes.txt /opt/rna_seq/data/star_chr1and2/chr1and2.fa -samfilename Aligned.out.sam -bsub

perl $HOME/Normalization/norm_scripts/runall_get_novel_exons.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ Aligned.out.sam
```
#####   c. Filter high expressors
```
perl $HOME/Normalization/norm_scripts/runall_quantify_exons.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_exons.study.txt false -bsub

perl $HOME/Normalization/norm_scripts/runall_quantify_exons.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_exons.study.txt false -bsub -NU-only

perl $HOME/Normalization/norm_scripts/runall_get_high_expressors.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ 10 $HOME/Normalization/norm_scripts/ucsc_known_mm9 $HOME/study/reads/master_list_of_exons.study.txt -bsub

perl $HOME/Normalization/norm_scripts/filter_high_expressors.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_exons.study.txt

perl $HOME/Normalization/norm_scripts/get_percent_high_expressor.pl $HOME/study/reads/dirs.txt $HOME/study/reads/
```

#####   d. Run quantify exons
```
perl $HOME/Normalization/norm_scripts/runall_quantify_exons.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/filtered_master_list_of_exons.study.txt true -depth 3 -bsub

perl $HOME/Normalization/norm_scripts/runall_quantify_exons.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/filtered_master_list_of_exons.study.txt true -depth 3 -bsub -NU-only

perl $HOME/Normalization/norm_scripts/get_exon2nonexon_signal_stats.pl $HOME/study/reads/dirs.txt $HOME/study/reads/

perl $HOME/Normalization/norm_scripts/get_1exon_vs_multi_exon_stats.pl $HOME/study/reads/dirs.txt $HOME/study/reads/
```

### 6. Quantify Introns

##### a. Create Master List of Introns
```
perl $HOME/Normalization/norm_scripts/get_master_list_of_introns_from_geneinfofile.pl /opt/rna_seq/data/star_chr1and2/genes.txt $HOME/study/reads/
```

#####   b. Run quantify introns
```
perl $HOME/Normalization/norm_scripts/runall_quantify_introns.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_introns.txt true -depth 3 -bsub

perl $HOME/Normalization/norm_scripts/runall_quantify_introns.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_introns.txt true -depth 3 -bsub -NU-only

perl $HOME/Normalization/norm_scripts/get_percent_intergenic.pl $HOME/study/reads/dirs.txt $HOME/study/reads/
```

### 7. Downsample
```
perl $HOME/Normalization/norm_scripts/runall_head.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ -bsub -depthE 3 -depthI 3

perl $HOME/Normalization/norm_scripts/cat_headfiles.pl $HOME/study/reads/dirs.txt $HOME/study/reads/

perl $HOME/Normalization/norm_scripts/make_final_samfile.pl $HOME/study/reads/dirs.txt $HOME/study/reads/
   
cd $HOME/study/NORMALIZED_DATA
```
### 8. Junctions
```
perl $HOME/Normalization/norm_scripts/runall_sam2junctions.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ /opt/rna_seq/data/star_chr1and2/genes.txt /opt/rna_seq/data/star_chr1and2/chr1and2.fa -bsub
```

### 9. Quants/Master tables
#####   a. concatenate unique and nu normalized exonmappers
```
perl $HOME/Normalization/norm_scripts/cat_exonmappers_Unique_NU.pl $HOME/study/reads/dirs.txt $HOME/study/reads/
```
#####   b. get exonquants  
```
perl $HOME/Normalization/norm_scripts/runall_quantify_exons.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/filtered_master_list_of_exons.study.txt false -bsub
```
#####   c. get intronquants   
```
perl $HOME/Normalization/norm_scripts/runall_quantify_introns.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_introns.txt false -bsub

perl $HOME/Normalization/norm_scripts/runall_quantify_introns.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ $HOME/study/reads/master_list_of_introns.txt false -bsub -NU-only
```
#####   d. final spreadsheets
```
perl $HOME/Normalization/norm_scripts/make_final_spreadsheets.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ -bsub
```
#####   e. annotate
```
cd $HOME/study/NORMALIZED_DATA

ls list_of_exons_counts_M* > annotate.txt

perl $HOME/Normalization/norm_scripts/run_annotate.pl $HOME/study/NORMALIZED_DATA/annotate.txt $HOME/Normalization/norm_scripts/ucsc_known_mm9 $HOME/study/reads/ -bsub
```
#####   f. filter low expressors
```
cd $HOME/study/NORMALIZED_DATA

ls master_list_of_* > filter.txt

perl $HOME/Normalization/norm_scripts/runall_filter_low_expressors.pl $HOME/study/NORMALIZED_DATA/filter.txt 3 3 $HOME/study/reads/
```

### 10. Coverage plots
```
perl $HOME/Normalization/norm_scripts/runall_sam2cov.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ /opt/rna_seq/data/star_chr1and2/chr1and2.fa.fai -bsub

cd $HOME/study/NORMALIZED_DATA/FINAL_SAM/MERGED/

cat *cov > final_coverage
```

### 11. Clean up
```
perl $HOME/Normalization/norm_scripts/cleanup.pl $HOME/study/reads/dirs.txt $HOME/study/reads/

perl $HOME/Normalization/norm_scripts/runall_sam2bam.pl $HOME/study/reads/dirs.txt $HOME/study/reads/ Aligned.out.sam /opt/rna_seq/data/star_chr1and2/chr1and2.fa.fai -bsub
```