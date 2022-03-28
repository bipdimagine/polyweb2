package public_data;
use Carp;
use Data::Dumper;
use FindBin qw($Bin);
use Moose;
use MooseX::Method::Signatures;
use db_public;
use Config::Std; 
my $files = {
			dbsnp =>"",
			evs => "",
			kg => "",
			deja_vu => "",
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
	default => 'HG19',
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

has 'kg' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_1kg',
);

has 'annot' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_annot',
);
has 'config' => (
	is => 'ro',
	lazy =>1,
	builder => '_new_config'
);

method _get_file_config(){
	my $filename = $INC{"public_data.pm"};
	$filename =~ s/kyoto\/public_data\.pm/obj-lite\/genbo\.cfg/;
	return $filename;
}
method _new_config (){
		read_config $self->config_file => my %config;
		return \%config;
}
sub _new_annot {
	my $self = shift;
	my $dir =  $self->config->{public_data}->{HG19}."/".$self->config->{ensembl}->{HG19}."/".$self->database()."/";
	mkdir($dir) unless -d $dir;	
	return  $self->_new_kyoto($dir);
}

method get_dir(Str:$type){
	my $root_dir = $self->config->{public_data}->{HG19};
	my $extend =  $self->config->{kyoto}->{$type};
	my $dir = $root_dir.$extend;
	confess($dir) unless -d $dir;
	
	return $dir;
}
sub _new_evs {
	my $self = shift;
	
	return  $self->_new_kyoto($self->get_dir(type=>'evs'));
}

sub _new_1kg {
	my $self = shift;
	my $dir =  $self->config->{public_data}->{HG19}."/snp/1000genomes/12_2011/";
	return  $self->_new_kyoto($self->get_dir(type=>'1000genomes'));
}


sub _new_dbsnp {
	my $self = shift;
	return  $self->_new_kyoto($self->get_dir(type=>'dbsnp'));
}

sub _new_dejavu {
	my $self = shift;
	return  $self->_new_kyoto( $self->get_dir(type=>'deja_vu')."/".$self->database()."/");
}
sub _new_dejavu_temp {
	my $self = shift;
	return  $self->_new_kyoto( $self->get_dir(type=>'deja_vu')."/".$self->database()."/temp/");
}

sub _new_kyoto {
	my ($self,$arg) = @_;
	return db_public->new(dir=>$arg,mode=>$self->mode);

}

method is_public (Str :$chr, Str :$id){
	#return defined $self->dbsnp->get(chr=>$chr,id=>$id) ;# || $self->deja_vu->get(chr=>$chr,id=>$id);
	return defined $self->dbsnp->get(chr=>$chr,id=>$id) || $self->evs->get(chr=>$chr,id=>$id) || $self->deja_vu->get(chr=>$chr,id=>$id);
}
1;