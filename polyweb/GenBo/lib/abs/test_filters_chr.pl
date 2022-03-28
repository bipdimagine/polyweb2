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


# PROFILING
# step 1: perl -d:NYTProf /data-xfs/dev/mbras/Workspace/GenBo/lib/abs/test_filters_chr.pl
# step 2: export PATH=$PATH:/bip-d/activePerl/site/bin/ 
# step 3: /bip-d/activePerl/site/bin/nytprofhtml -o nytprof -f nytprof.out


my $useBenchmark = shift;
my $count = 10;
my $dirCache = '/locdata/home/mbras/tmp/test_bitvector_4/';

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
			  'test_filters_chr'   										=> '&test_filters_chr',
			  'test_filters_genes_without_intergenic'   				=> '&test_filters_genes_without_intergenic',
			  'test_filters_genes_with_intergenic_without_coding'   	=> '&test_filters_genes_with_intergenic_without_coding',
			  'test_filters_genes_without_intergenic_without_coding'	=> '&test_filters_genes_without_intergenic_without_coding',
			  'test_filters_genes_with_intergenic_without_utr'   		=> '&test_filters_genes_with_intergenic_without_utr',
			  'test_filters_genes_without_intergenic_without_utr'   	=> '&test_filters_genes_without_intergenic_without_utr',
			  'test_filters_chr_genes_without_intergenic'   			=> '&test_filters_chr_genes_without_intergenic',
			  'test_filters_chr_genes_with_intergenic'   				=> '&test_filters_chr_genes_with_intergenic',
			  'test_filters_default_interface'   						=> '&test_filters_default_interface',
			  'test_ignore_family_1'   			=> '&test_ignore_family_1',
			  'test_ignore_family_2'   			=> '&test_ignore_family_2',
			  'test_ignore_family_3'   			=> '&test_ignore_family_3',
			  'test_ignore_patient'   			=> '&test_ignore_patient',
			  'test_ignore_multiple_patient'   	=> '&test_ignore_multiple_patient',
			  'test_ignore_family_patient'   	=> '&test_ignore_family_patient',
			  'test_exclude_patient_1'   		=> '&test_exclude_patient_1',
			  'test_exclude_patient_2'  		=> '&test_exclude_patient_2',
			  'test_exclude_patient_3'   		=> '&test_exclude_patient_3',
			  'test_exclude_patient_4'   		=> '&test_exclude_patient_4',
			  'test_ignore_exclude_patient'   	=> '&test_ignore_exclude_patient',
		}
	);
}

else {
	warn "\n### LAUNCH TESTS MODE: \n\n";
	use Test::More;
	plan tests => 19;
	test_filters_chr();
	test_filters_genes_without_intergenic();
	test_filters_genes_with_intergenic_without_coding();
	test_filters_genes_without_intergenic_without_coding();
	test_filters_genes_with_intergenic_without_utr();		# encore des soucis avec les UTR...
	test_filters_genes_without_intergenic_without_utr();	# encore des soucis avec les UTR...
	test_filters_chr_genes_without_intergenic();			
	test_filters_chr_genes_with_intergenic();	
	test_filters_default_interface();
	test_ignore_family_1();
	test_ignore_family_2();
	test_ignore_family_3();
	test_ignore_patient();
	test_ignore_multiple_patient();
	test_ignore_family_patient();
	test_exclude_patient_1();
	test_exclude_patient_2();
	test_exclude_patient_3();
	test_exclude_patient_4();
	test_ignore_exclude_patient();
}

warn "\n\n";



sub one_test {
	my ($chr_filters, $gene_filters) = @_;
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		if ($gene_filters) {
			foreach my $gene (@{$chr->getGenes($gene_filters)}) {
				foreach my $filter_name (split(',', $gene_filters)) {
					$gene->delete_variants($filter_name);
				}
				$chr->update_buffer_from_gene($gene);
			}
			$chr->update();
		}
		if ($chr_filters) {
			foreach my $filter_name (split(',', $chr_filters)) {
				$chr->delete_variants($filter_name);
			}
		}
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	return $total_var_after;
}

