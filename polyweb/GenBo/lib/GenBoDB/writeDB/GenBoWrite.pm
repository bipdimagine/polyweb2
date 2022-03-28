=head1 NAME

GenBoWrite : Use to insert records in the table GENBO of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoWrite provides a set of functions to write in the table GENBO of the database

=head1 METHODS

=cut

package GenBoWrite;
use strict;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use Carp;
use Try::Tiny; 
use warnings;

=head2 insertSequence
	Title   : insertSequence
 	Usage   : GenBoWrite::insertSequence($dbh,$GenBoId,$sequence);
 	Function: Insert the sequence in the table SEQUENCE for the specified GenBo id
 	Returns : The id of the inserted sequence (int)
 	Args    : A connection to the database, the GenBo id associated to the sequence to insert (int), the sequence to insert (string)
	Note    : 
=cut

sub insertSequence {
	my ($dbh,$id,$sequence) =@_;
	my $s = GenBoQuery::getSequenceId($dbh,$sequence);
	$sequence = uc($sequence);
	my $md5=md5_hex($sequence);
	my $length=length($sequence);
	my $query = qq{
		insert into SEQUENCE (MD5,LENGTH_2,SEQUENCE) values (MD5('$sequence'),$length,'$sequence')
		on duplicate KEY UPDATE SEQUENCE='$sequence' , MD5=MD5('$sequence'), LENGTH_2=$length
	};
	unless (exists $s->{id}) {
		$dbh->do($query);
		$s =  GenBoQuery::getSequenceId($dbh,$sequence);
	}
	my $sequenceId=$s->{id};
	my $sql = qq {
		update GENBO set SEQUENCE_ID='$sequenceId'  where GENBO_ID= '$id'
	};
	$dbh->do($sql) || die("probleme lors l'update de du sequence_id du genbo id=$id");
	return $s->{id};
}

=head2 createGenBo
	Title   : createGenBo
 	Usage   : GenBoWrite::createGenBo($dbh,$name,$typeId,$projectId);
 	Function: Create a record in the table GENBO for the GenBo of the specified name, type id and project id
  	Returns : The id of the inserted GenBo (int)
 	Args    : A connection to the database, the name of the GenBo (string), the type id of the GenBo to create (int), the id of the project of the GenBo (int)
	Note    : Check if the GenBo doesn't already exists
=cut

sub createGenBo{
	my ($dbh,$name,$type,$origin,$golden_path) = @_;
	$golden_path =0 unless $golden_path;
	my $r =  GenBoQuery::getGenboByName($dbh,$name,$type->id,$origin);

	return $r->{id} if defined $r->{id};
	
 
	my $sth= $dbh->prepare('call insert_new_genbo(?,?,?,?)');	 
	my $db_res=0;
	my $z;
	my $toto =0;
	while ($toto == 0){
	eval{
		$sth->execute($origin,$type->id,$name,$golden_path) || die();
 		$z = $sth->fetchrow_hashref();
 		$toto=1;
 		#warn $name." ".$z->{id}."\n";
 		$toto = 1;
	};
	if ($@) {
		warn "deadlock $name \n";
		#warn "sleep ================================================================================\n";
		sleep(2);
		
		
	}
	
	}
	
 #	my $z = $sth->fetchrow_hashref();
	#return($z->{id});
	confess() unless $z->{id};
	return($z->{id});
	
	die();
	
	
}

=head2 createOrigin
	Title   : createOrigin
 	Usage   : GenBoWrite::createOrigin($dbh,$name,$projectType);
 	Function: Create a record in the table ORIGIN for the project of the specified name
  	Returns : The id of the inserted origin (int)
 	Args    : A connection to the database, the name of the project (string), the type of the project (GenBoProjectType)
	Note    : Check if the project name doesn't already exists
=cut

sub createOrigin{
	my ($dbh,$name,$type) = @_;
	my $typeId = GenBoQuery::getOriginType($dbh, $type);
	my $r =  GenBoQuery::getOrigin($dbh,$name);
	my $query = qq{
		insert into ORIGIN (NAME,TYPE_ORIGIN_ID) values ('$name',$typeId->{id});
	};
	unless (  defined $r) {
		$dbh->do($query) ;
		$r =  GenBoQuery::getOrigin($dbh,$name);
	}
	return $r->{id};
}

