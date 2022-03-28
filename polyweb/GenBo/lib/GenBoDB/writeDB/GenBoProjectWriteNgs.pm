package GenBoProjectWriteNgs;
use strict;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use Carp;



#OK
sub newProject{
	my ($dbh,$name,$type_id,$description,$capture_id) = @_;
	
	my $query = qq{

		insert into PolyprojectsNGS.projects (name,type_project_id,description) values ('$name',$type_id,'$description');

	};
	$dbh->do($query) ;
	my $r =  GenBoQuery::getOrigin($dbh,$name);
	return $r->{id};
}


sub addMethods{
	my ($dbh,$run_id,$method_id) = @_;
	my $query = qq{
		insert into PolyprojectNGS.run_methods  (run_id,method_id) values ($run_id,$method_id);
	};
	$dbh->do($query) ;
}


sub addRelease{
	my ($dbh,$project_id,$release_id) = @_;
	my $query = qq{
		insert into PolyprojectNGS.project_release  (project_id,release_id,`default`) values ($project_id,$release_id,1);
	};

	$dbh->do($query) ;
}

sub addUser{
	my ($dbh,$project_id,$user_id) = @_;
	my $query = qq{
		insert into PolyprojectNGS.user_projects  (PROJECT_ID,USER_ID) values ($project_id,$user_id);
	};
	$dbh->do($query) ;
}

sub addMachine{
	my ($dbh,$project_id,$machine_id) = @_;
	my $query = qq{
		insert into PolyprojectNGS.projects_machines  (project_id,machine_id) values ($project_id,$machine_id);
	};
	$dbh->do($query) ;
}

sub addDb{
	my ($dbh,$project_id,$dbid) = @_;
	my $query = qq{
		insert into PolyprojectNGS.databases_projects  (project_id,db_id) values ($project_id,$dbid);
	};
	$dbh->do($query) ;
}


1;