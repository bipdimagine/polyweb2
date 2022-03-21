=head1 NAME

GenBoDelete : Specific functions to delete records in the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoDelete provides a set of functions to delete informations in the database

=head1 METHODS

=cut

package GenBoDelete;

use strict;
use Carp;

=head2 deleteRelations
	Title   : deleteRelations
 	Usage   : GenBoDelete::deleteRelations($dbh,$GenBoId);
 	Function: Delete the relations where the specified GenBoId is implicated in the table RELATION
 	Returns : Nothing
 	Args	: The id of the GenBo implicate in the relation to delete
	Note    : 
=cut

sub deleteRelations {
	my ($dbh,$id) = @_;
	my $query = qq{select relation_id as id from RELATION where GENBO_ID=$id or GENBO2_ID = $id};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $t = $sth->fetchall_hashref("id");
	foreach my $rid (keys %$t){
		if (existsAnnex($dbh,$rid)){
			
		}
		deleteByRelationId($dbh,$rid);
	}
} 

=head2 deleteObject
	Title   : deleteObject
 	Usage   : GenBoDelete::deleteObject($dbh,$GenBoId);
 	Function: Delete the specified GenBo in the table GENBO
 	Returns : Nothing
 	Args	: The id of the GenBo to delete
	Note    : 
=cut

sub deleteObject {
	my ($dbh,$id) = @_;
	my $nb = existsRelation($dbh,$id);
	#if ($nb >0) {
	#	confess ("can't delete genbo: $id still have $nb relations   on it ");
	#}
	deleteDescriptions($dbh,$id);
	deleteRelations($dbh,$id);
#	deleteSequence($dbh,$id);
	my $query = qq{delete from GENBO where GENBO_ID=$id};
	$dbh->do($query) ;
}

=head2 deleteSequence
	Title   : deleteSequence
 	Usage   : GenBoDelete::deleteSequence($dbh,$GenBoId);
 	Function: Delete the sequence of specified GenBo in the table SEQUENCE
 	Returns : Nothing
 	Args	: The GenBo id associated to the sequence to delete
	Note    : 
=cut

sub deleteSequence {
	my ($dbh,$id) = @_;
	my $nb = existsSequence($dbh,$id);
	if ($nb >0) {
		confess ("can't delete sequence: $id still have $nb genbo with it ");
	}
	my $query = qq{select sequence_id as id from GENBO where GENBO_ID=$id};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $t = $sth->fetchall_hashref("id");
	foreach my $rid (keys %$t){
		deleteBySequenceId($dbh,$rid);
	}
}

=head2 deleteByRelationId
	Title   : deleteByRelationId
 	Usage   : GenBoDelete::deleteByRelationId($dbh,$relationId);
 	Function: Delete the relation of specified id in the table RELATION
 	Returns : Nothing
 	Args	: The relation id to delete
	Note    : 
=cut


sub deleteByRelationId{
	my ($dbh,$id) = @_;
	my $nb = existsAnnex($dbh,$id);
	if ($nb >0) {
		my $sql = qq{delete from  RELATION_ANNEX where relation_id = $id};
		$dbh->do($sql);
		#warn  "relation: $id still have $nb Annex on it ";
		#confess ("can't delete relation: $id still have $nb Annex on it ");
	}
	my $query = qq{delete from RELATION where RELATION_ID=$id };
	$dbh->do($query);
} 

=head2 deleteByDescriptionId
	Title   : deleteByDescriptionId
 	Usage   : GenBoDelete::deleteByDescriptionId($dbh,$descriptionId);
 	Function: Delete the description of specified id in the table DESCRIPTION
 	Returns : Nothing
 	Args	: The description id to delete
	Note    : 
=cut

sub deleteByDescriptionId{
	my ($dbh,$id) = @_;
	my $query = qq{delete from DESCRIPTION where DESCRIPTION_ID=$id };
	$dbh->do($query);
} 

=head2 deleteBySequenceId
	Title   : deleteBySequenceId
 	Usage   : GenBoDelete::deleteBySequenceId($dbh,$sequenceId);
 	Function: Delete the sequence of specified id in the table SEQUENCE
 	Returns : Nothing
 	Args	: The sequence id to delete
	Note    : 
=cut

sub deleteBySequenceId{
	my ($dbh,$id) = @_;
	my $nb = existsSequence($dbh,$id);
	if ($nb >1) {
		
		confess ("can't delete sequence: $id still have $nb traces with this sequence ");
	}
	my $query = qq{delete from SEQUENCE where SEQUENCE_ID=$id };
	$dbh->do($query);
}

=head2 deleteAnnex
	Title   : deleteAnnex
 	Usage   : GenBoDelete::deleteAnnex($dbh,$methodId, $relationTypeId);
 	Function: Delete the annex with the specified method id and the specified relation type id in the table RELATION_ANNEX
 	Returns : Nothing
 	Args	: The method id and the relation type id of the annex to delete
	Note    : 
=cut

sub deleteAnnex {
	my ($dbh,$genboId,$methodid, $typeid) = @_;
	 my $query = qq{delete rr from RELATION_ANNEX rr ,RELATION r 
	 	where r.relation_id = rr.relation_id and r.type_relation_id = $typeid and
	 	 (GENBO_ID= $genboId or GENBO2_ID = $genboId) and rr.method_id = $methodid};
	 $dbh->do($query);
}