=head2 createGenBoWithCompteur
	Title   : createGenBoWithCompteur
 	Usage   : GenBoWrite::createGenBoWithCompteur($dbh,$compteur, $typeId, $projectId);
 	Function: Create a record in the table GENBO for the variation of the specified name,type and project id
  	Returns : The id of the inserted GenBo (int)
 	Args    : A connection to the database, the name of the variation (string), the type of the GenBo (int), the project id of the variation (int)
	Note    : Check if the variation name doesn't already exists
=cut

sub createGenBoWithCompteur{
	my ($dbh,$cpt,$type,$origin,$golden_path) = @_;
	
	if ($cpt == 1){
		my $tty = $type->name()."_";
		my $sql = qq{select (trim(leading "$tty" from NAME)) from GENBO where GENBO_ID=(select  MAX(GENBO_ID) from GENBO where NAME like "$tty%" and origin_id=$origin)};
		my $sth= $dbh->prepare($sql);
		$sth->execute;
		($cpt) = $sth->fetchrow_array();
		$cpt++;
		
	}
	#else {
	
	$golden_path = 0 unless $golden_path;
	my $full_name = $type->name()."_".$cpt;
	
	#warn $full_name." ".$cpt;
	my $r =  GenBoQuery::getGenboByName($dbh,$full_name,$type->id(),$origin);
	
	
	if (defined $r) {
		
		$cpt++;
		 return createGenBoWithCompteur($dbh,$cpt,$type,$origin,$golden_path);
	}
	#}
	 $full_name = $type->name()."_".$cpt;
	
	return (createGenBo($dbh,$full_name,$type,$origin,$golden_path),$cpt++);
	
	
}



=head2 createGenBoVariation
	Title   : createGenBoVariation
 	Usage   : GenBoWrite::createGenBoVariation($dbh,$name, $typeId, $projectId);
 	Function: Create a record in the table GENBO for the variation of the specified name,type and project id
  	Returns : The id of the inserted GenBo (int)
 	Args    : A connection to the database, the name of the variation (string), the type of the GenBo (int), the project id of the variation (int)
	Note    : Check if the variation name doesn't already exists
=cut

sub createGenBoVariation{
	my ($dbh,$name,$type,$origin) = @_;
	my $r =  GenBoQuery::getGenboByName($dbh,$name,$type,$origin);
	if (defined $r){
		my ($nameV,$cpt) = split("variation_",$name);
		$cpt++;
		 return createGenBoVariation($dbh,$nameV."_".$cpt,$type,$origin);
	}
	my $query = qq{
		insert into GENBO (ORIGIN_ID,TYPE_GENBO_ID,NAME,DATE,IS_VALID) values ('$origin','$type','$name',NOW(),'0');
	};
	confess(" WARNING change code this one not useful see createGENBOWITHCOMPTEUR");
	unless (  defined $r) {
		$dbh->do($query) ;
		$r =  GenBoQuery::getGenboByName($dbh,$name,$type,$origin);
	}
	return $r->{id};
}

=head2 createGenBoIndel
	Title   : createGenBoIndel
 	Usage   : GenBoWrite::createGenBoIndel($dbh,$name, $typeId, $projectId);
 	Function: Create a record in the table GENBO for the indel of the specified name,type and project id
  	Returns : The id of the inserted GenBo (int)
 	Args    : A connection to the database, the name of the indel (string), the type of the GenBo (int), the project id of the indel (int)
	Note    : Check if the indel name doesn't already exists
=cut

