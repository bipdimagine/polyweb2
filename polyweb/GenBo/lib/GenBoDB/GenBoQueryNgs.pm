package GenBoQueryNgs;
use strict;
use Data::Dumper;
use Carp;

my $selectGenbo = "select GENBO_ID as id, name as name, type_genbo_id as type_id";

=head2 getGenboById
	Title   : getGenboById
 	Usage   : GenBoQueryNgs::getGenboById($dbh,$GenBoId);
 	Function: Get the genbo record corresponding to the specified genbo id
 	Returns : A hash table of the record
 	Args    : An integer corresponding to the id of the searched GenBo
	Note    : 
=cut

sub getGenboById {
	my ($dbh,$id) =@_;
	my $query = qq{
		$selectGenbo  from GENBO where GENBO_ID=$id;
	};
	
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}

=head2 getGenboByName
	Title   : getGenboByName
 	Usage   : GenBoQueryNgs::getGenboByName($dbh,$GenBoName,$typeId,$projectId);
 	Function: Get the genbo record corresponding to the specified genbo name, type id and project id
 	Returns : A hash table of the record
 	Args    : A string corresponding to the name of the searched GenBo
 	Integers corresponding to the differents id 
	Note    : 
=cut

sub getGenboByName {
	my ($dbh,$name,$typeid,$origin) =@_;
	$origin=0 unless $origin;
	my $query = qq{
		$selectGenbo  from GENBO  where name='$name' and type_genbo_id=$typeid and origin_id=$origin;
	};
	
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}


