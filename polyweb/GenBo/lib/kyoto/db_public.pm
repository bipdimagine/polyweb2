package db_public;

use Moose;
use MooseX::Method::Signatures;
use Data::Printer;
use kyoto_database;

has 'dir' => (
	is =>'rw',
	isa =>"Str",
	required => 1,
);


has 'mode' =>(
		is => 'ro',
		default => 'r',
		
);

has 'db' => (
      traits    => ['Hash'],
      is        => 'rw',
      isa       => 'HashRef[kyoto_database]',
      lazy =>1,
      default   => \&init,
    handles   => {
#          set_option     => 'set',
          get_chr     => 'get',
#          has_no_options => 'is_empty',
#          num_options    => 'count',
#          delete_option  => 'delete',
           get_all_chrs   => 'keys',
          exists_chr => 'exists',
     },
  );
  

method init {

	my @chrs = (1..22,'X','Y','MT','all');
	my $db;

	foreach my $chr (@chrs){
		
		$db->{$chr} = kyoto_database->new(mode=>$self->mode,file => $self->dir."/$chr.kct");
	}
	
	return $db;
}


method get (Str :$chr, Str :$id) {
	
	 $self->get_chr($chr)->get($id);
}

method get_bulk(Str :$chr, ArrayRef :$ids) {
	
	 $self->get_chr($chr)->get_bulk($ids);
}
method set (Str :$chr, Str :$id, Str :$value){
	 $self->get_chr($chr)->set($id,$value);
}

method print_all (Str :$chr) {

	#foreach my $chr ($self->get_chrs){
	
		$self->get_chr($chr)->print_all();
	#}
}
1;