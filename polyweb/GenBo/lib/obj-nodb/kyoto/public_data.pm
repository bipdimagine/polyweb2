package public_data;
use Carp;
use Data::Dumper;
use Moose;
use MooseX::Method::Signatures;
#use db_public;  
use Config::Std; 


my $files = {
			dbsnp =>"",
			evs => "",
			kg => "",
			deja_vu => "",
			exac => "",
};

has config_file  =>(
		is => 'ro',
		lazy =>1,
		builder => '_get_file_config',	
);

has 'mode' =>(
		is => 'ro',
		default => 'r',
);

has database => (
	is => 'ro',
	default => 'Polyexome',
);

has build => (
	is => 'ro',
	required=>1,
	#default => 'HG38',
);

has dbsnp => (
	is => 'ro',
	lazy =>1,
	builder => '_new_dbsnp',
	init_arg => "dbsnp",
);

has deja_vu => (
	is => 'ro',
	lazy =>1,
	builder => '_new_dejavu',
);

has 'prediction_matrix' => (
	is => 'ro',
	lazy =>1,
	
	builder => '_new_matrix',
);

has deja_vu_temp => (
	is => 'ro',
	lazy =>1,
	
	builder => '_new_dejavu_temp',
);

has evs => (
	is => 'ro',
	lazy =>1,
	builder => '_new_evs',
);

has cosmic => (
	is => 'ro',
	lazy =>1,
	builder => '_new_cosmic',
);
has 'kg' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_1kg',
);
has 'exac' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_exac',
);
has 'dbnsfp' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_dbnsfp',
);
has 'merge' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_merge',
);

has 'config' => (
	is => 'ro',
	lazy =>1,
	default => sub {
		my $self =shift;
		read_config $self->config_file => my %config;
		return \%config;
		
	}
);

method _get_file_config(){
	my ($filename) =  grep {/obj-nodb$/} @INC;
	unless ($filename) {
		($filename) =  grep {/obj-nodb\/$/} @INC;
	}
	
	unless ($filename) {
		($filename) =  grep {/obj-nodb\//} @INC;
	}
	$filename .= "/genbo.cfg";
	return $filename;
}

method _new_config () {
	
}

sub _new_annot {
	my $self = shift;
	my $dir =  $self->config->{public_data}->{$self->build}."/".$self->config->{ensembl}->{$self->build}."/".$self->database()."/";
	mkdir($dir) unless -d $dir;	
	return  $self->_new_kyoto(dir=>$dir,database_name=>"annot");
}

sub _new_matrix {
	my $self = shift;
	
	return  $self->_new_kyoto(dir=>$self->get_dir(type=>'prediction_matrix'),database_name=>"prediction_matrix",storable=>1);
	#my $dir =  $self->config->{public_data}->{$self->build}."/".$self->config->{ensembl}->{$self->build}."/".$self->database()."/";
	#warn $dir;
	die();
	#mkdir($dir) unless -d $dir;	
	#return  $self->_new_kyoto(dir=>$dir,database_name=>"protein_matrix");
	#return  $self->_new_kyoto(dir=>$dir,database_name=>"dbnsfp");
}

sub _new_dbnsfp {
	my $self = shift;
	my $dir =  $self->config->{public_data}->{$self->build}."/dbnsfp"."/".$self->config->{dbnsfp}->{version}."/";
	mkdir($dir) unless -d $dir;	
	return  $self->_new_kyoto(dir=>$dir,database_name=>"dbnsfp");
}

method get_dir(Str:$type) {
	my $root_dir = $self->config->{public_data}->{$self->build};
	#warn 'root dir: '.$root_dir;
	my $extend =  $self->config->{kyoto}->{$type};
	#warn 'extend: '.$extend;
	my $dir = $root_dir.$extend;
	#warn 'dir: '.$dir;
	#warn "\n\n";
	confess("\n\nERROR: directory $dir doesn't exist... Die.\n\n") if ((not -d $dir) and (not -l $dir));
	return $dir;
}
sub _new_exac {
	my $self = shift;
	return  $self->_new_kyoto(dir=>$self->get_dir(type=>'exac'),database_name=>"exac");
}
sub _new_evs {
	my $self = shift;
	return  $self->_new_kyoto(dir=>$self->get_dir(type=>'evs'),database_name=>"evs");
}
sub _new_cosmic {
	my $self = shift;
	return  $self->_new_kyoto(dir=>$self->get_dir(type=>'cosmic'),database_name=>"cosmic");
}
sub _new_1kg {
	my $self = shift;
	my $dir =  $self->config->{public_data}->{$self->build}."/snp/1000genomes/latest/";
	return  $self->_new_kyoto(dir=>$self->get_dir(type=>'1000genomes'),database_name=>"1000genomes");
}


sub _new_dbsnp {
	my $self = shift;
	return  $self->_new_kyoto(dir=>$self->get_dir(type=>'dbsnp'),database_name=>"dbsnp");
}

sub _new_dejavu {
	my $self = shift;
	return  $self->_new_kyoto( dir=>$self->get_dir(type=>'deja_vu')."/",database_name=>"deja_vu");
}

sub _new_dejavu_temp {
	my $self = shift;
	die();
	return  $self->_new_kyoto( $self->get_dir(type=>'deja_vu')."/".$self->database()."/temp/");
}

method _new_kyoto (Str :$dir, Str :$database_name, Str :$mode, Bool :$storable! = 0 ) {
	return db_public->new(dir=>$dir,mode=>$self->mode,name=>$database_name,storable=>$storable);
	# $self->get_chr($chr)->set($id,$value);
}

sub _new_kyoto {
	my ($self,$arg,$storable) = @_;
	die();
	return db_public->new(dir=>$arg,mode=>$self->mode,storable=>);
}

method is_public (Str :$chr, Str :$id) {
	#return defined $self->dbsnp->get(chr=>$chr,id=>$id) ;# || $self->deja_vu->get(chr=>$chr,id=>$id);
	#warn $self->kg->get(chr=>$chr,id=>$id);
	return defined $self->dbsnp->get(chr=>$chr,id=>$id) || $self->evs->get(chr=>$chr,id=>$id) || $self->kg->get(chr=>$chr,id=>$id);
}


1;
