=head1 NAME

GenBoCacheQuery : Use to create a cache for the graphic view of the varaiations to accelerate the queries

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoCacheQuery provides a set of functions to create a cache (stored informations in the table CACHE_ELECTRO in the database)

=head1 METHODS

=cut


package GenBoCacheQuery;

 
use strict;
use Carp;
use Data::Dumper;

=head2 insertJson
	Title   : insertJson
 	Usage   : GenBoCacheQuery::insertJson($dbh,$projectId,$variationId,$traceId,$json);
 	Function: Insert data from Json format in the CACHE_ELECTRO table of the database
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub insertJson {
	my ($dbh,$pid,$vid,$trid,$json) = @_;
	my $id = getid($dbh,$pid,$vid,$trid);
	if ($id){
		my $query = qq{delete from CACHE_ELECTRO where cache_id=$id};
		$dbh->do($query);
	}
	my $data2 = connect::compressData($json);
	my $sql = qq {
				insert into CACHE_ELECTRO (origin_id,variation_id,trace_id,json,DATE) values(?,?,?,?,NOW());
				};
	my $sth= $dbh->prepare($sql);
	$sth->execute($pid,$vid,$trid,$data2);
	$sth->finish;
	return ;
}

=head2 insertJsonForUrl
	Title   : insertJson
 	Usage   : GenBoCacheQuery::insertJson($dbh,$projectId,$variationId,$traceId,$json);
 	Function: Insert data from Json format in the CACHE_ELECTRO table of the database
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub insertJsonForUrl {
	my ($dbh,$url,$json) = @_;
#	my $id = getid($dbh,$pid,$vid,$trid);
#	if ($id){
#		my $query = qq{delete from CACHE_ELECTRO where cache_id=$id};
#		$dbh->do($query);
#	}
	my $data2 = connect::compressData($json);
	my $sql = qq {
				insert into CACHE_WWW(url,json) values(?,?);
				};
	my $sth= $dbh->prepare($sql);
	$sth->execute($url,$data2);
	$sth->finish;
	return ;
}
=head2 getidForUrl
	Title   : getid
 	Usage   : GenBoCacheQuery::getid($dbh,$projectId,$variationId,$traceId);
 	Function: get the id of the row in the table ELECTRO_CACHE corresponding to the specified variation id, project id and trace id  
 	Returns : An integer corresponding to the searched id
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Note    : 
=cut

sub getidForUrl {
	my ($dbh,$url) = @_;
	my $sql = qq{select cache_id from CACHE_WWW where url='$url'};
	return connect::returnOneVal($dbh,$sql);
}

=head2 getid
	Title   : getid
 	Usage   : GenBoCacheQuery::getid($dbh,$projectId,$variationId,$traceId);
 	Function: get the id of the row in the table ELECTRO_CACHE corresponding to the specified variation id, project id and trace id  
 	Returns : An integer corresponding to the searched id
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Note    : 
=cut

sub getid {
	my ($dbh,$pid,$vid,$trid) = @_;
	my $sql = qq{select cache_id from CACHE_ELECTRO where variation_id=$vid and trace_id=$trid};
	return connect::returnOneVal($dbh,$sql);
}
=head2 getJsonForUrl
	Title   : getJsonFromId
 	Usage   : GenBoCacheQuery::getJsonFromId($dbh,$cacheId);
 	Function: get the data in Json format by the cache id  
 	Returns : Data in Json format
 	Args    : A connection to the database
	Integer corresponding to the cache id 
	Note    : 
=cut

sub getJsonForUrl {
	my ($dbh,$id) = @_;
	my $sql = qq{select json from CACHE_WWW where cache_id=$id};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_hashref();
	return connect::uncompressData($z->{json});
}
=head2 getJsonFromId
	Title   : getJsonFromId
 	Usage   : GenBoCacheQuery::getJsonFromId($dbh,$cacheId);
 	Function: get the data in Json format by the cache id  
 	Returns : Data in Json format
 	Args    : A connection to the database
	Integer corresponding to the cache id 
	Note    : 
=cut

sub getJsonFromId {
	my ($dbh,$id) = @_;
	my $sql = qq{select json from CACHE_ELECTRO where cache_id=$id};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_hashref();
	return connect::uncompressData($z->{json});
}

=head2 getJson
	Title   : getJson
 	Usage   : GenBoCacheQuery::getJson($dbh,$projectId, $variationId, $traceId);
 	Function: get the data in Json format by variation id and trace id  
 	Returns : Data in Json format
 	Args    : A connection to the database
	Integer corresponding to the differents ids 
	Note    : 
=cut

sub getJson {
	my ($dbh,$pid,$vid,$trid) = @_;
	my $sql = qq{select json from CACHE_ELECTRO where variation_id=$vid and trace_id=$trid};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_hashref();
	return connect::uncompressData($z->{html});
}
1;