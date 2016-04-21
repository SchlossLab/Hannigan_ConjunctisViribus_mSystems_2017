#!/bin/bash
# PrepareProtClusters.sh
# Geoffrey Hannigan
# Pat Schloss Lab
# University of Michigan

#PBS -N PrepareProtClusters
#PBS -A pschloss_flux
#PBS -q flux
#PBS -l qos=flux
#PBS -l nodes=1:ppn=12,mem=64GB
#PBS -l walltime=100:00:00
#PBS -j oe
#PBS -V

################
# Load Modules #
################

module load R/3.2.2

#################
# Set Variables #
#################

# Paths
export WorkingDirectory=/scratch/pschloss_flux/ghannig/git/Hannigan-2016-ConjunctisViribus/data
export FigureDir=/scratch/pschloss_flux/ghannig/git/Hannigan-2016-ConjunctisViribus/figures
export Output='PrepareProtClusters'
export BinPath=/scratch/pschloss_flux/ghannig/git/Hannigan-2016-ConjunctisViribus/bin/
export BigBin=/scratch/pschloss_flux/ghannig/bin/

# Files
export PhageDat=/scratch/pschloss_flux/ghannig/git/Hannigan-2016-ConjunctisViribus/data/phageSVA.dat
export BacteriaDat=/scratch/pschloss_flux/ghannig/git/Hannigan-2016-ConjunctisViribus/data/bacteriaSVA.dat

# Should we run the benchmarking scripts?
export Benching=false

###########
# Set Env #
###########

cd ${WorkingDirectory} || exit
mkdir ./${Output}

###################
# Set Subroutines #
###################

GetGeneFasta () {
	# 1 = Name
	# 2 = Input dat

	perl ${BinPath}dat2fasta.pl \
		-d "${2}" \
		-f ./${Output}/"${1}"Prot.fa \
		-p \
		-g

	sed -i 
}

ClusterProteins () {
	# 1 = Name
	# 2 = Input Fasta
	# 3 = Similarity Cutoff Threshold (Default should be 0.9)

	${BigBin}cd-hit-v4.6.5-2016-0304/cd-hit \
		-i "${2}" \
		-o ./${Output}/"${1}"Clustered.fa \
		-c "${3}" \
		-M 64000 \
		-T 8 \
		-d 0

	perl -p -i -e 's/ /_/g' ./${Output}/"${1}"Clustered.fa #Hmmmmm pie
}

GetClusteringStats () {
	# 1 = Input File

	# Remove the file that will be appended to
	rm ./${Output}/BenchmarkingCounts.tsv

	for int in $(seq 0.6 0.05 1); do
		# Get the clusters
		ClusterProteins \
			"Benchmark" \
			"${1}" \
			"${int}"

		# Get how many sequences are in the file
		wc -l ./${Output}/BenchmarkClustered.fa \
			| sed 's/ \+/\t/' \
			| awk -v num="$int" '{print num"\t"$1/2}' \
			>> ./${Output}/BenchmarkingCounts.tsv
	done

	# Plot the results
	Rscript ${BinPath}PlotClusterBenchmark.R \
		-i ./${Output}/BenchmarkingCounts.tsv \
		-o ${FigureDir}/"${2}"BenchmarkingCounts.png
}

export -f GetGeneFasta
export -f ClusterProteins
export -f GetClusteringStats

################
# Run Analysis #
################

GetGeneFasta \
	"Phage" \
	${PhageDat}

GetGeneFasta \
	"Bacteria" \
	${BacteriaDat}

ClusterProteins \
	"Phage" \
	./${Output}/PhageProt.fa \
	0.9

ClusterProteins \
	"Bacteria" \
	./${Output}/BacteriaProt.fa \
	0.9

if [ "$Benching" = true ] ; then

	GetClusteringStats \
		./${Output}/PhageProt.fa \
		"Phage"
	
	GetClusteringStats \
		./${Output}/BacteriaProt.fa \
		"Bacteria"

fi
