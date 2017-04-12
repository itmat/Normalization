## CONFIGURATION FILE

### 0. NORMALIZATION and DATA TYPE

#### A. Normalization Type
PORT offers **Exon-Intron-Junction** level normalization and **Gene** level normalization. Select the normalization type by setting GENE_NORM and/or EXON_INTRON_JUNCTION_NORM to TRUE. At least one normalization type needs to be used.

#### B. Data Type
##### i. STRANDED
Set STRANDED to TRUE if the data are stranded.<br>
##### ii. FWD or REV
If STRANDED is set to TRUE, strand information needs to be provided. Set FWD to TRUE if forward read is in the same orientation as the transcripts/genes (sense) and set REV to TRUE if reverse read is in the same orientation as the transcripts/genes (sense).<br>
Note that when dUTP-based protocol (e.g. Illumina TruSeq stranded protocol) is used, strand information comes from reverse read.

#### C. Chromosome Names
#### :red_circle: __By default, PORT *ONLY* uses numbered, X or Y (e.g. chr1,chr2,...,chrX,chrY OR 1,2,...,X,Y) as standard chromosome names.__


##### i. File of chromosome names [optional]
Provide a full path to file of chromosomes names (CHRNAMES) *if your chromosome names do not follow the chromosome nomenclature described above*. For example, for dm6, the CHRNAMES file should look like this (one name per line):

    chr3R
    chr3L
    chr2R
    chrX
    chr2L
    chrY
    chr4
    chrM

>Note: Depending on the genome, it may contain clone contigs that cannot be confidently placed on a specific chromosome (e.g. chrUn) and sequences that is not in a finished state (e.g. chrN_random). We recommend excluding those \"non-standard\" chromosomes.

##### ii. Name of mitochondrial chromosome [required]
Provide a name of mitochondrial chromosome (e.g. chrM, M). If there are multiple mitochondrial chromosomes, provide a comma separated list of chromosome names.


--------------

### 1. CLUSTER INFO
If you're using SGE (Sun Grid Engine) or LSF (Load Sharing Facility), simply set the cluster name (SGE_CLUSTER or LSF_CLUSTER) to TRUE. You may edit the queue names and max_jobs.<br>
If not, use OTHER_CLUSTER option and specify the required parameters.<br><br>
For clusters which only allows job submissions from the head node, specify the job submission host name (HOST_NAME)<br>


---------------

### 2. GENE INFO
Gene information file with required suffixes need to be provided. **Gene level normalization requires an ensembl gene info file.**<br><br>The gene info file must contain column names with these suffixes: __name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, geneSymbol, ensemblToGeneName.value.__ 

ensembl gene info files for mm9, mm10, hg19, hg38, dm3 and danRer7 are available in Normalization/norm_scripts directory:

     mm9: /path/to/Normalization/norm_scripts/mm9_ensGenes.txt
     mm10: /path/to/Normalization/norm_scripts/Mus_musculus.GRCm38.84.PORT_geneinfo.txt
     hg19: /path/to/Normalization/norm_scripts/hg19_ensGenes.txt
     hg38: /path/to/Normalization/norm_scripts/Homo_sapiens.GRCh38.84.PORT_geneinfo.txt
     dm3: /path/to/Normalization/norm_scripts/dm3_ensGenes.txt
     danRer7: /path/to/Normalization/norm_scripts/danRer7_ensGenes.txt

Alternatively, you can use a perl script (**/path/to/Normalization/norm_scripts/convert_gtf_to_PORT_geneinfo.transcripts.pl**) to convert an ENSEMBL gtf file to a gene information file. 

---------------

### 3. FA and FAI
#### [1] genome fasta file

The description line (the header line that begins with ">") **MUST** begin with chromosome names that match the chromosome names in [GENE INFO](https://github.com/itmat/Normalization/blob/master/about_cfg.md#2-gene-info) file(s).

Please check and modify the file appropriately before starting PORT. 

ucsc genome FASTA files for mm9, hg19, dm3, and danRer7 are available for download (gunzip after download):

      mm9: wget http://itmat.indexes.s3.amazonaws.com/mm9_genome_one-line-seqs.fa.gz
      hg19: wget http://itmat.indexes.s3.amazonaws.com/hg19_genome_one-line-seqs.fa.gz
      dm3: wget http://itmat.indexes.s3.amazonaws.com/dm3_genome_one-line-seqs.fa.gz
      danRer7: wget http://itmat.indexes.s3.amazonaws.com/danRer7_genome_one-line-seqs.fa.gz


#### [2] index file
You can get the index file (*.fai) using [samtools](http://samtools.sourceforge.net/) (samtools faidx &lt;ref.fa>)

#### [3] samtools
Provide the location of your copy of samtools

----------------

### 4. rRNA
#### [1] rRNA_PREFILTERED
Set rRNA_PREFILTERED to TRUE if you prefiltered the ribosomal reads. When rRNA_PREFILTERED is set to TRUE, the BLAST step will be skipped and PORT will not generate percent ribosomal statistics.

#### [2] rRNA sequence fasta file
rRNA sequence file for Mammal (mm9 - **can be used for all mammal**), Drosophila melanogaster (dm), Zebrafish (danRer) and C.elegans is available in Normalization/norm_scripts directory:

      Mammal: /path/to/Normalization/norm_scripts/rRNA_mm9.fa
      Drosophila melanogaster: /path/to/Normalization/norm_scripts/rRNA_dm.fa
      Zebrafish: /path/to/Normalization/norm_scripts/rRNA_danRer.fa
      C.elegans: /path/to/Normalization/norm_scripts/rRNA_c.elegans.fa

For other organisms, get rRNA sequences and create a fasta file.

-----------------

### 5. DATA VISUALIZATION
Set SAM2COV to TRUE if you want to use sam2cov to generate coverage files. sam2cov only supports reads aligned with RUM, STAR, or GSNAP (set aligner used to TRUE). Make sure you have the latest version of sam2cov. At the moment, sam2cov assumes the strand information (sense) comes from reverse read for stranded data.

-------------------

### 6. CLEANUP
By default, CLEANUP step only deletes the intermediate SAM files. Set DELETE_INT_SAM to FALSE if you wish to keep the intermediate SAM files. You can also convert sam files to bam files by setting CONVERT_SAM2BAM to TRUE. Coverage files can be compressed by setting GZIP_COV to TRUE. 

-------------------