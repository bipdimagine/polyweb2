#!/usr/bin/perl

use strict;
use Data::Dumper;
use Getopt::Long;
use Spreadsheet::WriteExcel;
use FindBin qw($Bin);
use lib "$Bin/";
use strict;
use AbsProject;
use Parallel::ForkManager;


my $project = AbsProject->new(projectName => 'NGS2013_0318');
warn "\n\nSPECIAL FILTERS GENES:\n";
warn Dumper $project->special_filters_genes();
warn "\n\nSPECIAL FILTERS CHROMOSOMES:\n";
warn Dumper $project->special_filters_chromosomes();

### TODO: faire une method qui donne 2 hash filtre_normaux, filtres_speciaux

$project->dir_cache('/locdata/home/mbras/tmp/test_bitvector_2/');

my $total_var = 0;
my $total_var_filter_chr = 0;
my $total_var_filter_pat = 0;
my $total_var_filter_all = 0;
my $nbGene_initial = 0;
my $nbGene_chr_filters = 0;
my $nbGene_gene_filters = 0; 
foreach my $chr (@{$project->getChromosomes()}) {
	my $nbVar = $chr->countVariants();
	warn $chr->name().'  ->  init: '.$nbVar.' var';
	$total_var += $nbVar;
	$nbGene_initial += scalar(@{$chr->getGenes()});
	
	$chr->delete_variants($chr->getCategory('evs'));
	$chr->delete_variants($chr->getCategory('evs_1p'));
	$chr->delete_variants($chr->getCategory('1000genomes'));
	$chr->delete_variants($chr->getCategory('1000genomes_1p'));
	
	$total_var_filter_chr += $chr->countVariants();
	
	#$chr->delete_variants($chr->getPatient('MFC-P533-3')->getAll());
	#$chr->delete_variants($chr->getPatient('MFC-P474-2')->getHo());
	#$chr->delete_variants($chr->getPatient('MFC-P5-3')->getHe());

	#$chr->delete_variants($chr->getFamily('MFC-P533')->getAll());
	
	$total_var_filter_pat += $chr->countVariants();
	$nbGene_chr_filters += scalar(@{$chr->getGenes()});
	
#	foreach my $gene (@{$chr->getGenes()}) {
#		$gene->delete_variants($gene->getCategory('intronic'));
#		next if $gene->is_empty();
#		$gene->delete_variants($gene->getCategory('silent'));
#		next if $gene->is_empty();
#		$gene->delete_variants($gene->getCategory('splicing'));
#		next if $gene->is_empty();
#		$gene->delete_variants($gene->getCategory('coding'));
#		next if $gene->is_empty();
#		$chr->add_buffer_variants($gene);
#	}
#	$chr->update();
	$total_var_filter_all += $chr->countVariants();
	$nbGene_gene_filters += scalar(@{$chr->getGenes()});
}

warn "\n";
warn 'PROJECT NAME: '.$project->getProjectName();
warn 'TOTAL BEFORE FILTER: '.$total_var;
warn 'TOTAL AFTER FILTER: '.$total_var_filter_all;
warn '   -> Nb variants supressed from chr filters: '.$total_var_filter_chr;
warn '   -> Nb variants supressed from patients filters: '.$total_var_filter_pat;
warn '   -> Nb variants supressed from gene filters: '.$total_var_filter_all;
warn "\n\n";
warn 'NB Gene initial: '.$nbGene_initial;
warn 'NB Gene after chr filters: '.$nbGene_chr_filters;
warn 'NB Gene after genes filters: '.$nbGene_gene_filters;

#warn Dumper sort keys %{$project->objects()->{families}}; die;

#warn "\n\nSTATS:\n";
#warn Dumper $project->getStats();

#warn "\n\nCONFIG:\n";
#warn Dumper $project->config();

#warn Dumper sort keys $project->getChromosome('1')->categories_available();
#warn "\n";
#warn Dumper sort keys $project->getChromosome('5')->getGene('ENSG00000145919_5')->categories_available();
#warn "\n";
#warn Dumper sort keys $project->getChromosome('5')->setPatients();

#warn '-> Family: ';
#warn $project->getChromosome('5')->getFamily('MFC-P533');
#warn Dumper $project->getChromosome('5')->getFamily('MFC-P533')->categories_available();
#warn $project->getChromosome('5')->getFamily('MFC-P533')->getCategory('ho');
#warn ref($project->getChromosome('5')->getFamily('MFC-P533')->getCategory('ho')->getVariants());

# TODO: ne pas oublier getFamily, retirere var du'une famille;