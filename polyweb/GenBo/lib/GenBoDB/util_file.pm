package util_file;
use Exporter 'import'; # gives you Exporter's import() method directly
@EXPORT_OK = qw(writeXmlVariations readXmlVariations);
use Carp;
use Data::Dumper;
use XML::Simple;
use strict;
use Storable qw(store retrieve freeze);
my $method = {
	xml => "xml",
	align => "align",
	maq => "maq",
	variations => "variations",
	indels => "indels",
#	cnvs => "cnvs",
	cnvs => "beadstd",
	raw=>"raw",
	cover=>"cover",
	cover=>"bam",
	affymetrix=>"affymetrix",
	remap=>"remaphg19"
};
my $public_dir ="/data-xfs/genome/36/";
my $root_dir =  "/data-xfs/sequencing/";
sub makedir{
	my ($dir,$name) = @_;
	my $rep = $dir."/".$name;
	if (!(-e $rep)){
		mkdir ($rep);
	}
	return $rep;	
	
} 
sub makedirAlign{
	my ($dir,$name) = @_;
	my $rep = $dir."/".$name;
	if (!(-e $rep)){
		mkdir ($rep);
		my $dir2 = $dir."/igv";
		system ("ln -s $rep  $dir2");
	}
	return $rep;	
	
} 
sub get_project_dir {
	my ($project) = @_;
	my $rep = makedir($root_dir,$project->projectType()->name());
	return makedir($rep,$project->name());
}

sub get_xml_dir {
	my ($project) = @_;
	my $dir_project = get_project_dir($project);
	return makedir($dir_project,$method->{xml});
}


sub get_align_root_dir {
	my ($project) = @_;
	my $dir_project = get_project_dir($project);
	return makedirAlign($dir_project,$method->{align});
}

sub get_cover_root_dir {
	my ($project) = @_;
	my $dir_project = get_project_dir($project);
	
	return makedir($dir_project,$method->{cover});
}

sub get_bam_root_dir {
	my ($project) = @_;
	my $dir_project = get_project_dir($project);
	
	return makedir($dir_project,$method->{cover});
}
sub get_remap_root_dir {
	my ($project) = @_;
	my $dir_project = get_project_dir($project);
	
	return makedir($dir_project,$method->{remap});
}


sub get_align_dir {
	my ($args) = @_;
	confess("manque projet") unless exists $args->{project};
 	confess("manque method") unless exists $args->{method};
	my $dir_project = get_align_root_dir($args->{project});
	
	return makedir($dir_project,$args->{method});
}


sub get_cover_dir {
	my ($args) = @_;
	 confess("manque projet") unless exists $args->{project};
 	confess("manque patient") unless exists $args->{patient_name};
	my $dir_project = get_cover_root_dir($args->{project});
	return $dir_project;
	return makedir($dir_project,$args->{patient_name});
}

sub get_bam_dir {
	my ($args) = @_;
	 confess("manque projet") unless exists $args->{project};
 
	my $dir_project = get_bam_root_dir($args->{project});
	return $dir_project;
	#return makedir($dir_project,$args->{patient_name});
}

sub get_cnvs_dir {
	my ($args) = @_;
	confess("manque projet") unless exists $args->{project};
	my $dir_project = get_cnvs_root_dir($args->{project});
	return $dir_project;
}

sub get_raw_dir {
	my ($args) = @_;
    confess("manque projet") unless exists $args->{project};
	my $dir_project = get_project_dir($args->{project});
	return makedir($dir_project,$method->{raw});
}


sub get_cnvs_raw_dir {
	my ($args) = @_;
	confess("manque projet") unless exists $args->{project};
	my $dir_project = get_raw_dir($args);
	makedir($dir_project,$method->{cnvs});
	return $dir_project."/".$method->{cnvs}."/";
}



sub get_cover_file {
	my ($args) = @_;
	
 	 confess("manque patient_name") unless exists $args->{patient_name};
 	#confess("manque chromosome_name") unless exists $args->{chromosome_name};
 	my $coverage = 20;
 	if  (exists $args->{coverage}) {
 		$coverage = $args->{coverage};
 	}
	my $dir = get_cover_dir($args);
	return $dir."/".$args->{patient_name}.".".$coverage.".cover";
	return $dir."/chr". $args->{chromosome_name}.".".$coverage.".cover";
}

sub get_stat_file {
	my ($args) = @_;
	
 	 confess("manque patient_name") unless exists $args->{patient_name};
 	confess("manque chromosome_name") unless exists $args->{chromosome_name};
	my $dir = get_cover_dir($args);
	return $dir."/chr". $args->{chromosome_name}.".stats";
}


sub get_bam_file {
	my ($args) = @_;
	
 	confess("manque patient_name") unless exists $args->{patient_name};
 
 	
	my $dir = get_bam_dir($args);
	return $dir."/".$args->{patient_name}.".bam";
}

sub get_cnv_file {
	my ($args) = @_;
 	confess("manque patient_name") unless exists $args->{patient_name};
	my $dir = get_cnvs_raw_dir($args);
	return $dir."/CNV".$args->{patient_name}.".txt";
}

sub get_gseq_file {
	my ($args) = @_;
 	confess("manque patient_name") unless exists $args->{patient_name};
	my $dir = get_align_dir($args);
	return $dir."/".$args->{patient_name}.".gseq";
}

sub get_bfa_file {
	my ($args) = @_;
	
 	confess("manque version") unless exists $args->{version};
 	confess("manque chromosome") unless exists $args->{chromosome};
 	
 	my $file = "/temporary/genome/36/chr".$args->{chromosome}->name().".bfa";
 	
	confess("file not found : $file" ) unless -e $file;
	return $file;
}

