library(vegan)
library(ape)
library(data.table)

#0: Remove all previous data instanced
rm(kmer_counts, kmer_dist, kmer_hclust, tmp, table_list, files, kmers, tmp)

#1: Set the working directory and get the list of files present that match the pattern we want.
setwd('/Volumes/Pegasus_RAID/Graf_lab/MNelson/Genomes/phylogenomics/Bacteroidales/5mers')
files <- list.files(pattern='mers.txt')

#2: Create a list of data frames for all of the files we found.
table_list <- lapply(files, fread)

#3: Now make one big, combined data frame from all of the individual ones, with kmer being the merging column.
tmp <- Reduce(function(x, y) merge.data.frame(x, y, by = 'kmer', all=TRUE), table_list)
if(any(is.na(tmp))) {tmp[is.na(tmp)] <- 0 } # check if any cell is NA which we need to set to 0, doing this now is faster than after we transpose

#4: The combined data frame is in the opposite orientation, so now we need to fix that before analyzing.
kmers<-tmp$kmer
kmer_counts <- as.data.frame(t(tmp[-1]))
colnames(kmer_counts) <- kmers
any(is.na(kmer_counts))
#kmer_counts[is.na(kmer_counts)] <- 0
rm (files, table_list, tmp, kmers)

#5: Now we can analyze our kmer table.
kmer_dist<-vegdist(kmer_counts)
kmer_hclust<-hclust(kmer_dist)
plot(kmer_hclust)
