package kyoto_database_storable;
use Moose;
use Storable qw/thaw/;
use Data::Dumper;
use KyotoCabinet;
extends (qw(kyoto_database));


sub get_bulk {
	my ($self,$arg) = @_;
	confess();
	$self->db->get_bulk($arg);
}
sub get {
	my ($self,$arg) = @_;
	thaw $self->db->get($arg);
}


sub set {
	my ($self,$k,$v) = @_;
	$self->db->set($k,freeze $v);
}






sub print_all {
my ($self) = @_;
my $cur = $self->db->cursor;
 $cur->jump;
 while (my ($key, $value) = $cur->get(1)) {
 		
     printf("%s:%s\n", $key,Dumper thaw $value);
    
 }
 $cur->disable;
}

1;