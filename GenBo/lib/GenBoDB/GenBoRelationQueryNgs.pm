package GenBoRelationQueryNgs;
use Carp;
use strict;


=head2 getRelationType
	Title   : getRelationType
 	Usage   : GenBoRelationQueryNgs::getRelationType($dbh,$name);
 	Function: Get the type of the relation corresponding to the specified name
 	Returns : An integer corresponding to the id of the searched type of relation
 	Args    : A string corresponding to the name of the searched type of relation
	Note    : 
=cut


sub getRelationType {
	my ($dbh,$name) = @_;
	my $query = qq{
		select type_relation_id as id from PolyprojectNGS.type_relation tr 
		where tr.name= '$name';
	};
	
	return connect::returnOneVal($dbh,$query);
}


=head2 getAllRelationType
	Title   : getRelationType
 	Usage   : GenBoRelationQueryNgs::getRelationType($dbh,$name);
 	Function: Get the type of the relation corresponding to the specified name
 	Returns : An integer corresponding to the id of the searched type of relation
 	Args    : A string corresponding to the name of the searched type of relation
	Note    : 
=cut


sub getAllRelationType {
	my ($dbh,$name) = @_;
	my $query = qq{
		select type_relation_id as id ,name as name from PolyprojectNGS.type_relation tr ;		
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	return $sth->fetchall_hashref("name");
	
}
=head2 getRelationsDown
	Title   : getRelationsDown
 	Usage   : GenBoRelationQueryNgs::getRelationsDown($dbh,$GenBoId, $relationTypeId);
 	Function: Get the GenBos of the down level of the specified type
 	Returns : A hash table of the corresponding results
 	Args    : An integer corresponding to the GenBo id at the up level in the relation
 		An integer corresponding to the searched type relation id 
	Note    : 
=cut
my %query;
sub getRelationsDown {
	my ($dbh,$id,$typeid,$pid) = @_;
	confess("no project id given") unless $pid;
	
	unless (exists $query{down}){
		my $query = qq{
		select  relation_id as rid, GENBO2_ID as '-id', go.name as '-name', start2 as start,end2 as end, strand as strand,start1 as start2, end1 as end2, method as method
		  from RELATION r , ORIGIN_GENBO g, GENBO go ,  PolyprojectNGS.project_release pr
		  where r.genbo_id=? and type_relation_id=? and genbo2_id=g.genbo_id and g.origin_id=$pid and g.genbo_id=go.genbo_id and pr.project_id=$pid  and (pr.default=1 OR pr.RELEASE_ID = 0) 
		  order by start1;
	};
		$query{down} = $dbh->prepare_cached($query);
		
	}
	

	$query{down}->execute($id,$typeid);
	my $t = $query{down}->fetchall_arrayref({});
	return $t;

}

=head2 getRelationsUp
	Title   : getRelationsUp
 	Usage   : GenBoRelationQueryNgs::getRelationsUp($dbh,$GenBoId, $relationTypeId);
 	Function: Get the GenBos of the up level of the specified type
 	Returns : A hash table of the corresponding results
 	Args    : An integer corresponding to the GenBo id at the down level in the relation
 		An integer corresponding to the searched type relation id 
	Note    : 
=cut

sub getRelationsUp {
	my ($dbh,$id,$typeid,$pid) = @_;
	unless (exists $query{up}){
	my $query = qq{
		select  relation_id as rid, g.GENBO_ID as '-id', go.name as '-name', start1 as start,end1 as end, strand as strand ,start2 as start2,end2 as end2, method as method 
		from RELATION r , ORIGIN_GENBO g, GENBO go 
		where r.genbo2_id=? and type_relation_id=? and r.genbo_id=g.genbo_id and g.origin_id=$pid and g.genbo_id=go.genbo_id 
		  order by start2;
	};
	$query{up}=$dbh->prepare_cached($query);
	}
	#my $sth = $dbh->prepare($query);
	$query{up}->execute($id,$typeid);
	return $query{up}->fetchall_arrayref({});
	#return $sth->fetchall_hashref("id");
}

=head2 getRelationId
	Title   : getRelationId
 	Usage   : GenBoRelationQueryNgs::getRelationId($dbh,$GenBoId1, $GenBoId2, $relationTypeId);
 	Function: Get the relation id between the to specified GenBos of the specified relation type id
 	Returns : A hash table of the corresponding results
 	Args    : Integers corresponding to the differents ids
	Note    : 
=cut

sub getRelationId {
	my ($dbh,$genboId1,$genboId2,$type) = @_;
	my $sql = qq{
		select RELATION_ID as id FROM RELATION 
		where GENBO2_ID='$genboId2' and GENBO_ID='$genboId1' and TYPE_RELATION_ID='$type'; 
	};
	
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}

=head2 getMethodId
	Title   : getMethodId
 	Usage   : GenBoRelationQueryNgs::getMethodId($dbh,$name);
 	Function: Get the method id of the specified name
 	Returns : An integer corresponding to the searched id
 	Args    : A string corresonding to the name of the searche method
	Note    : Interrogate the METHOD table
=cut

sub getMethodId {
	my ($dbh,$name) = @_ ;
	my $sql = qq{select method_id as ID from PolyprojectNGS.methods where name = '$name'};
	my $id = connect::returnOneVal($dbh,$sql);
	confess ("problem with method $name") unless $id;
	return $id;
}

=head2 getAnnexByRelationId
	Title   : getAnnexByRelationId
 	Usage   : GenBoRelationQueryNgs::getAnnexByRelationId($dbh,$relationId);
 	Function: Get the annex associated with the specified relation id
 	Returns : A hash table of the results
 	Args    : An integer corresponding to the relation id
	Note    : 
=cut

sub getAnnexByRelationId {
	my ($dbh,$id) = @_ ;
	my $sql = qq{select annex_id as id, score as score,text as text,name as method_name,score2 as score2,score3 as score3 ,score4 as score4,ho as homozygote,he as heterozygote  FROM RELATION_ANNEX r , PolyprojectNGS.methods m  where m.method_id=r.method_id and relation_id=$id};
	my $sth = $dbh->prepare($sql);

	$sth->execute();
	my $s = $sth->fetchall_hashref("id");	
	return $s;
}
 
=head2 isValid
	Title   : isValid
 	Usage   : GenBoRelationQueryNgs::isValid($dbh,$relationId);
 	Function: To know if the relation has been validated
 	Returns : An integer correspondingto the status of the validation
 	Args    : An integer corresponding to the relation id
	Note    : 
=cut

sub isValid{
	my ($dbh,$id)=@_;
	my $sql = qq{select IS_VALID  from RELATION R where R.RELATION_ID='$id'};
	return  connect::returnOneVal($dbh,$sql); 
}
=head2 getFirstAndLastVariationPosition
	Title   : getFirstAndLastVariationPosition
 	Usage   : GenBoRelationQueryNgs::getFirstAndLastVariationPosition($dbh,$Id);
 	Function: return first and last position of variation on this contig
 	Returns : An integer correspondingto the status of the validation
 	Args    : An integer corresponding to the relation id
	Note    : 
=cut
sub getFirstAndLastVariationPosition {
	my ($dbh,$id)=@_;
	my $sql = qq{select min(start1)as start ,max(start1) as end from RELATION where GENBO_ID=$id and type_relation_id in (8,11) order by start1;};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	return  $sth->fetchrow_hashref();	
	#return $s;
}


1;