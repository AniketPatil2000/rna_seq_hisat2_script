#!/usr/bin/bash

SECONDS=0

# Change working Directory
cd /mnt/a/ani_linux/pipeline/RNASeq_pipeline

# Step 1: Run Fastqc
fastqc data/demo.fastq -o data/

# Run trimmomatic to trim reads with poor quality
java -jar /mnt/a/ani_linux/tools/Trimmomatic/Trimmomatic-0.39/trimmomatic-0.39.jar SE -threads 8 /mnt/a/ani_linux/pipeline/RNASeq_pipeline/data/demo.fastq /mnt/a/ani_linux/pipeline/RNASeq_pipeline/data/demo_trimmed.fastq TRAILING:10 -phred33
echo "Trimmomatic finished running"

# Run Fastqc on trimmed data
fastqc data/demo_trimmed.fastq -o data/

# STEP 2: Run HISAT2
mkdir -p HISAT2  # Use -p to create the directory only if it doesn't exist

# Get the genome indices
wget -O HISAT2/grch38_genome.tar.gz https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz

# Extract the genome indices
tar -xf HISAT2/grch38_genome.tar.gz -C HISAT2/

# Run alignment
hisat2 -q --rna-strandness R -x HISAT2/grch38/genome -U data/demo_trimmed.fastq -p 8 | samtools sort -o HISAT2/demo_trimmed.bam
echo "HISAT2 finished running!"

samtools view -h -o HISAT2/demo_trimmed.sam HISAT2/demo_trimmed.bam

# STEP 3: Run FeatureCounts - Quantification
# Get GTF File
wget -O Homo_sapiens.GRCh38.110.gtf.gz https://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.gtf.gz

# Extract the GTF file
gunzip Homo_sapiens.GRCh38.110.gtf.gz

# Run FeatureCounts
featureCounts -s 2 -a Homo_sapiens.GRCh38.110.gtf -o quants/demo_feature_counts.txt -T 8 HISAT2/demo_trimmed.bam
echo "FeatureCounts finished running!"

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
