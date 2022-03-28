package kyoto_database;
use Moose;
use KyotoCabinet;
use Data::Dumper;




has 'file' => (
	is =>'rw',
	isa =>"Str",
	required => 1,
);

has 'mode' => (
	is =>'rw',
	isa =>"Str",
	default => 'r',
	
);

has 'db' => (
	is => 'ro',
	lazy=> 1,
	builder => '_open_kyoto',
);


 has 'kyoto' => (
      traits    => ['Hash'],
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      handles   => {
          set_option     => 'set',
          get_option     => 'get',
          has_no_options => 'is_empty',
          num_options    => 'count',
          delete_option  => 'delete',
          option_pairs   => 'kv',
      },
  );

sub _open_kyoto {
	my $self = shift;
	my $db1 = new KyotoCabinet::DB;
 
	# open the database
	if ($self->mode eq 'r') {
		if (!$db1->open($self->file, $db1->ONOLOCK | $db1->OREADER)) {
			printf STDERR ("open error:  %s\n".$self->file(), $db1->error);
		}
	}

	elsif ($self->mode eq 'w'){
		warn $self->file;
		if (!$db1->open($self->file, $db1->OWRITER |  $db1->OCREATE )) {
			printf STDERR ("open error: %s\n", $db1->error);
		}
	}

	elsif ($self->mode eq 'c'){ 
		if (!$db1->open($self->file, $db1->OWRITER |  $db1->OCREATE | $db1->OTRUNCATE )) {
			warn "TRUNC";
			printf STDERR ("open error: %s\n", $db1->error);
		}
	}
	return $db1;
}

sub get_bulk {
	my ($self, $arg) = @_;
	$self->db->get_bulk($arg);
}

sub get {
	my ($self, $arg) = @_;
	$self->db->get($arg);
}

sub set {
	my ($self, $k, $v) = @_;
	$self->db->set($k,$v);
}

sub print_all {
	my ($self) = @_;
	my $cur = $self->db->cursor;
	$cur->jump;
	while (my ($key, $value) = $cur->get(1)) { printf("%s:%s\n", $key, $value); }
	$cur->disable;
}

1;