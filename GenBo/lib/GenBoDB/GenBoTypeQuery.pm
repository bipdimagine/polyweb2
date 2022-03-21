=head1 NAME

GenBoTypeQuery : Use to interrogate the table TYPE_RELATION of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoTypeQuery provides a set of functions to interrogate the table TYPE_RELATION of the database

=head1 METHODS

=cut

package GenBoTypeQuery;
use strict;
use Data::Dumper;

=head2 getGenBoTypes
	Title   : getGenBoTypes
 	Usage   : GenBoTypeQuery::getGenBoTypes($dbh);
 	Function: Get the all the possible types of the GenBos 
 	Returns : A hash table corresponding to the results
 	Args    : A connection to the database
	Note    : 
=cut

sub getGenBoTypes{
	my ($dbh) =@_;
	my $query = qq{
		SELECT TYPE_GENBO_ID as id,NAME as name, GENBO_OBJECT as object 
		 FROM type_genbo;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("id");
	return $s;
}

=head2 getMethods
	Title   : getMethods
 	Usage   : GenBoTypeQuery::getMethods($dbh);
 	Function: 
 	Returns : 
 	Args    : 
	Note    : NOT USEED
=cut


sub getMethods{
	my $dbh = shift;
	my $query = qq{
		
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("id");
} 


1;