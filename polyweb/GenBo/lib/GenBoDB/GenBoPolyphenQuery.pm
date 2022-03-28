=head1 NAME

GenBoPolyphenQuery : Use to interrogate the table POLYPHEN of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoPolyphenQuery provides a set of functions to interrogate the table POLYPHEN of the database

=head1 METHODS

=cut


package GenBoPolyphenQuery;
 
use strict;
use Carp;

=head2 deleteAll
	Title   : deleteAll
 	Usage   : GenBoPolyphenQuery::deleteAll($dbh,$projectId);
 	Function: Delete the data in the table POLYPHEN associated with the specified project id
 	Returns : Nothing
 	Args    : An integer corresponding to the project id
	Note    : 
=cut

sub deleteAll {
	my ($dbh,$id) = @_;
	confess("problem with id") unless $id;
	my $query = qq{delete from POLYPHEN where ORIGIN_ID=$id };
	$dbh->do($query);
	return 1;
}

=head2 insertData
	Title   : insertDate
 	Usage   : GenBoPolyphenQuery::insertData($dbh,$projectId,$variationId,$protein,$status,$html);
 	Function: Insert data from polyphen associated with the differents ids
 	Returns : Nothing
 	Args    : A connection to the database 
 	Integers corresponding to differents ids
 	A string corresponding to the protein name
 	An integer corresponding to the polyphen status
 	A blob containing the html page of results
	Note    : 
=cut

sub insertData {
	my ($dbh,$pid,$vid,$prot,$status,$html) = @_;
	my $status2 = getStatus($dbh,$vid,$prot);
	if (defined $status2) {
		my $query = qq{delete from POLYPHEN where variation_id=$vid and protein='$prot' };
		$dbh->do($query);
	}
	my $data2 = connect::compressData($html);
	my $sql = qq {
				insert into POLYPHEN (origin_id,variation_id,protein,status,html,DATE) values(?,?,?,?,?,NOW());
				};
	my $sth= $dbh->prepare($sql);
	$sth->execute($pid,$vid,$prot,$status,$data2);
	$sth->finish;
	return 1;
}

sub getVariationsIdsForStatus {
	my ($dbh,$pid,$status) = @_;
	my $sql = qq {select p.GENBO_ID as id, p.status from ORIGIN_GENBO o , POLYPHEN p where origin_id=$pid and type_genbo_id=8 and o.genbo_id=p.genbo_id and status >= $status;};
	return connect::return_hashref($dbh,$sql,"id");
}

=head2 getHtml
	Title   : getHtml
 	Usage   : GenBoPolyphenQuery::getHtml($dbh,$variationId,$protein);
 	Function: Get the results polyphen html page associated to the specified protein and variationId 
 	Returns : A html page
 	Args    : A connection to the database 
 	Integer corresponding to variation id
 	A string corresponding to the protein name
	Note    : 
=cut

sub getHtml {
	my ($dbh,$vid,$prot) = @_;
	my $sql = qq{select html from POLYPHEN where variation_id=$vid and protein='$prot'};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_hashref();
	return connect::uncompressData($z->{html});
}

=head2 getStatus
	Title   : getStatus
 	Usage   : GenBoPolyphenQuery::getStatus($dbh,$variationId,$protein);
 	Function: Get the polyphen status associated to the specified protein and variationId 
 	Returns : An integer corresponding to the status
 	Args    : A connection to the database 
 	Integer corresponding to variation id
 	A string corresponding to the protein name
	Note    : 
=cut

sub getStatus {
	my ($dbh,$vid,$prot) = @_;
	my $sql = qq{select status from POLYPHEN where variation_id=$vid and protein='$prot'};
	return connect::returnOneVal($dbh,$sql);
}

=head2 getMaxStatusFromVariation
	Title   : getMaxStatusFromVariation
 	Usage   : GenBoPolyphenQuery::getMaxStatusFromVariation($dbh,$variationId,$protein);
 	Function: Get the higher polyphen status associated to the specified protein and variationId 
 	Returns : An integer corresponding to the status
 	Args    : A connection to the database 
 	Integer corresponding to variation id
 	A string corresponding to the protein name
	Note    : 
=cut

sub getMaxStatusFromVariation {
	my ($dbh,$vid,$prot) = @_;
	my $sql = qq{select max(status) from POLYPHEN where variation_id=$vid};
	return connect::returnOneVal($dbh,$sql);
}

1;