sub test_filters_chr {
	my ($total_var_after) = one_test('evs,evs_1p,1000genomes,1000genomes_1p', '');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_chr\n";
		warn 'OBS: '.$total_var_after.' [EXP: 176270 var]';
		ok($total_var_after == 176270, "test_filters_chr");
	}
}



sub test_filters_genes_without_intergenic {
	my ($total_var_after) = one_test('', 'intergenic');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_genes_without_intergenic\n";
		warn 'OBS: '.$total_var_after.' [EXP: 354132 var]';
		ok($total_var_after == 354132, "test_filters_genes_without_intergenic_without_utr");
	}
}



sub test_filters_genes_with_intergenic_without_coding {
	my ($total_var_after) = one_test('', 'coding');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_genes_with_intergenic_without_coding\n";
		warn 'OBS: '.$total_var_after.' [EXP: 319164 var]';
		ok($total_var_after == 319164, "test_filters_genes_with_intergenic_without_coding");
	}
}



sub test_filters_genes_without_intergenic_without_coding {
	my ($total_var_after) = one_test('', 'coding,intergenic');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_genes_without_intergenic_without_coding\n";
		warn 'OBS: '.$total_var_after.' [EXP: 314733 var]';
		ok($total_var_after == 314733, "test_filters_genes_without_intergenic_without_coding");
	}
}



sub test_filters_genes_with_intergenic_without_utr {
	my ($total_var_after) = one_test('', 'utr');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_genes_with_intergenic_without_utr\n";
		warn 'OBS: '.$total_var_after.' [EXP: 328555 var]';
		ok($total_var_after == 328555, "test_filters_genes_with_intergenic_without_utr");
	}
}



sub test_filters_genes_without_intergenic_without_utr {
	my ($total_var_after) = one_test('', 'utr,intergenic');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_genes_without_intergenic_without_utr\n";
		warn 'OBS: '.$total_var_after.' [EXP: 324124 var]';
		ok($total_var_after == 324124, "test_filters_genes_without_intergenic_without_utr");
	}
}



sub test_filters_chr_genes_without_intergenic {
	my ($total_var_after) = one_test('evs,evs_1p,1000genomes,1000genomes_1p', 'intergenic,intronic,silent,splicing,coding');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_chr_genes_without_intergenic\n";
		warn 'OBS: '.$total_var_after.' [EXP: 36836 var]';
		ok($total_var_after == 36836, "test_filters_chr_genes_without_intergenic");
	}
}



sub test_filters_chr_genes_with_intergenic {
	my ($total_var_after) = one_test('evs,evs_1p,1000genomes,1000genomes_1p', 'intronic,silent,splicing,coding');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_chr_genes_with_intergenic\n";
		warn 'OBS: '.$total_var_after.' [EXP: 39894 var]';
		ok($total_var_after == 39894, "test_filters_chr_genes_with_intergenic");
	}
}


sub test_filters_default_interface {
	my ($total_var_after) = one_test('dbsnp,dbsnp_1p,dbsnp_none,1000genomes,1000genomes_1p,evs,evs_1p', 'silent,intergenic,intronic,pseudogene');
	unless ($useBenchmark) {
		print "\n\n##### test_filters_default_interface\n";
		warn 'OBS: '.$total_var_after.' [EXP: 10722 var]';
		ok($total_var_after == 10722, "test_filters_default_interface");
	}
}



sub test_ignore_family_1 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		my @lPatients;
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P533');
			$family->setInTheAttic(1);
		}
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_family_1\n";
		warn 'OBS: '.$total_var_after.' [EXP: 187101 var]';
		ok($total_var_after == 187101, "test_ignore_family_1");
	}
} 



sub test_ignore_family_2 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P382');
			$family->setInTheAttic(1);
		}
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_family_2\n";
		warn 'OBS: '.$total_var_after.' [EXP: 148361 var]';
		ok($total_var_after == 148361, "test_ignore_family_2");
	}
} 



