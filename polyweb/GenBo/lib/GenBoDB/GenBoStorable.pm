=head1 NAME

GenBoStorable : Use to create a cache for the graphic view of the varaiations to accelerate the queries

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoCacheQuery provides a set of functions to create a cache (stored informations in the table CACHE_ELECTRO in the database)

=head1 METHODS

=cut


package GenBoStorable;
use strict;
use Carp;
use Data::Dumper;
use Storable qw/freeze thaw nfreeze/;

=head2 insertStorable
	Title   : insertJson
 	Usage   : GenBoCacheQuery::insertJson($dbh,$projectId,$variationId,$traceId,$json);
 	Function: Insert data from Json format in the CACHE_ELECTRO table of the database
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub insertStorable {
	my ($dbh,$pid,$ref_id,$type,$data) = @_;
	
	
	my $id = getStoreId($dbh,$pid,$ref_id,$type);
	
	if ($id){
		my $query = qq{delete from CACHE_STORABLE where cache_id=$id};
		$dbh->do($query);
	}
	
	my $data2 = connect::compressData(nfreeze($data));
	my $sql = qq {
				insert into CACHE_STORABLE (project_id,reference_id,request_type,store) values(?,?,?,?);
				};
	my $sth= $dbh->prepare($sql);
	$sth->execute($pid,$ref_id,$type,$data2) || confess("problem save storable");
	$sth->finish;
	return ;
}

=head2 getStoreId
	Title   : getStoreId
 	Usage   : GenBoStorable::getStorableId($dbh,$projectId,$variationId,$traceId);
 	Function: get the id of the row in the table ELECTRO_CACHE corresponding to the specified variation id, project id and trace id  
 	Returns : An integer corresponding to the searched id
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Note    : 
=cut

sub getStoreId {
	my ($dbh,$pid,$ref_id,$type) = @_;
	my $sql = qq{select cache_id from CACHE_STORABLE where project_id=$pid and reference_id=$ref_id and request_type='$type'};
	return connect::returnOneVal($dbh,$sql);
}


=head2 getOneStoreId
	Title   : getStoreId
 	Usage   : GenBoStorable::getStorableId($dbh,$projectId,$variationId,$traceId);
 	Function: get the id of the row in the table ELECTRO_CACHE corresponding to the specified variation id, project id and trace id  
 	Returns : An integer corresponding to the searched id
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Note    : 
=cut

sub getOneStoreId {
	my ($dbh,$pid,$ref_id,$type) = @_;
	my $sql = qq{select cache_id from CACHE_STORABLE where project_id=$pid and request_type='$type'};
	return connect::returnOneVal($dbh,$sql);
}

=head2 getStore
	Title   : getStore
 	Usage   : GenBoStorable::getStore($dbh,$cacheId);
 	Function: get the data in Json format by the cache id  
 	Returns : Data in Storable format
 	Args    : A connection to the database
	Integer corresponding to the cache id 
	Note    : 
=cut

sub getStore {
	my ($dbh,$id) = @_;
	die("no cache ") unless $id;
	my $sql = qq{select store from CACHE_STORABLE where cache_id=$id};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_hashref();

	my $t = connect::uncompressData($z->{store});
	return (thaw($t));
}

=head2 getWaitingId
	Title   : getWaitingId
 	Usage   : 
 	Function: get the id of the row in the table ELECTRO_CACHE corresponding to the specified variation id, project id and trace id  
 	Returns : An integer corresponding to the searched id
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Note    : 
=cut

sub getWaitingId {
	my ($dbh,$pid,$type) = @_;
	my $sql = qq{select waiting_id from WAITING where project_id=$pid and request_type='$type'};
	
	return connect::returnOneVal($dbh,$sql);
}

=head2 getStore
	Title   : getStore
 	Usage   : GenBoStorable::getStore($dbh,$cacheId);
 	Function: get the data in Json format by the cache id  
 	Returns : Data in Storable format
 	Args    : A connection to the database
	Integer corresponding to the cache id 
	Note    : 
=cut

sub getWaitingPourcent {
	my ($dbh,$id) = @_;
	die("no project id") unless $id;
	my $sql = qq{select pourcent as pourcent,(NOW()-DATE) as time,request_type as type from WAITING where project_id=$id};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_hashref();
	return $z;
}


=head2 deleteWaiting
	Title   : insertWaiting
 	Usage   :
 	Function: 
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut
sub deleteWaiting {
	my ($dbh,$id) = @_;
	my $query = qq{delete from WAITING where waiting_id=$id};
	$dbh->do($query);

}


=head2 insertWaiting
	Title   : insertWaiting
 	Usage   :
 	Function: 
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub insertWaiting {
	my ($dbh,$pid,$type) = @_;
	
	my $id = getWaitingId($dbh,$pid,$type);
	
	if ($id){
		deleteWaiting($dbh,$id);
	}
	
	
	my $sql = qq {
				insert into WAITING (project_id,request_type,pourcent) values(?,?,?);
				};
				
	my $sth= $dbh->prepare($sql);
	$sth->execute($pid,$type,0);
	$sth->finish;
	return getWaitingId($dbh,$pid,$type);
}


=head2 updateWaiting
	Title   : updateWaiting
 	Usage   :
 	Function: 
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub updateWaiting {
	my ($dbh,$id,$value) = @_;
	
	
	if ($id){
		my $query = qq{update WAITING set pourcent=$value,DATE=NOW() where waiting_id=$id};
		$dbh->do($query);
	}

}
=head2 addWaiting
	Title   : updateWaiting
 	Usage   :
 	Function: 
 	Returns : Nothing
 	Args    : A connection to the database
	Integer corresponding to differents ids 
	Data in Json format
	Note    : 
=cut

sub incrementWaiting {
	my ($dbh,$id,$value) = @_;
	
	if ($id){
		my $query = qq{update WAITING set pourcent=pourcent+$value,DATE=NOW() where waiting_id=$id};
		$dbh->do($query);
	}

}

sub countObjects{
	my($dbh,$pid,@types_name) = @_;
	confess() unless @types_name;
	my $string_or= "t.name= '".shift(@types_name)."'";

	foreach my $t  (@types_name) {
		$string_or .= " or  t.name= '".$t."'";
	} 
	my $sql = qq{
		SELECT count(*)  FROM ORIGIN_GENBO o ,Polyproject.type_genbo t where o.origin_id=$pid and t.type_genbo_id=o.type_genbo_id and ($string_or);
	};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $z = $sth->fetchrow_arrayref();
	return $z->[0];
	
}

1;