=head2 deleteDescriptions
	Title   : deleteDescriptions
 	Usage   : GenBoDelete::deleteDescriptions($dbh,$GenBoId);
 	Function: Delete the descriptions associated with the specified GenBo id in the table DESCRIPTION
 	Returns : Nothing
 	Args	: The GenBo id associated with the description to delete
	Note    : 
=cut

sub deleteDescriptions {
	my ($dbh,$id) = @_;
	my $query = qq{select description_id as id from DESCRIPTION where GENBO_ID=$id};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $t = $sth->fetchall_hashref("id");
	foreach my $rid (keys %$t){
		deleteByDescriptionId($dbh,$rid);
	}
}

=head2 existsAnnexOnGenBo
	Title   : existsAnnexOnGenBo
 	Usage   : GenBoDelete::existsAnnexOnGenBo($dbh,$GenBoId);
 	Function: Get the annex associated with the specified GenBo id in the table ANNEX
 	Returns : The number of annex corresponding (else 0)
 	Args	: The GenBo id associated with the searched annex
	Note    : 
=cut

sub existsAnnexOnGenBo {
	my ($dbh,$id) = @_;
	 my $sql = qq{select count(rr.annex_id) from RELATION_ANNEX rr ,RELATION r 
	 	where r.relation_id = rr.relation_id and
	 	 (GENBO_ID= $id or GENBO2_ID = $id)};
	 	return  connect::returnOneVal($dbh,$sql); 
}

=head2 existsAnnex
	Title   : existsAnnex
 	Usage   : GenBoDelete::existsAnnex($dbh,$relationId);
 	Function: Get the annex associated with the specified relation id in the table ANNEX
 	Returns : The number of annex corresponding (else 0)
 	Args	: The relation id associated with the searched annex
	Note    : 
=cut

sub existsAnnex {
	my ($dbh,$id) = @_;
	my $sql = qq{select count(annex_id) from  RELATION_ANNEX where relation_id = $id};
	return connect::returnOneVal($dbh,$sql); 
}

=head2 existsSequence
	Title   : existsSequence
 	Usage   : GenBoDelete::existsSequence($dbh,$GenBoId);
 	Function: To know if the sequence of the specified GenBo id exists in the table SEQUENCE
 	Returns : The number of sequence corresponding (else 0)
 	Args	: The GenBo id of the searched sequence
	Note    : 
=cut

sub existsSequence {
	my ($dbh,$id) = @_;
	my $sql = qq{select count(G2.genbo_id) from  GENBO G , GENBO G2 where G2.sequence_id = G.sequence_id and G.genbo_id=$id};
	return connect::returnOneVal($dbh,$sql); 
}

=head2 existsOrigin
	Title   : existsOrigin
 	Usage   : GenBoDelete::existsOrigin($dbh,$projectName);
 	Function: To know if the origin of value $projectName exists in the table ORIGIN
 	Returns : The number of GenBo of the specified origin id (else 0)
 	Args	: A string corresponding to the name of the project
	Note    : origin = project
=cut

sub existsOrigin {
	my ($dbh,$name) = @_;
	my $sql = qq{select count(G.GENBO_ID) from GENBO G, ORIGIN O where G.ORIGIN_ID=O.ORIGIN_ID and O.NAME='$name'};
	return connect::returnOneVal($dbh,$sql); 
}

=head2 existsRelation
	Title   : existsRelation
 	Usage   : GenBoDelete::existsRelation($dbh,$GenBoId);
 	Function: To know if the relation associated with the GenBo id exists
 	Returns : The number of corresponding relation ids (else 0)
 	Args	: An integer corresponding to the searched relation id
	Note    : 
=cut

sub existsRelation {
	my ($dbh,$id) = @_;
	my $sql = qq{select count(relation_id) from  RELATION where GENBO_ID = $id or GENBO2_ID= $id};
	return connect::returnOneVal($dbh,$sql); 
}

=head2 existsDescription
	Title   : existsDescription
 	Usage   : GenBoDelete::existsDescription($dbh,$GenBoId);
 	Function: To know if the description associated with the GenBo id exists
 	Returns : The number of corresponding description ids (else 0)
 	Args	: An integer corresponding to the GenBo id associated with the searched description
	Note    : 
=cut

sub existsDescription {
	my ($dbh,$id) = @_;
	my $sql = qq{select count(description_id) from  DESCRIPTION where GENBO_ID= $id};
	return connect::returnOneVal($dbh,$sql); 
}

=head2 deleteOrigin
	Title   : deleteOrigin
 	Usage   : GenBoDelete::deleteOrigin($dbh,$projectName);
 	Function: Delete the origin of the specified name in the table ORIGIN
 	Returns : Nothing
 	Args	: A string corresponding to the name of the origin
	Note    : origin = project
=cut

sub deleteOrigin {
	my ($dbh,$name) = @_;
	my $nb = existsOrigin($dbh,$name);
	if ($nb >1) {
		confess ("can't delete origin: $name still have $nb genbo associate ");
	}
	my $query = qq{delete from ORIGIN where NAME='$name' };
	$dbh->do($query);
}
1;