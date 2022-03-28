=head1 NAME

GenBoCnvsQuery : 

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoCnvsQuery provides a set of functions to deal with cnv public 

=head1 METHODS

=cut
 

package GenBoCnvsQuery;

 
use strict;
use Carp;
use Data::Dumper;
use util_file;



=head2 getCnvsPublic
	Title   : getCnvsPublic
 	Usage   : getCnvsPublic::
 	Function: Insert data from Json format in the CACHE_ELECTRO table of the database
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub getCnvsPublic {
	my ($dbh,$chr_name,$start,$end) = @_;
	$chr_name= "chr".$chr_name;
	my $file_cnv  = util_file::get_cnv_public_file();
	my $cmd =  "tabix $file_cnv $chr_name:$start-$end" ;
	my @res = `$cmd`;
	
	return _format_data(\@res);;

	 
}

=head2 getCnvsPublic
	Title   : getCnvsPublic
 	Usage   : getCnvsPublic::
 	Function: Insert data from Json format in the CACHE_ELECTRO table of the database
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub getCnvsPublicByChromosome {
	my ($dbh,$chr_name) = @_;
	
	$chr_name= "chr".$chr_name;
	my $file_cnv  = util_file::get_cnv_public_file();
	my $cmd =  "tabix $file_cnv $chr_name";
	my @res = `$cmd`;
	
	
	return _format_data(\@res);;
	 
}

sub _format_data {
	my ($res) = @_;
	my @cnvs;
	
	foreach my $line (@$res){
		chomp($line);
		my @d = split("\t",$line);
		my %cnv_t;
		$cnv_t{name} = $d[3];
		$cnv_t{span} = Set::IntSpan::Fast::XS->new($d[1]."-".$d[2]);
		push(@cnvs,\%cnv_t);
	} 
	return \@cnvs;
}
1;