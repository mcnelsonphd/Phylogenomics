#!/usr/bin/env perl
#
# Script to take a list of genome sequences and count the kmers present.
# The input list file is a tab-delimited, one entry per line format of GenomeID:file-path pairs.
# Genome files should be in fasta/multi-fasta format.
# Output file is a tab-delimited text file named with the GenomeID
# User specifies the kmer size during execution, which will be appended to the sorted output filename (_Nmer.txt)
#
# NB: Uses jellyfish to actually count kmers due to its speed over doing so in pure perl.
#     This must be present somewhere in the users PATH in order for script to work.
#
# Created by: Michael C. Nelson
# Version: 1
# Created on: 2015-05-19
# Revised on: 2015-05-19
######################################################################################################

use strict;
use warnings;
use FindBin;
use File::Copy;
use Time::Piece;
use Time::Seconds;

###### Initial variable instancing ######
my $kmer = 12;
my $outdir;


my $starttime = localtime;
my $fp = find_exe("jellyfish");
err("Can't find Jellyfish in your \$PATH") if !$fp;

my(@Options, $cpus, $listdb, $citation);
setOptions();

msg("Began running Make_kmer_tables.pl at $starttime");

my $num_cores = num_cpu();
msg("System has $num_cores cores.");
if (!defined $cpus or $cpus < 0) {
    $cpus = 1;
}
elsif ($cpus == 0) {
    $cpus = $num_cores;
}
elsif ($cpus > $num_cores) {
    msg("Option --cpu asked for $cpus cores, but system only has $num_cores");
    $cpus = $num_cores;
}
msg("Will use maximum of $cpus cores.");

my $logfile = "$outdir/$kmer\_tables.log";
msg("Writing log to: $logfile");
open LOG, '>', $logfile or err("Can't open logfile");


###### ACTUAL WORK GETS DONE HERE ######

my $infile = open



###### Sub-routines ######
sub find_exe {
    my($bin) = shift;
    for my $dir (File::Spec->path) {
        my $exe = File::Spec->catfile($dir, $bin);
        return $exe if -x $exe;
    }
    return;
}

sub runcmd {
    msg("Running:", @_);
    system(@_)==0 or err("Could not run command:", @_);
}

sub msg {
    my $t = localtime;
    my $line = "[".$t->hms."] @_\n";
    print LOG $line if openhandle(\*LOG);
}

sub setOptions {
    use Getopt::Long;
    @Options = (
    'Mandatory:',
    {OPT=>"input=s", VAR=>\&infile, DESC=>"The input table of GenomeID:filepaths to use for analysis"},
    'Options:',
    {OPT=>"kmer=i", VAR=>\&kmer, DESC=>"The kmer to use for analysis [DEFAULT=$kmer]"},
    {OPT=>"outdir=s", VAR=>\$outdir, DEFAULT=>'', DESC=>"Output folder"},
    'Help:',
    {OPT=>"help", VAR=>\&usage, DESC=>"This help"},
    );
    
    (!@ARGV) && (usage());
    
    &GetOptions(map {$_->{OPT}, $_->{VAR}} grep { ref } @Options) || usage();
    
    # Now setup default values.
    foreach (@Options) {
        if (ref $_ && defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
            ${$_->{VAR}} = $_->{DEFAULT};
        }
    }
}

sub usage {
    print STDERR
    "\nMake_kmer_tables.pl: A jellyfish wrapper for creating kmer tables for genome sequences.\n",
    "Usage:\tMake_kmer_tables.pl [options] --input file_list.txt\n";
    foreach (@Options) {
        if (ref) {
            my $def = defined($_->{DEFAULT}) ? " [DEFAULT='$_->{DEFAULT}']" : "";
            my $opt = $_->{OPT};
            $opt =~ s/!$//;
            $opt =~ s/=s$/ [XXX]/;
            $opt =~ s/=i$/ [int]/;
            printf STDERR "  --%-15s %s%s\n", $opt, $_->{DESC}, $def;
        }
        else {
            print STDERR "$_\n";
        }
    }
    print "\n";
    exit(1);
}