#OK
sub getOrigin {
	my ($dbh,$name) =@_;
	my $query = qq{
		select project_id as id, type_project_id as type from PolyprojectNGS.projects  where name='$name';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}

=head2 getOriginType
	Title   : getOriginType
 	Usage   : GenBoQueryNgs::getOriginType($dbh,$type);
 	Function: Get the origin type corresponding to the specified type name
 	Returns : A hash table of the record
 	Args    : A string corresponding to the name of the type origin searched
	Note    : 
=cut

sub getOriginType {
	my ($dbh,$type) =@_;
	my $query = qq{
		select type_project_id as id  from PolyprojectNGS.project_types  where name='$type';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}

=head2 getGenboUp
	NOT USED 
=cut

sub getGenboUp {
	my ($id,$relation,$dbh) =@_;
	my $ids;
}

=head2 getRelatedDownObjects
	Title   : getRelatedDownObjects
 	Usage   : GenBoQueryNgs::getRelatedDownObjects($dbh,$GenBoId,$typeRelationId);
 	Function: Get the relation record where the specified genbo id is at the level up in the specified type relation id
 	Returns : An array of hash table of the records
 	Args    : Integers corresponding to the diffrents ids
	Note    : 
=cut

sub getRelatedDownObjects {
	my ($dbh,$id,$relation) = @_;
	my $query = qq{
		select  GENBO2_ID as id from RELATION where genbo_id=$id and type_relation_id=$relation;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my @ids = keys %{$sth->fetchall_hashref("id")};
	return \@ids;
}

=head2 getSequenceId
	Title   : getSequenceId
 	Usage   : GenBoQueryNgs::getSequenceId($dbh,$sequence);
 	Function: Get the id of the specified sequence
 	Returns : A hash table of the record
 	Args    : A string corresponding to the searched sequence 
	Note    : 
=cut

sub getSequenceId {
	my ($dbh,$sequence)=@_;
	my $l = length($sequence);
	my $query = qq{
		select  SEQUENCE_ID as id from SEQUENCE where MD5=MD5('$sequence') and length_2=$l and sequence='$sequence' ;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}

=head2 getDescription
	Title   : getDescription
 	Usage   : GenBoQueryNgs::getDescription($dbh,$genBoId, $typeId);
 	Function: Get the description of the specified GenBo id and type id
 	Returns : A hash table of the record
 	Args    : Integers corresponding to the differents ids 
	Note    : 
=cut

sub getDescription {
	my ($dbh,$genbo,$type) =@_;
	my $query = qq{
		SELECT D.DESCRIPTION_ID as id, D.NAME as name from DESCRIPTION D, TYPE_DESCRIPTION T where D.GENBO_ID='$genbo' and T.type_description_id= D.type_description_id and T.name='$type';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $d = $sth->fetchrow_hashref();	
	return $d;
}

=head2 getSequence
	Title   : getSequence
 	Usage   : GenBoQueryNgs::getSequence($dbh,$genBoId);
 	Function: Get the sequence of the specified GenBo id 
 	Returns : A string corresponding to the searched sequence
 	Args    : An integer corresponding to the GenBo id
	Note    : 
=cut
my %query_cached;
sub getSequence{
	my ($dbh,$id)=@_;
	unless (exists $query_cached{sequence}){
	my $query = qq{
		select  S.SEQUENCE as sequence from SEQUENCE S, GENBO G where G.SEQUENCE_ID=S.SEQUENCE_ID AND G.GENBO_ID=? ;
	};
	$query_cached{sequence} = $dbh->prepare_cached($query);
	}
	
	$query_cached{sequence}->execute($id);
	my $s = $query_cached{sequence}->fetchrow_hashref();	
	return $s->{sequence};
}

=head2 existsAnnexTypeOnGenBo
	Title   : existsAnnexTypeOnGenBo
 	Usage   : GenBoQueryNgs::existsAnnexTypeOnGenBo($dbh,$genBoId, $methodId);
 	Function: To know if an annex record exists for the specified GenBo id and method id 
 	Returns : An integer corresponding to the number of searched annex
 	Args    : Integers corresponding to the differents ids
	Note    : 
=cut

sub existsAnnexTypeOnGenBo {
	my ($dbh,$id,$mid) = @_;
	 my $sql = qq{select count(rr.annex_id) from RELATION_ANNEX rr ,RELATION r 
	 	where r.relation_id = rr.relation_id and
	 	 GENBO2_ID = $id and rr.method_id=$mid};
	 	return  connect::returnOneVal($dbh,$sql); 
}

=head2 isValid
	Title   : isValid
 	Usage   : GenBoQueryNgs::isValid($dbh,$genBoId);
 	Function: To know if the specified GenBo id has been validated
 	Returns : An integer correponding to the status of the validation
 	Args    : An integer corresponding to the GenBo id
	Note    : 
=cut

sub isValid{
	my ($dbh,$id)=@_;
	my $sql = qq{select  IS_VALID  from GENBO G where G.GENBO_ID='$id'};
	return  connect::returnOneVal($dbh,$sql); 
}

=head2 isValidTotal
	Title   : isValid
 	Usage   : GenBoQueryNgs::isValid($dbh,$genBoId);
 	Function: To know if the specified GenBo id has been validated
 	Returns : An integer correponding to the status of the validation
 	Args    : An integer corresponding to the GenBo id
	Note    : 
=cut

sub isValidTotal{
	my ($dbh,$id,$rid,$debug)=@_;
	my $sql = qq{select  r.IS_VALID as valid , r.genbo_id as id, g.NAME as name from RELATION r,GENBO g  where g.GENBO_ID=r.GENBO_ID and r.GENBO2_ID='$id' and r.type_relation_id=$rid};
	my $sth = $dbh->prepare($sql);
	warn $sql if $debug;
	$sth->execute();
	return $sth->fetchall_arrayref({});


	#my @s = keys %{$sth->fetchall_hashref("valid")};	
	#return \@s;
	
	
}
=head2 getAllMethods
	Title   : getAllMethods
 	Usage   : GenBoQueryNgs::getAllMethods($dbh,$projectId);
 	Function: Get all the existing methods for the specified project id
 	Returns : A hash table of the name of the methods
 	Args    : An integer corresponding to the project id
	Note    : 
=cut

sub getAllMethods{
	my ($dbh,$projectId)=@_;
	my $sql= qq{select distinct M.NAME from RELATION R , GENBO G , RELATION_ANNEX RA, METHODS M where G.ORIGIN_ID ='$projectId' and (R.GENBO_ID=G.GENBO_ID or R.GENBO2_ID=G.GENBO_ID) and R.RELATION_ID=RA.RELATION_ID AND M.METHOD_ID=RA.METHOD_ID};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchall_hashref("NAME");	
	return $s;
}


=head2 getVariationOnContigByPosAndSeq
	Title   : getVariationOnContigByPosAndSeq
 	Usage   : GenBoQueryNgs::getVariationOnContigByPosAndSeq($dbh,$contig,$position,$sequence);
 	Function: Get the GenBo id of the variation on the specified contig at the sepcified position and with the sepcified sequence 
 	Returns : A integer corresponding to the searched GenBo id
 	Args    : A GenBoContig
 		An integer corresponding to the searched position
 		A string corresponding to the sequence
	Note    : 
=cut

sub getObjectOnContigByPosAndSeq {
	my ($dbh,$contig,$pos1,$seq,$type) = @_;
	my $projectId=$contig->getProject()->id();
	my $contigId=$contig->id();
	my $type_id = $type->id;
	my $sql = qq{SELECT g.GENBO_ID FROM GENBO g,RELATION r, SEQUENCE s where g.origin_id='$projectId' and g.type_genbo_id=$type_id and r.genbo_id='$contigId' and r.genbo2_id=g.genbo_id and r.start1='$pos1' and g.sequence_id=s.sequence_id and s.sequence='$seq';};
	return  connect::returnOneVal($dbh,$sql); 
}

=head2 existsObjectOnContigByVariationHash
	Title   : existsObjectOnContigByVariationHash
 	Usage   : GenBoQueryNgs::existsObjectOnContigByVariationHash($dbh,$hash_var);
 	Function: Get the GenBo id of the variation on the specified contig at the sepcified position and with the sepcified sequence 
 	Returns : A integer corresponding to the searched GenBo id
 	Args    : A GenBoContig
 		An integer corresponding to the searched position
 		A string corresponding to the sequence
	Note    : 
=cut

sub existsObjectOnContigByVariationHash {
	my ($dbh,$var,$debug) = @_;
	
	my $contig_id=$var->{contig}->{id};
	my $type = $var->{type};
	my $start = $var->{contig}->{start};
	my $end = $var->{contig}->{end};
	my $seq = $var->{sequence};
	
	confess("type") unless defined $type;
	confess("contig id") unless defined $contig_id;
	confess("contig start") unless defined $start;
	confess("contig end") unless defined $start;
	confess("sequence var ") unless exists $var->{sequence};
	my $sql = qq{SELECT g.GENBO_ID FROM GENBO g,RELATION r, SEQUENCE s, PolyprojectNGS.type_genbo t where t.name = "$type"  and t.type_genbo_id=g.type_genbo_id and r.genbo_id='$contig_id' and r.genbo2_id=g.genbo_id and r.start1='$start' and r.end1='$end' and g.sequence_id=s.sequence_id and s.sequence='$seq';};
	return  connect::returnOneVal($dbh,$sql); 
		
}



sub existsObjectsByPosition {
	my ($dbh,$var,$gp,$debug) = @_;
	my $start = $var->{start};
	my $end = $var->{end};
	my $seq = $var->{sequence};
	my $chr = $var->{chromosome}->{name};
	my $type = $var->{type};
	
	confess("contig start") unless defined $start;
	confess("contig end") unless defined $end;
	confess("chr") unless exists $var->{chromosome}->{name};
	confess("type") unless exists $var->{type};
	confess("sequence var ") unless exists $var->{sequence};
	confess ("chromosome var ") unless exists $var->{chromosome};
	confess("and the golden path ") unless $gp;
	my $t1 = "CHR_".$gp;
	my $t2 = "START_".$gp;
	my $t3 = "END_".$gp;
	my $t4 = "SHA1_".$gp;
	
	my $sha1_code = "$chr:$start-$end:$seq";
	
	### TODO to supress
#	my $cmd = "select GENBO_ID as id  FROM DEJAVU_STATIC D,  PolyprojectNGS.type_genbo t where t.name = \"$type\"  and t.type_genbo_id=D.type_genbo_id  and $t4=UNHEX(SHA1(\'$sha1_code\')) and $t1=\'$chr\' and $t2=$start and $t3=$end;";
#	print "[QueryNgs::existsObjectsByPosition] $cmd\n";
	### to here
	
	my $sql = qq{ select GENBO_ID as id  FROM DEJAVU_STATIC D,  PolyprojectNGS.type_genbo t where
		 t.name = "$type"  and t.type_genbo_id=D.type_genbo_id  and $t4=UNHEX(SHA1('$sha1_code')) 
		 and $t1='$chr' and $t2=$start and $t3=$end;
		
	}; 	
	my $sth = $dbh->prepare( $sql );
	$sth->execute()  or confess();
	my ($id) = $sth->fetchrow_array() ;#or confess($sql);
	return $id;
	
	
}



=head2 isBipd
	Title   : isBipd
 	Usage   : GenBoQueryNgs::isBipd($dbh,$genBoId);
 	Function: To know if the specified GenBo id id already seen in an other project
 	Returns : An integer correponding to the status of the validation
 	Args    : An integer corresponding to the GenBo id
	Note    : 
=cut

sub isBipd{
	my ($dbh,$id)=@_;
	my $sql = qq{select nb_project, count(distinct g) as nb_patient, sum(he) as he , sum(ho) as ho from  (select  d.nb as nb_project, d.genbo_id as did, g.genbo_id  as g , if (ra.he>=1,1,0) as he, if (ra.ho>=1,1,0) as ho
from DEJAVU_STATIC d, RELATION r,GENBO g, RELATION_ANNEX ra
 where d.NB >1 and d.GENBO_ID = $id and r.genbo2_id= d.genbo_id and g.genbo_id=r.genbo_id
  and g.type_genbo_id = 5
  and ra.relation_id=r.relation_id  group by ra.relation_id,d.genbo_id ) as tbl ;
	};
	#my $sql = qq{select  d.nb as nb_project ,count(g.genbo_id) as nb_patient, sum(ra.he) as he , sum(ra.ho) as ho  from DEJAVU_STATIC d, RELATION r,GENBO g, RELATION_ANNEX ra where d.NB >1 and d.GENBO_ID = $id and r.genbo2_id= d.genbo_id and g.genbo_id=r.genbo_id and g.type_genbo_id = 5  and ra.relation_id=r.relation_id and ra.he>=0 and ra.ho>=0 group by d.genbo_id;};
	my $sth = $dbh->prepare($sql);
	#warn $sql;
	$sth->execute();
	my $col1;
	my $col2;
	my $ho;
	my $he;
	$sth->bind_columns(\$col1,\$col2,\$he,\$ho);
	$sth->fetch();
	#my @res = $sth->fetchrow_array();
 	return ($col1,$col2,$he,$ho);
}

sub isBIPDForOneProject{
	my ($dbh,$pid,$id)=@_;
	confess() unless $pid;
	my $sql = qq{select nb_project, count(distinct g) as nb_patient, sum(he) as he , sum(ho) as ho from  (select  d.nb as nb_project, d.genbo_id as did, g.genbo_id  as g , if (ra.he>=1,1,0) as he, if (ra.ho>=1,1,0) as ho
from DEJAVU_STATIC d, RELATION r,GENBO g, RELATION_ANNEX ra
 where d.NB >1 and d.GENBO_ID = $id and r.genbo2_id= d.genbo_id and g.genbo_id=r.genbo_id
  and g.type_genbo_id = 5
  and g.origin_id=$pid
  and ra.relation_id=r.relation_id  group by ra.relation_id,d.genbo_id ) as tbl ;
	};
	my $sth = $dbh->prepare($sql);
	#warn $sql;
	$sth->execute();
	my $col1;
	my $col2;
	my $ho;
	my $he;
	$sth->bind_columns(\$col1,\$col2,\$he,\$ho);
	$sth->fetch();
	#my @res = $sth->fetchrow_array();
 	return ($col1,$col2,$he,$ho);
}

1;