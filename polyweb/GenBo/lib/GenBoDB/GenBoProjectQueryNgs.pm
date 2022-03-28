=head1 NAME

GenBoProjectQuery : Use to interrogate the table ORIGIN of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoProjectQuery provides a set of functions to interrogate the table ORIGIN of the database

=head1 METHODS

=cut


package GenBoProjectQueryNgs;

use strict;
use Carp;
use Data::Dumper;


	

sub getOwnerProject {
	my ($dbh, $pid) = @_;
	my $query = qq{
		select BU.email as email, BU.PRENOM_U as firstname FROM PolyprojectNGS.user_projects U, PolyprojectNGS.projects O, bipd_users.USER BU
		where U.project_id=O.project_id and O.project_id=$pid and U.USER_ID=BU.USER_ID and BU.equipe_id != 6 ;
	};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res;
}

sub getUserId {
	my ($dbh, $username) = @_;
	my $query = qq{SELECT user_id  FROM bipd_users.`USER` U where U.LOGIN='$username' and U.equipe_id = 6;};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{user_id} if $res;
	return;
}

sub getDbId {
	my ($dbh, $database) = @_;
	my $query = qq{SELECT db_id  FROM PolyprojectNGS.polydb where NAME='$database';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{db_id} if $res;
	return;
}

sub getSeqMachineId {
	my ($dbh,$seq_machine) = @_;
	my $query = qq{SELECT machine_id  FROM PolyprojectNGS.sequencing_machines where name='$seq_machine';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{machine_id} if $res;
	return;
}


sub getReleaseId {
	my ($dbh,$name) = @_;
	my $query = qq{SELECT release_id  FROM PolyprojectNGS.releases where name='$name';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{release_id} if $res;
	return;
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
	my $query = qq{select project_id as id, name as name, TYPE_PROJECT_ID as projectType from PolyprojectNGS.projects };
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
	### TODO: attention !!! la table project_types n'existe pas dans PolyprojectNGS !! Pour l'instant je laisse Polyproject.
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("id");
	return $s;
}

sub getOriginMethods {
	my ($dbh, $projectId, $type) = @_;
	$type = uc($type);
	my $query = qq{
		SELECT distinct m.name as methodname 
    		FROM PolyprojectNGS.projects pr, PolyprojectNGS.patient pa, PolyprojectNGS.run r, PolyprojectNGS.run_methods rm, PolyprojectNGS.methods m 
        		where pr.project_id='$projectId' and pr.project_id=pa.project_id and pa.run_id=rm.run_id and rm.method_id=m.method_id and m.type='$type';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("methodname");
	my @lRes = keys(%$s);
	@lRes = sort(@lRes);
	return \@lRes;
}

sub getSequencingMachines {
	my ($dbh, $pid) = @_;
	my $sql = qq{
		SELECT distinct sm.name as name 
    		FROM PolyprojectNGS.projects pr, PolyprojectNGS.patient pa, PolyprojectNGS.run_machine rm, PolyprojectNGS.sequencing_machines sm 
        		where pr.project_id='$pid' and pr.project_id=pa.project_id and pa.run_id=rm.run_id and rm.machine_id=sm.machine_id;
	};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchall_hashref("name");
	my @lRes = keys(%$s);
	@lRes = sort(@lRes);
	return \@lRes;
}

sub getDuplicateVariations_HG19 {
	my ($dbh,$pid,$ver,$db) = @_;
	my $sql = qq{select o.genbo_id as id,nb as NB from DEJAVU_STATIC s,ORIGIN_GENBO o where origin_id=? and  o.type_genbo_id in (8,15,16) and s.genbo_id=o.genbo_id and nb>1};
	my $sth = $dbh->prepare($sql);
	$sth->execute($pid);
	my $d = $sth->fetchall_hashref("id");
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
		FROM PolyprojectNGS.methods m
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
		 FROM  PolyprojectNGS.project_release p, PolyprojectNGS.releases r
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

sub getObjects{
	my ($dbh,$id,$typeid) = @_;
	confess() unless $id;
	confess unless $typeid;
	my $cmd = "select o.GENBO_ID as '-id' ,g.NAME as '-name',g.type_genbo_id as '-type' from ORIGIN_GENBO o, GENBO g where o.ORIGIN_ID=$id and o.TYPE_GENBO_ID=$typeid and o.GENBO_ID=g.GENBO_ID order by g.name";
	my $query = qq{$cmd} ;
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_arrayref({}) || confess();
	return $res;
}

sub getProjectByName {
	my ($dbh,$name,$config,$verbose) = @_;
	my $type_db = $config->{type_db};
	confess(" manque le type de base de donnée") unless exists $config->{type_db};
	my $query = qq{	  	
			select o.project_id as id,o.name as name, o.type_project_id as projectType , db.name as dbname , r.name as version
			from PolyprojectNGS.projects o , PolyprojectNGS.databases_projects dp, PolyprojectNGS.polydb db, PolyprojectNGS.project_release pr , PolyprojectNGS.releases r 
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
		while (my ($k, $v)=each(%$res)){
			print "  K: $k  -  V: $v\n";
			while (my ($k2, $v2)=each(%$v)){
				print "     K2: $k  -  V2: $v\n";
			}
		}
		confess("2 different databases for the same project\n");
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

sub getAllPatientsNameOrIdFromProjectId {
	my ($dbh, $projectId, $type) = @_;
	my $query = qq{
		select pat.name as name, pat.genbo_id as id, pat.patient_id as patId
	        FROM PolyprojectNGS.patient pat, PolyprojectNGS.projects pro
	            where pro.project_id='$projectId' and pat.project_id=pro.project_id;	
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref($type);
	my @res = sort(keys(%$s));
	return \@res;
}

sub getPatientsNameOrIdFromProjectId {
	my ($dbh, $projectId, $nameOrId, $type) = @_;
	my $query = qq{
		select pat.name as name, pat.genbo_id as id, pat.patient_id as patId
	        FROM PolyprojectNGS.patient pat, PolyprojectNGS.projects pro
	            where pro.project_id='$projectId' and pat.project_id=pro.project_id and (pat.genbo_id='$nameOrId' or pat.name='$nameOrId');	
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref($type);
	my @res = sort(keys(%$s));
	return \@res;
}

sub getOriginMethodsFromPatientId {
	my ($dbh, $patientId, $type) = @_;
	$type = uc($type);
	my $query = qq{
		select m.name as name
        	FROM PolyprojectNGS.patient p, PolyprojectNGS.run r, PolyprojectNGS.run_methods rm, PolyprojectNGS.methods m
           		where p.genbo_id='$patientId' and p.run_id=r.run_id and r.run_id=rm.run_id and rm.method_id=m.method_id and m.type='$type';
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("name");
	my @res = sort(keys(%$s));
	return \@res;
}

sub getSequencingMachinesFromPatientId {
	my ($dbh, $patientId) = @_;
	my $sql = qq{
		select sm.name as name
	        FROM PolyprojectNGS.patient p, PolyprojectNGS.run r, PolyprojectNGS.run_machine rm, PolyprojectNGS.sequencing_machines sm
	            where p.genbo_id="$patientId" and p.run_id=r.run_id and r.run_id=rm.run_id and rm.machine_id=sm.machine_id
	};
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchall_hashref("name");
	my @t = keys %$s;
	return \@t;		
}

sub getDescription {
	my ($dbh,$pid) = @_;
		my $query = qq{ select description from PolyprojectNGS.projects where project_id=$pid };
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{description};
}

sub getCaptureId {
	my ($dbh,$cname) = @_;
	my $query = qq{SELECT capture_id  FROM PolyprojectNGS.capture_systems where name='$cname';};
	my $sth = $dbh->prepare( $query );
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	return $res->[0]->{capture_id} if $res;
	return;
}

sub getCaptureInfos {
	my ($dbh, $project_id, $test) =@_;
	my $query = qq{SELECT c.* FROM PolyprojectNGS.patient p, PolyprojectNGS.capture_systems c where p.project_id=$project_id and p.capture_id=c.capture_id;};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});
	my @allCaptureFileName ;
	foreach my $obj (@$res) { push(@allCaptureFileName, $obj->{'filename'}) }
	return $res;
	
	
} 

sub _uniqValueInArray {
	my ($tab) = shift;
	my %seen = ();
	my @uniq = grep { ! $seen{$_} ++ } @$tab;
	@uniq = sort(@uniq);
	return \@uniq;
}

1;