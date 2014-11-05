## CONFIGURATION FILE

###0. NORMALIZATION and DATA TYPE
####A. Normalization Type
PORT offers **Exon-Intron-Junction** level normalization and **Gene** level normalization. Select the normalization type by setting GENE_NORM and/or EXON_INTRON_JUNCTION_NORM to TRUE. At least one normalization type needs to be used.
####B. Data Type
#####i. STRANDED
Set STRANDED to TRUE if the data are stranded.<br>
#####ii. FWD or REV
If STRANDED is set to TRUE, strand information needs to be provided. Set FWD to TRUE if forward read is in the same orientation as the transcripts/genes (sense) and set REV to TRUE if reverse read is in the same orientation as the transcripts/genes (sense).<br>
Note that when dUTP-based protocol (e.g. Illumina TruSeq stranded protocol) is used, strand information comes from reverse read.

========================================================================================================

###1. CLUSTER INFO
If you're using SGE (Sun Grid Engine) or LSF (Load Sharing Facility), simply set the cluster name (SGE_CLUSTER or LSF_CLUSTER) to TRUE. You may edit the queue names and max_jobs.<br>
If not, use OTHER_CLUSTER option and specify the required parameters.

========================================================================================================

###2. GENE INFO
Gene information file with required suffixes need to be provided. You may use the same file for [1] and [2].
####[1] Gene information file for [Gene Normalization]
Gene normalization requires an ensembl gene info file. The gene info file must contain column names with these suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value. 

ensembl gene info files for mm9, hg19, and dm3 are available in Normalization/norm_scripts directory:

      mm9: /path/to/Normalization/norm_scripts/mm9_ensGenes.txt
      hg19: /path/to/Normalization/norm_scripts/hg19_ensGenes.txt
      dm3: /path/to/Normalization/norm_scripts/dm3_ensGenes.txt

####[2] Gene information file for [Exon-Intron-Junction Normalization]
Gene info file must contain column names with these suffixes: chrom, strand, txStart, txEnd, exonStarts, and exonEnds. 

ucsc gene info files for mm9, hg19, and dm3 are available for download:

      mm9: wget http://itmat.indexes.s3.amazonaws.com/mm9_ucsc_gene_info_header.txt
      hg19: wget http://itmat.indexes.s3.amazonaws.com/hg19_ucsc_gene_info_header.txt
      dm3: wget http://itmat.indexes.s3.amazonaws.com/dm3_ucsc_gene_info_header.txt

####[3] Annotation file for [Exon-Intron-Junction Normalization]
This file should be downloaded from UCSC known-gene track. This file must contain column names with these suffixes: name, chrom, exonStarts, exonEnd, geneSymbol, and description. 

Annotation files for mm9 and hg19 are available in Normalization/norm_scripts directory:

      mm9: /path/to/Normalization/norm_scripts/ucsc_known_mm9
      hg19: /path/to/Normalization/norm_scripts/ucsc_known_hg19

========================================================================================================

###3. FA and FAI
####[1] genome sequence one-line fasta file

ucsc genome fa files for mm9, hg19, and dm3 are available for download :

      mm9: wget http://itmat.indexes.s3.amazonaws.com/mm9_genome_one-line-seqs.fa
      hg19: wget http://itmat.indexes.s3.amazonaws.com/hg19_genome_one-line-seqs.fa
      dm3: wget http://itmat.indexes.s3.amazonaws.com/dm3_genome_one-line-seqs.fa

For other organisms, follow the instructions [here](https://github.com/itmat/rum/wiki/Creating-indexes) to create indexes.

####[2] index file
You can get the index file (*.fai) using [samtools](http://samtools.sourceforge.net/) (samtools faidx &lt;ref.fa>)

========================================================================================================

###4. DATA VISUALIZATION
Set SAM2COV to TRUE if you want to use sam2cov to generate coverage files. sam2cov only supports reads aligned with RUM or STAR (set aligner used to TRUE). Make sure you have the latest version of sam2cov. At the moment, sam2cov assumes the strand information (sense) comes from reverse read for stranded data.

========================================================================================================

###5. CLEANUP
By default, CLEANUP step only deletes the intermediate SAM files. Set DELETE_INT_SAM to FALSE if you wish to keep the intermediate SAM files. You can also convert sam files to bam files by setting CONVERT_SAM2BAM to TRUE and coverage files can be compressed by setting GZIP_COV to TRUE. 

========================================================================================================