sub get_cnvs_root_dir {
	my ($project) = @_;
	 confess("manque projet") unless $project;
 	#confess("manque method") unless exists $args->{method};
 	my $dir_project = get_project_dir($project);
	return makedir($dir_project,$method->{cnvs});
}


sub get_variations_root_dir {
	my ($project) = @_;
	 confess("manque projet") unless $project;
 	#confess("manque method") unless exists $args->{method};
 	my $dir_project = get_project_dir($project);
	return makedir($dir_project,$method->{variations});
}
sub get_variations_dir {
	my ($args) = @_;
	 confess("manque projet") unless exists $args->{project};
 	confess("manque method") unless exists $args->{method};
	my $dir_project = get_variations_root_dir($args->{project});
	return makedir($dir_project,$args->{method});
}

sub get_indels_root_dir {
	my ($project) = @_;
	 confess("manque projet") unless $project;
 	#confess("manque method") unless exists $args->{method};
 	my $dir_project = get_project_dir($project);
	return makedir($dir_project,$method->{indels});
}

sub get_indels_dir {
	my ($args) = @_;
	 confess("manque projet") unless exists $args->{project};
 	confess("manque method") unless exists $args->{method};
	my $dir_project = get_indels_root_dir($args->{project});
	return makedir($dir_project,$args->{method});
}



 sub writeXmlVariations {
 	my $args = shift;
 	confess("manque projet") unless exists $args->{project};
 	confess("manque data") unless exists $args->{data};
 	confess("manque type") unless exists $args->{type};
 	confess("manque method") unless exists $args->{method};
 	
 	my $patient_name= "all";
 	if (exists ($args->{patient})) {
 	#confess("manque patient ") unless exists  ;
 	$patient_name = $args->{patient}->name();
 	}
 	my $rep  = get_dir_from_type($args);
 
 	#$rep = makedir($rep,$patient_name);
 	
	my $xml = new XML::Simple (NoAttr=>1, RootName=>'variation');
	my $data =  $xml->XMLout($args->{data});
	my $file = $rep."/". $patient_name.".store";
	store($args->{data},$file);
	warn "end store";
	#open my $fh ,'>'.$rep."/". $patient_name.".xml" || die("can't open ".$rep."/". $args->{file});
	#warn "writing results =>  ".$rep."/".$patient_name.".xml"."\n";
	#print $fh $data;
	#close ($fh);
 	
 }
 sub get_dir_from_type {
 	my ($args) = @_;
 		my $rep;
 	if ($args->{type} eq "variations") {
 	 $rep = get_variations_dir($args);
 	}
 	elsif ($args->{type} eq "indels") {
 			 $rep = get_indels_dir($args);
 	}
 	elsif ($args->{type} eq "cnvs") {
 			 $rep = get_cnvs_dir($args);
 	}
 	else {
 		confess("problem unknown type " . $args->{type});
 	}
 	return $rep;
 	
 }
 sub readXmlFromFile {
 	my ($filename) = @_;
 	warn $filename;
 
 	unless (-e $filename){
 		 die("can't open ". $filename);
 	}
 	warn "open => ".$filename;
 
 	my $fh;
 	
 	return  (XMLin($filename,SuppressEmpty =>undef, KeyAttr => ["traces"],forcearray =>  ["traces"]));
 }
 
 sub readStoreVariations {
 	my $args = shift;
 	confess("manque projet") unless exists $args->{project};
 	confess("manque type") unless exists $args->{type};
 	confess("manque method") unless exists $args->{method};
 	my $patient_name= "all";
 	if (exists ($args->{patient})) {
 	#confess("manque patient ") unless exists  ;
 	$patient_name = $args->{patient}->name();
 	}
 	
 	my $rep = get_dir_from_type($args);;
 	my $filename = $rep."/". $patient_name.".store";
 	return retrieve($filename);
 	
 }
 sub readXmlVariations {
 	my $args = shift;
 	confess("manque projet") unless exists $args->{project};
 	confess("manque type") unless exists $args->{type};
 	confess("manque method") unless exists $args->{method};
 	my $patient_name= "all";
 	if (exists ($args->{patient})) {
 	#confess("manque patient ") unless exists  ;
 	$patient_name = $args->{patient}->name();
 	}
 	
 	my $rep = get_dir_from_type($args);;
 	my $filename = $rep."/". $patient_name.".xml";
 	unless (-e $filename) {
 		warn "NO XML FOR $patient_name";
 		return [];
 	}
 	return readXmlFromFile($filename);
 }
 
 sub closeXmlFromFile {
 	my ($filename) = @_;
 	unless (-e $filename){
 		
 		 warn ("can't open ".$filename);
 		 return;
 	}
 	system ("gzip $filename");
 }
sub close_xml {
	my $args = shift;
	confess("manque projet") unless exists $args->{project};
 	confess("manque type") unless exists $args->{type};
 	confess("manque method") unless exists $args->{method};
 	my $patient_name= "all";
 	if (exists ($args->{patient})) {
 	#confess("manque patient ") unless exists  ;
 	$patient_name = $args->{patient}->name();
 	}
 	my $rep  = get_dir_from_type($args);;
 	my $filename = $rep."/". $patient_name.".xml";
 	#warn $filename;
 	closeXmlFromFile($filename);
 	return;
 	
}

sub get_cnv_public_file {
	return $public_dir."/CNVs/mix_dgv_var_toronto.bed.gz";
}


1;
