package db_public;

use Moose;
use MooseX::Method::Signatures;
use Data::Dumper;
use Data::Printer;
#use kyoto_database;
#use kyoto::kyoto_database_storable;

has 'dir' => (
	is =>'rw',
	isa =>"Str",
	required => 1,
);


has 'mode' =>(
		is => 'ro',
		default => 'r',
		
);

has storable =>(
		is =>'ro',
		isa =>"Bool",
		default => 0,
		
);

has 'name' =>(
	is =>'rw',
	isa =>"Str",
	required => 1,
);

has 'db' => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[kyoto_database]',
    lazy =>1,
    default   => \&init,
    handles   => {
#       set_option     => 'set',
    	get_chr        => 'get',
#       has_no_options => 'is_empty',
#       num_options    => 'count',
#       delete_option  => 'delete',
		get_all_chrs   => 'keys',
		exists_chr     => 'exists',
	},
);
  

method init {
	my @chrs = (1..22,'X','Y','MT','all');
	my $db;
	foreach my $chr (@chrs){
		if ($self->storable){
		
			$db->{$chr} = kyoto_database_storable->new(mode=>$self->mode,file => $self->dir."/$chr.kct");
		}
		else {
			$db->{$chr} = kyoto_database->new(mode=>$self->mode,file => $self->dir."/$chr.kct");
		}
	}
	return $db; 
}


method get (Str :$chr, Str :$id) {
	#return $self->db->{"chr"}->get($id);
	 $self->get_chr($chr)->get($id);
}

method get_indel(Str :$chr, Str :$id, Str :$sequence){
	my $var = $self->get_variation(chr=>$chr,id=>$id);
	if (scalar(keys(%$var)) == 0) {
		my %none;
		return \%none;
	}
	for (my $i =0;$i<@{$var->{seq_array}};$i++){
		if ($self->isSameIndel(seq1=>$var->{seq_array}->[$i], seq2=>$sequence, id=>$id) ) {
			$var->{seq} = $var->{seq_array}->[$i];
			return $var;
		}
	}
	my %none;
	return \%none;
}

method isSameIndel (Str :$seq1, Str :$seq2, Str :$id){
	my $lcid = lc($id);
	if ($lcid =~ /ins/ ){ return $seq1 eq $seq2; }
	else { return length($seq1) eq length($seq2); }
}

method get_variation (Str :$chr, Str :$id) {
	return unless $self->db->{"$chr"};
	my $str = $self->db->{"$chr"}->get($id);
	
	my %none;
	return \%none unless defined($str);
	my $var;
	$var->{dbname} = $self->name;
	($var->{seq}, $var->{rs}, $var->{freq}, $var->{clinical}) = split(":", $str);
	foreach my $k (keys %$var){
		delete $var->{$k} if $var->{$k} eq "-" || $var->{$k} eq '';   
	} 
	my @toto = split(";",$var->{seq});
	$var->{seq_array} = \@toto;
	#$var->{dbname} = "dbsnp" if exists $var->{rs};
	$var->{dbname} = "pheno_snp" if exists $var->{clinical};
	return $var;
}

method get_bulk(Str :$chr, ArrayRef :$ids) {
	
	 $self->get_chr($chr)->get_bulk($ids);
}
method set (Str :$chr, Str :$id, Str :$value){
	warn $chr unless $self->get_chr($chr); 
	 $self->get_chr($chr)->set($id,$value);
}

method print_all (Str :$chr) {

	#foreach my $chr ($self->get_chrs){
	
		$self->get_chr($chr)->print_all();
	#}
}
1;