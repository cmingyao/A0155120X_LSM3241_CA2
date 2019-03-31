#1 Creating Required Directories for Data & Results
mkdir -p data results data/references data/references/combined
         results/fastqc results/sam results/sam/local 
         results/bam results/bam/local
         
#2 FastQC
fastqc data/*.fq -o results/fastqc 
for filename in results/fastqc/*.zip; do 
	unzip $filename
done

#3 Construting original reference genome GT
cat data/references/*.fa > data/references/combined/GT.fa

#4 Bowtie 2
bowtie2-build data/references/combined/GT.fa data/references/combined/GT
export BOWTIE2_INDEXES=$(pwd)/data/references/combined/GT
bowtie2 -x data/references/combined/GT \
		-k 3 --local --very-fast -p 4 \
		--no-unal \
		-1 data/A0155120X_1.fq \
		-2 data/A0155120X_2.fq \
		-S results/sam/local/A0155120X-local.sam

#5 Samtools- convert SAM to BAM format
for file in results/sam/local/*.sam
do
	SRR=$(basename $file .sam)
		echo $SRR
		samtools view -S -b results/sam/local/${SRR}.sam > results/bam/local/${SRR}-aligned.bam
done

#6 Samtools- sort BAM files by coordinates
for file in results/bam/local/*-aligned.bam
do
	SRR=$(basename $file -aligned.bam)
		echo $SRR
		samtools sort results/bam/local/${SRR}-aligned.bam -o results/bam/local/${SRR}-sorted.bam
done

samtools index results/bam/local/A0155120X-local-sorted.bam

#7 Samtools view- filtering FLAGs for discordant read-mate pairs
samtools view -b -F 1038 results/bam/local/A0155120X-local-sorted.bam > results/bam/local/A0155120X-local-sorted-INFLAG.bam
samtools index results/bam/local/A0155120X-local-sorted-INFLAG.bam
