#!/usr/bin/perl

use strict;
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/";
use strict;
use AbsProject;
use Getopt::Long;
use Benchmark;

my $useBenchmark = shift;
my $count = 10;
my $dirCache = '/locdata/home/mbras/tmp/test_bitvector_3/';

GetOptions(
	'benchmark!'	=> \$useBenchmark,
	'count=s'  		=> \$count,
	'dirCache=s'	=> \$dirCache,
);

if ($useBenchmark) {
	warn "\n### LAUNCH BENCHMARK MODE: \n\n";
	timethese(
		$count,
		{
			  'test_individual_compound'   	=> '&test_individual_compound',
			  'test_individual_recessif'   	=> '&test_individual_recessif',
			  'test_familial_dominant'   	=> '&test_familial_dominant',
			  'test_familial_dominant_2'	=> '&test_familial_dominant_2',
			  'test_familial_denovo'   		=> '&test_familial_denovo',
			  'test_familial_denovo_2'   	=> '&test_familial_denovo_2',
			  'test_familial_recessif_1'   	=> '&test_familial_recessif_1',
			  'test_familial_recessif_2'   	=> '&test_familial_recessif_2',
			  'test_familial_recessif_3'   	=> '&test_familial_recessif_3',
			  #'test_familial_compound'   	=> '&test_familial_compound',
		}
	);
}

else {
	warn "\n### LAUNCH TESTS MODE: \n\n";
	use Test::More;
	plan tests => 11;
	
	test_individual_compound();		# -> TRES Proche !
	test_individual_recessif();		# -> TRES Proche !
	test_familial_dominant();		# -> OK !!!
	test_familial_dominant_2();		# -> OK !!!
	test_familial_denovo();			# -> OK !!!
	test_familial_denovo_2();		# -> OK !!!
	test_familial_recessif_1();		# -> OK !!!
	test_familial_recessif_2();		# -> OK !!!
	test_familial_recessif_3();		# -> OK !!!
	#test_familial_compound();
}

warn "\n\n";



sub test_individual_compound {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'individual',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	my $nb_genes_init = 0;
	my $nb_genes_end = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$nb_genes_init += scalar(@{$chr->getGenes});
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		foreach my $patient (@{$chr->getPatients()}) {
			next if ($patient->name() =~ /MFC-P370/);
			$patient->setInTheAttic(1);
		}
		$project->filters->apply_model_compound($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		$nb_genes_end += scalar(@{$chr->getGenes});
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_individual_compound\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP: 150261]';
		warn "NB GENES INIT: ".$nb_genes_init;
		warn "NB GENES END: ".$nb_genes_end;
		ok($total_var_after == 150208, "test_individual_compound Version Stable");
		ok($total_var_after == 150261, "test_individual_compound Ancienne Interface");
	}
}



sub test_individual_recessif {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'individual',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	my $nb_genes_init = 0;
	my $nb_genes_end = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$nb_genes_init += scalar(@{$chr->getGenes});
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		foreach my $patient (@{$chr->getPatients()}) {
			next if ($patient->name() =~ /MFC-P370/);
			$patient->setInTheAttic(1);
		}
		$project->filters->apply_model_recessif($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		$nb_genes_end += scalar(@{$chr->getGenes});
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_individual_recessif\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP: 151932]';
		warn "NB GENES INIT: ".$nb_genes_init;
		warn "NB GENES END: ".$nb_genes_end;
		ok($total_var_after == 151087, "test_individual_recessif Version Stable");
		ok($total_var_after == 151932, "test_individual_recessif Ancienne Interface");
	}
}



sub test_familial_recessif_1_old {
	print "\n\n##### test_familial_recessif_1\n";
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		#foreach my $family (@{$chr->getFamilies()}) {
		#	next if ($family->name() eq 'MFC-P533');
		#	$family->setInTheAttic(1);
		#}
		my $toto;
		#my $nbVar_init = $chr->countVariants();
		#$total_var_init += $nbVar_init;
		#$chr->delete_variants($chr->getCategory("dbsnp"));
		#$project->filters->apply_model_recessif($chr);
		
		#my $nbVar_after = $chr->countVariants();
		#$total_var_after += $nbVar_after;
	#warn $chr->name." ".scalar(@{$chr->getGenes});
	#my $toto = ;
	
		foreach my $gene (@{$chr->getGenes()}) {
		#	$gene->getCategory("intronic");
			$gene->delete_variants("intronic");
			next if $gene->is_empty;
			#$gene->delete_variants($gene->getCategory("coding"));
			
		}
		warn "end";
	#	warn $chr->name." ".scalar(@{$chr->getGenes});
		
		$chr->purge();
		
	}
	die;
	warn 'TOTAL NO FILTER: '.$total_var_init;
	warn 'OBS: '.$total_var_after.' [EXP 6042 var for this fam]';
	ok($total_var_after == 6042, "test_familial_recessif_1");
}



sub test_familial_recessif_1 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P533');
			$family->setInTheAttic(1);
		}
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		$project->filters->apply_model_recessif($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_recessif_1\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP 6042 var for this fam]';
		ok($total_var_after == 6042, "test_familial_recessif_1");
	}
}



sub test_familial_recessif_2 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P382');
			$family->setInTheAttic(1);
		}
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		$project->filters->apply_model_recessif($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_recessif_2\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP 4793 var for this fam]';
		ok($total_var_after == 4793, "test_familial_recessif_2");
	}
}



sub test_familial_recessif_3 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P474');
			$family->setInTheAttic(1);
		}
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		$project->filters->apply_model_recessif($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_recessif_3\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP 5409 var for this fam]';
		ok($total_var_after == 5409, "test_familial_recessif_3");
	}
}



sub test_familial_compound {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P486');
			$family->setInTheAttic(1);
		}
		$project->filters->apply_model_compound($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_compound\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after;
		#ok($total_var_after == , "test_familial_compound");
	}
}



sub test_familial_dominant {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		$project->filters->apply_model_dominant($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_dominant\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP: 26260 var]';
		ok($total_var_after == 26260, "test_familial_dominant");
	}
}



sub test_familial_dominant_2 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P370');
			$family->setInTheAttic(1);
		}
		$project->filters->apply_model_dominant($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_dominant_2\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP: 2517 var]';
		ok($total_var_after == 2517, "test_familial_dominant_2");
	}
}


sub test_familial_denovo {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		$project->filters->apply_model_denovo($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_denovo\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP: 26260 var]';
		ok($total_var_after == 26260, "test_familial_denovo");
	}
}


sub test_familial_denovo_2 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => '/locdata/home/mbras/tmp/test_bitvector_2/',
									typeFilters => 'familial',
								);
	my $total_var_init = 0;
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		my $nbVar_init = $chr->countVariants();
		$total_var_init += $nbVar_init;
		
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P370');
			$family->setInTheAttic(1);
		}
		$project->filters->apply_model_denovo($chr);
		
		my $nbVar_after = $chr->countVariants();
		$total_var_after += $nbVar_after;
		
		$chr->purge();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_familial_denovo_2\n";
		warn 'TOTAL NO FILTER: '.$total_var_init;
		warn 'OBS: '.$total_var_after.' [EXP: 2517 var]';
		ok($total_var_after == 2517, "test_familial_denovo_2");
	}
}