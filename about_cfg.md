## CONFIGURATION FILE

###0. NORMALIZATION and DATA TYPE
####A. Normalization Type
PORT offers **Exon-Intron-Junction** level normalization and **Gene** level normalization. Select the normalization type by setting GENE_NORM and/or EXON_INTRON_JUNCTION_NORM to TRUE. At least one normalization type needs to be used.
####B. Stranded Data
#####i. STRANDED
Set STRANDED to TRUE if the data is stranded.<br>
#####ii. FWD or REV
If STRANDED is set to TRUE, strand information needs to be provided. Set FWD to TRUE if forward read is in the same orientation as the transcripts/genes and set REV to TRUE if reverse read is in the same orientation as the transcripts/genes.<n><n>
Note that when dUTP-based protocol (e.g. Illumina TruSeq stranded protocol) is used, strand information comes from reverse read.

========================================================================================================

###1. CLUSTER INFO
If you're using SGE (Sun Grid Engine) or LSF (Load Sharing Facility), simply set the cluster name (SGE_CLUSTER or LSF_CLUSTER) to TRUE. You may edit the queue names and max_jobs.<br>
If not, use OTHER_CLUSER option and specify the required parameters.

========================================================================================================

###2. GENE INFO
Gene information file with required suffixes need to be provided. You may use the same file for [1] and [2].
####[1] Gene information file for [Gene Normalization]
Gene normalization requires an ensembl gene info file. The gene info file must contain columns with these suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value. 

ensGenes files for mm9, hg19, and dm3 are available in Normalization/norm_scripts directory:

      mm9: /path/to/Normalization/norm_scripts/mm9_ensGenes.txt
      hg19: /path/to/Normalization/norm_scripts/hg19_ensGenes.txt
      dm3: /path/to/Normalization/norm_scripts/dm3_ensGenes.txt

####[2] Gene information file for [Exon-Intron-Junction Normalization]
Gene info file must contain columns with these suffixes: chrom, strand, txStart, txEnd, exonStarts, and exonEnds. 

ucsc gene info files for mm9, hg19, and dm3 are available for download:

      mm9: http://itmat.indexes.s3.amazonaws.com/mm9_ucsc_gene_info_header.txt
      hg19: http://itmat.indexes.s3.amazonaws.com/hg19_ucsc_gene_info_header.txt
      dm3: http://itmat.indexes.s3.amazonaws.com/dm3_ucsc_gene_info_header.txt

####[3] Annotation file for [Exon-Intron-Junction Normalization]
This file should be downloaded from UCSC known-gene track including the following suffixes: name, chrom, exonStarts, exonEnd, geneSymbol, and description. 

Annotation files for mm9 and hg19 are available in Normalization/norm_scripts directory:

      mm9: /path/to/Normalization/norm_scripts/ucsc_known_mm9
      hg19: /path/to/Normalization/norm_scripts/ucsc_known_hg19

========================================================================================================

###3. FA and FAI
####[1] genome sequence one-line fasta file

ucsc genome fa files for mm9, hg19, and dm3 are available for download :

      mm9: http://itmat.indexes.s3.amazonaws.com/mm9_genome_one-line-seqs.fa
      hg19: http://itmat.indexes.s3.amazonaws.com/hg19_genome_one-line-seqs.fa
      dm3: http://itmat.indexes.s3.amazonaws.com/dm3_genome_one-line-seqs.fa

Follow the instructions [here](https://github.com/itmat/rum/wiki/Creating-indexes) to create indexes.

####[2] index file
You can get fai file using [samtools](http://samtools.sourceforge.net/) (samtools faidx &lt;ref.fa>)

========================================================================================================

###4. DATA VISUALIZATION
Set SAM2COV to TRUE if you want to use sam2cov to generate coverage files. sam2cov only supports reads aligned with RUM or STAR (this information also needs to be specified). Make sure you have the latest version of sam2cov. At the moment, sam2cov assumes the strand information comes from reverse read for stranded data.