sub test_ignore_family_3 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		foreach my $family (@{$chr->getFamilies()}) {
			next if ($family->name() eq 'MFC-P474');
			$family->setInTheAttic(1);
		}
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_family_3\n";
		warn 'OBS: '.$total_var_after.' [EXP: 155844 var]';
		ok($total_var_after == 155844, "test_ignore_family_3");
	}
}



sub test_ignore_patient {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->getPatient('MFC-P533-3')->setInTheAttic(1);
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_patient\n";
		warn 'OBS: '.$total_var_after.' [EXP: 358202 var]';
		ok($total_var_after == 358202, "test_ignore_patient");
	}
}



sub test_ignore_multiple_patient {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->setInTheAttic('MFC-P533-1,MFC-P533-3,MFC-P382-2,MFC-P591-1,MFC-P591-2', 1);
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_multiple_patient\n";
		warn 'OBS: '.$total_var_after.' [EXP: 335421 var]';
		ok($total_var_after == 335421, "test_ignore_multiple_patient");
	}
}

sub test_ignore_family_patient {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->setInTheAttic('MFC-P533-1,MFC-P533-3,MFC-P382-2,MFC-P591-1,MFC-P591-2', 1);
		$chr->getFamily('MFC-P370')->setInTheAttic(1);
		$chr->getFamily('MFC-P405')->setInTheAttic(1);
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_family_patient\n";
		warn 'OBS: '.$total_var_after.' [EXP: 309721 var]';
		ok($total_var_after == 309721, "test_ignore_family_patient");
	}
}



sub test_exclude_patient_1 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->setExclude('MFC-P533-1,MFC-P591-1', 'all');
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_exclude_patient_1\n";
		warn 'OBS: '.$total_var_after.' [EXP: 191862 var]';
		ok($total_var_after == 191862, "test_exclude_patient_1");
	}
}



sub test_exclude_patient_2 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->setExclude('MFC-P533-1,MFC-P591-1', 'ho');
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_exclude_patient_2\n";
		warn 'OBS: '.$total_var_after.' [EXP: 296994 var]';
		ok($total_var_after == 296994, "test_exclude_patient_2");
	}
}



sub test_exclude_patient_3 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->setExclude('MFC-P533-1,MFC-P591-1', 'he');
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_exclude_patient_3\n";
		warn 'OBS: '.$total_var_after.' [EXP: 233622 var]';
		ok($total_var_after == 233622, "test_exclude_patient_3");
	}
}



sub test_exclude_patient_4 {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->getPatient('MFC-P524-2')->setExclude('all');
		$chr->getPatient('MFC-P533-1')->setExclude('ho');
		$chr->getPatient('MFC-P591-1')->setExclude('he');
		$chr->purge();
		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_exclude_patient_4\n";
		warn 'OBS: '.$total_var_after.' [EXP: 212299 var]';
		ok($total_var_after == 212299, "test_exclude_patient_4");
	}
}



sub test_ignore_exclude_patient {
	my $project = AbsProject->new(
									name => 'NGS2013_0318',
									dir_cache => $dirCache,
									typeFilters => 'individual',
								);
	my $total_var_after = 0;
	foreach my $chr (@{$project->getChromosomes()}) {
		$chr->setInTheAttic('MFC-P486-3,MFC-P5-1', 1);
		$chr->getPatient('MFC-P524-2')->setExclude('all');
		$chr->getPatient('MFC-P533-1')->setExclude('ho');
		$chr->getPatient('MFC-P591-1')->setExclude('he');
		$chr->purge();
  		$total_var_after += $chr->countVariants();
	}
	unless ($useBenchmark) {
		print "\n\n##### test_ignore_exclude_patient\n";
		warn 'OBS: '.$total_var_after.' [EXP: 210534 var]';
		ok($total_var_after == 210534, "test_ignore_exclude_patient");
	}
}