sub createGenBoIndel{
	my ($dbh,$name,$type,$origin) = @_;
	my $r =  GenBoQuery::getGenboByName($dbh,$name,$type,$origin);
	if (defined $r){
		my ($nameV,$cpt) = split("indel_",$name);
		$cpt++;
		 return createGenBoIndel($dbh,$nameV."_".$cpt,$type,$origin);
	}
	my $query = qq{
		insert into GENBO (ORIGIN_ID,TYPE_GENBO_ID,NAME,DATE,IS_VALID) values ('$origin','$type','$name',NOW(),'0');
	};
	confess(" WARNING change code this one not useful see createGENBOWITHCOMPTEUR");
	unless (  defined $r) {
		$dbh->do($query) ;
		$r =  GenBoQuery::getGenboByName($dbh,$name,$type,$origin);
	}
	return $r->{id};
}

=head2 insertDescription
	Title   : insertDescription
 	Usage   : GenBoWrite::insertDescription($dbh,$GenBoId, $typeId, $name);
 	Function: Create a record in the table DESCRIPTION for the GenBo of the specified id
   	Returns : The id of the inserted description (int)
 	Args    : A connection to the database, the GenBo id to describe (int), the type of the GenBo (int), the name of the description (string)
	Note    : Check if the description name doesn't already exists
=cut

sub insertDescription{
	my ( $dbh, $genboId ,$type, $name) = @_;
	my $des=GenBoQuery::getDescription($dbh,$genboId,$type);
	my $query = qq{
		insert into DESCRIPTION (GENBO_ID,TYPE_DESCRIPTION_ID,NAME) values ('$genboId','$type','$name')
		on duplicate KEY UPDATE NAME='$name' 
	};
	unless (  defined $des) {
		$dbh->do($query) ;
		$des = GenBoQuery::getDescription($dbh,$genboId,$type);
	}
	return $des->{id};
}

=head2 valider
	Title   : valider
 	Usage   : GenBoWrite::valider($dbh,$GenBoId,$status);
 	Function: To validate the specified GenBo
   	Returns : Nothing
 	Args    : A connection to the database, the GenBo id to validate (int), the status ofthe validation (int)
	Note    : 
=cut

sub valider{
	my($dbh,$id,$valeur) = @_;
	my $sql = qq {
		update GENBO set IS_VALID='$valeur' where GENBO_ID= '$id';
	};
	return ($dbh->do($sql));
}

sub existsGenBoOrigin {
	my ($dbh,$origin_id,$genbo_id)= @_;
	my $sql = qq {
		select  GENBO_ID as id from ORIGIN_GENBO where genbo_id=$genbo_id and origin_id=$origin_id
	};
	my $sth = $dbh->prepare($sql);
	
	$sth->execute() || confess();
	my $s = $sth->fetchrow_hashref();
	
	return $s if $s;
	return;
	
}
sub insertDejaVu {
 my ($dbh,$genboid,$var,$gp) = @_;
 	my $start = $var->{start};
	my $end = $var->{end};
	my $seq = $var->{sequence};
	my $chr = $var->{chromosome}->{name};
	my $type = $var->{type};
	confess("contig start") unless exists $var->{type};
	confess("contig start") unless defined $start;
	confess("contig end") unless defined $end;
	confess("chr") unless exists $var->{chromosome}->{name};
	
	confess("sequence var ") unless exists $var->{sequence};
	confess ("chromosome var ") unless exists $var->{chromosome};
	confess("and the golden path ") unless $gp;
	my $t1 = "CHR_".$gp;
	my $t2 = "START_".$gp;
	my $t3 = "END_".$gp;
	my $t4 = "SHA1_".$gp;
	
	my $sha1_code = "$chr:$start-$end:$seq";
 	my $sql = qq{insert into DEJAVU_STATIC (GENBO_ID,NB,$t1,$t2,$t3,$t4) values ($genboid,1,'$chr',$start,$end,UNHEX(SHA1('$sha1_code'))) } 	;
 	$dbh->do($sql) || confess("problem insertion dejavu") ;
 	my $sql2 = qq{update DEJAVU_STATIC D,GENBO G SET D.TYPE_GENBO_ID=G.TYPE_GENBO_ID where G.GENBO_ID=$genboid and D.GENBO_ID = G.GENBO_ID};
 	$dbh->do($sql2) || confess("problem insertion dejavu");
}


1;
