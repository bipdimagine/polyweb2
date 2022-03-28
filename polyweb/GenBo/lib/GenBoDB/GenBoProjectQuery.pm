=head1 NAME

GenBoProjectQuery : Use to interrogate the table ORIGIN of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoProjectQuery provides a set of functions to interrogate the table ORIGIN of the database

=head1 METHODS

=cut


package GenBoProjectQuery;
 
use strict;
use Carp;
use Data::Dumper;


=head2 getOriginType
	Title   : getOriginType
 	Usage   : GenBoQuery::getOriginType($dbh,$type);
 	Function: Get the origin type corresponding to the specified type name
 	Returns : A hash table of the record
 	Args    : A string corresponding to the name of the type origin searched
	Note    : 
=cut

sub getOriginType {
	my ($dbh,$type) =@_;
	my $query = qq{
		select type_project_id as id  from Polyproject.project_types  where name='$type';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s;
}

=head2 getProjectByName
	Title   : getProjectByName
 	Usage   : GenBoProjectQuery::getProjectByName($dbh,$name);
 	Function: Get the origin record corresponding to the specified project name
 	Returns : A hash table of the record
 	Args    : A string corresponding to the name of the searched project
	Note    : 
=cut

sub getProjectByName {
	my ($dbh,$name,$config,$verbose) = @_;
	
	my $type_db = $config->{type_db};
	confess(" manque le type de base de donnée") unless exists $config->{type_db};
	my $query = qq{	  	
			select o.project_id as id,o.name as name, o.type_project_id as projectType , db.name as dbname , r.name as version
			from projects o , databases_projects dp,polydb db, project_release pr , releases r 
			  where o.name='$name' 
			  and dp.project_id=o.project_id and db.db_id=dp.db_id and prod=$type_db
			  and pr.project_id=o.project_id and pr.release_id = r.release_id and pr.default=1;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_hashref("dbname");
	
	if (scalar(keys %$res) ==0 ){
		confess("no project found $name");
	}
	if (scalar(keys %$res) >1 && ! exists $config->{name}){
		confess("2 different databases for the same project");
		
	}
	my ($dbname) = keys %$res;
	if (exists $config->{name}){
		$dbname = 	$config->{name};
		confess("no project $name defined on $dbname database") unless exists  $res->{$dbname};
	}
	
	
	my $s = $res->{$dbname};
	$config->{root}= $dbname;
	if (lc($dbname) eq "polyexome" || lc($dbname) eq "polyrock"){
	
		$config->{name} = $dbname."_".$res->{$dbname}->{version};
		
	}
	else {
	$config->{name} = $dbname;#."_".$res->{$dbname}->{version};
	}
	$dbname = $config->{name};
	my $sql2 = qq{use $dbname;};
	my $user = getlogin();
	#warn "############################## \n";

	warn "     ++ $dbname $name++ $user \n" unless $verbose ;
	#warn "##############################\n";
	
	$dbh->do($sql2) || die("==> can't find $dbname on server : ".$config->{dbname});
	return $s;
}
	

sub getOwnerProject {
	my ($dbh,$pid) = @_;
	
	
	my $query = qq{
		select BU.email as email,BU.PRENOM_U as firstname FROM user_projects U, projects O, bipd_users.USER BU
		where U.project_id=O.project_id and O.project_id=$pid and U.USER_ID=BU.USER_ID and BU.equipe_id != 6 ;
	};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	
	return $res;
}

sub getUserId {
	my ($dbh,$username) = @_;
	my $query = qq{SELECT user_id  FROM bipd_users.`USER` U where U.LOGIN='$username' and U.equipe_id = 6;};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{user_id} if $res;
	return;
}

sub getDbId {
	my ($dbh,$database) = @_;
	my $query = qq{SELECT db_id  FROM Polyproject.polydb where NAME='$database';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{db_id} if $res;
	return;
}

sub getSeqMachineId {
	my ($dbh,$seq_machine) = @_;
	my $query = qq{SELECT machine_id  FROM Polyproject.sequencing_machines where name='$seq_machine';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{machine_id} if $res;
	return;
}

sub getCaptureId {
	my ($dbh,$cname) = @_;
	my $query = qq{SELECT capture_id  FROM Polyproject.capture_systems where name='$cname';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{capture_id} if $res;
	return;
}

sub getReleaseId {
	my ($dbh,$name) = @_;
	my $query = qq{SELECT release_id  FROM Polyproject.releases where name='$name';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{release_id} if $res;
	return;
}

sub getDescription {
	my ($dbh,$pid) = @_;
		my $query = qq{ select description from Polyproject.projects where project_id=$pid };
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{description};
}
=head2 getObjects
	Title   : getObjects
 	Usage   : GenBoProjectQuery::getObjects($dbh,$projectId,$typeId);
 	Function: Get the genbo record corresponding to the specified project id and type id
 	Returns : An array of objects ids of the specified type
 	Args    : Integers corresponding to the differents ids
	Note    : 
=cut
sub getObjects{
	my ($dbh,$id,$typeid) = @_;
	confess() unless $id;
	confess unless $typeid;
	my $query = qq{select o.GENBO_ID as '-id' ,g.NAME as '-name',g.type_genbo_id as '-type' from ORIGIN_GENBO o,GENBO g where o.ORIGIN_ID=$id and o.TYPE_GENBO_ID=$typeid and o.GENBO_ID=g.GENBO_ID order by g.name} ;
	
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_arrayref({}) || confess();
	return $res;
		
}


=head2 getAllProjects
	Title   : getAllProjects
 	Usage   : GenBoProjectQuery::getAllProjects($dbh);
 	Function: Get all the projects of the table ORIGIN
 	Returns : An array of project ids
 	Args    : A connection to the database
	Note    : 
=cut

sub getAllProjects {
	my ($dbh) = @_;
	my $query = qq{select project_id as id,name as name, TYPE_PROJECT_ID as projectType  from projects };
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my @ids = values %{$sth->fetchall_hashref("id")};
	return \@ids;
}

=head2 countObjects
	Title   : countObjects
 	Usage   : GenBoProjectQuery::countObjects($dbh,$typeId,$projectId);
 	Function: Get all the objects of the specified type for the specified project id
 	Returns : An integer corresponding to the number of objects
 	Args    : A connection to the database
 	Integers corresponding to the differents ids
	Note    : 
=cut

sub countObjects{
	my ($dbh,$dbname,$typeid,$pid) = @_;
	my $query = qq{select count(genbo_id) from $dbname.ORIGIN_GENBO where origin_id = $pid and type_genbo_id=$typeid };
	connect::returnOneVal($dbh,$query);
}

=head2 getProjectTypes
	Title   : getProjectTypes
 	Usage   : GenBoProjectQuery::getProjectTypes($dbh);
 	Function: Get the all the possible types of the origins 
 	Returns : A hash table corresponding to the results
 	Args    : A connection to the database
	Note    : 
=cut

sub getProjectTypes{
	my ($dbh) =@_;
	my $query = qq{
		SELECT type_project_id as id,name as name
		 FROM Polyproject.project_types;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("id");
	return $s;
}



sub getOriginMethods {
	my ($dbh,$project_id,$type) = @_;
	$type = uc($type);
	my $query = qq{
		select m.name as name, m.type as type, m.method_id as id 
		 FROM Polyproject.project_methods om, Polyproject.methods m
			where om.project_id=$project_id and om.method_id=m.method_id and m.type='$type';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("name");
	
	return keys %$s;
}

sub getSequencingMachines {
	my ($dbh,$pid) = @_;
	my $sql = qq{select m.name as name,m.type as type 
				 from Polyproject.projects_machines pm , Polyproject.sequencing_machines m 
				where pm.project_id=$pid and pm.machine_id=m.machine_id };
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchall_hashref("name");
	
	return keys %$s;		
}


sub getDuplicateVariations_HG19 {
	my ($dbh,$pid,$ver,$db) = @_;
	my $sql = qq{select o.genbo_id as id,nb as NB from DEJAVU_STATIC s,ORIGIN_GENBO o where origin_id=? and  o.type_genbo_id in (8,15,16) and s.genbo_id=o.genbo_id and nb>1};
	#my $sql = qq{select o.genbo_id as id from already_static al left join ORIGIN_GENBO o using (GENBO_ID) where origin_id=$pid and (type_genbo_id=8 or type_genbo_id=14 or type_genbo_id=15)};
#	my $sql = qq{select o.genbo_id as id from ORIGIN_GENBO o, already_static f where o.origin_id=$pid and (o.type_genbo_id=8 or type_genbo_id=15 or type_genbo_id = 14) and o.genbo_id=f.genbo_id order by o.genbo_id};
#	my $sql = qq{select genbo_id as id from ORIGIN_GENBO o1 where o1.type_genbo_id=8 and o1.genbo_id IN (select genbo_id from ORIGIN_GENBO where type_genbo_id = 8 and origin_id=$pid) group by genbo_id HAVING count(origin_id) > 1 ;};
	my $sth = $dbh->prepare($sql);
	$sth->execute($pid);
	my $d = $sth->fetchall_hashref("id");
	my %dd = %$d;

	return $d;
}

sub getDuplicateVariations {
	my ($dbh,$pid,$ver,$db) = @_;
	return getDuplicateVariations_HG19(@_) if ($ver eq "HG19");
	my ($db_name,$t) = split("_",$db) ;
	my $ver2 = "HG19";
	$ver2 = "HG18" if ($ver eq "HG19");
	
	my $limit =1;
   warn "start";
	my $sql = qq{select o.genbo_id as id,nb as NB from DEJAVU_STATIC s,ORIGIN_GENBO o where origin_id=? and s.genbo_id=o.genbo_id and nb>1};
	#my $sql = qq{select o.genbo_id as id from already_static al left join ORIGIN_GENBO o using (GENBO_ID) where origin_id=$pid and (type_genbo_id=8 or type_genbo_id=14 or type_genbo_id=15)};
#	my $sql = qq{select o.genbo_id as id from ORIGIN_GENBO o, already_static f where o.origin_id=$pid and (o.type_genbo_id=8 or type_genbo_id=15 or type_genbo_id = 14) and o.genbo_id=f.genbo_id order by o.genbo_id};
#	my $sql = qq{select genbo_id as id from ORIGIN_GENBO o1 where o1.type_genbo_id=8 and o1.genbo_id IN (select genbo_id from ORIGIN_GENBO where type_genbo_id = 8 and origin_id=$pid) group by genbo_id HAVING count(origin_id) > 1 ;};
	my $sth = $dbh->prepare($sql);
	warn "end";
	$sth->execute($pid);	
	my $d = $sth->fetchall_hashref("id");
	my %dd = %$d;
	if (lc($db_name) eq "polyexome" || lc($db_name) eq "polyrock") {
	my $table2 = $db_name."_".$ver2;
	my $sql2 = qq{select s.genbo_id as id,s.nb+s2.nb as NB from DEJAVU_STATIC s,$table2.DEJAVU_STATIC s2, ORIGIN_GENBO o  where
 			o.origin_id= ? and o.genbo_id=s.genbo_id  and s.SHA1_$ver = s2.SHA1_$ver and s.type_genbo_id=s2.type_genbo_id and s.nb+s2.nb>?;};
	
	my $sth2 = $dbh->prepare($sql2) || die();
	
	$sth2->execute($pid,$limit)|| die();
	
	my $d2  = $sth2->fetchall_hashref("id");
	
	@dd{keys %{$d2}} = values %{$d2};
	}
	warn "end3";
	return \%dd; 
	
}

=head2 getMethodsFromName
	Title   : getProjectByName
 	Usage   : GenBoProjectQuery::getProjectByName($dbh,$name);
 	Function: Get the origin record corresponding to the specified project name
 	Returns : A hash table of the record
 	Args    : A string corresponding to the name of the searched project
	Note    : 
=cut

sub getMethodsFromName {
	my ($dbh,$name,$type) = @_;
	my $query = qq{
		select m.name as name, m.type as type, m.method_id as id  
		FROM Polyproject.methods m
			where  m.name='$name' and m.type='$type';
	};
	
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();
	return $s;
}


sub getGenomeRelease {
	my ($dbh,$project_id) = @_;
	my $query = qq{
		 select r.name 
		 FROM  Polyproject.project_release p, Polyproject.releases r
			where p.project_id=$project_id and r.release_id = p.release_id;;
	};

	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s  = $sth->fetchall_arrayref({});
	return $s;
}	

=head2 checkAuthentification
	Title   : checkAuthentification
 	Usage   : connect::checkAuthentification($dbh, $login, $pwd);
 	Function: To show only the projects of the user with the login $login and the password $pwd
 	Returns : An array of hash table corresponding to the projects of the user
 	Args	: A connection to the database, the login and the password of the user (string)
	Note    : 
=cut

sub getProjectListForUser {
	my ($dbh,$config,$login,$pwd)=@_;
	my $type_db = $config->{type_db};
	confess(" manque le type de base de donnée") unless exists $config->{type_db};
	
	my $query = qq{	  	
			select o.project_id as id,o.name as name, pt.name as type , db.name as dbname ,o.description as description
			from projects o , databases_projects dp,polydb db,  user_projects  up ,  bipd_users.USER BU, project_types pt
			  where 
			  	up.project_id=o.project_id and up.USER_ID=BU.USER_ID AND BU.LOGIN='$login' and BU.password_txt=password('$pwd')
			   and dp.project_id=o.project_id and db.db_id=dp.db_id and prod=$type_db 
			   and o.type_project_id = pt.type_project_id order by pt.name,o.name;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_hashref("id");
	my @toto = sort{$a->{type} cmp $b->{type} || $a->{name} cmp $b->{name}} values %$res;
	return \@toto; 
}
=head2 checkAuthentification
	Title   : checkAuthentification
 	Usage   : connect::checkAuthentification($dbh, $login, $pwd);
 	Function: To show only the projects of the user with the login $login and the password $pwd
 	Returns : An array of hash table corresponding to the projects of the user
 	Args	: A connection to the database, the login and the password of the user (string)
	Note    : 
=cut

sub getAuthentificationForUser {
	my ($dbh,$project_name,$login,$pwd)=@_;
	my $query = qq{	  	
			select o.project_id as id 
			from projects o ,  user_projects  up ,  bipd_users.USER BU
			  where 
			  	o.name= '$project_name' and 
			  	up.project_id=o.project_id and up.USER_ID=BU.USER_ID AND BU.LOGIN='$login' and BU.password_txt=password('$pwd');
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_arrayref();
	return scalar(@$res);
}

sub getCaptureInfos {
	my ($dbh,$project_id) =@_;
	my $query = qq{SELECT c.* FROM Polyproject.projects p, Polyproject.capture_systems c where p.project_id=$project_id and p.capture_id=c.capture_id; };
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});#$sth->fetch_hashref("id");
	return $res->[0] if $res;
	
} 

1;