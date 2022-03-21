=head1 NAME

GenBoWrite : Use to insert records in the table GENBO of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoWrite provides a set of functions to write in the table GENBO of the database

=head1 METHODS

=cut

package GenBoProjectWrite;
use strict;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use Carp;


=head2 createOrigin
	Title   : createOrigin
 	Usage   : GenBoWrite::createOrigin($dbh,$name,$projectType);
 	Function: Create a record in the table ORIGIN for the project of the specified name
  	Returns : The id of the inserted origin (int)
 	Args    : A connection to the database, the name of the project (string), the type of the project (GenBoProjectType)
	Note    : Check if the project name doesn't already exists
=cut


sub newProject{
	my ($dbh,$name,$type_id,$description,$capture_id) = @_;
	
	my $query = qq{

		insert into Polyprojects.projects (name,type_project_id,description,capture_id) values ('$name',$type_id,'$description','$capture_id');

	};
	$dbh->do($query) ;
	my $r =  GenBoQuery::getOrigin($dbh,$name);
	return $r->{id};
}


sub addMethods{
	my ($dbh,$project_id,$method_id) = @_;
	my $query = qq{
		insert into Polyproject.project_methods  (project_id,method_id) values ($project_id,$method_id);
	};
	$dbh->do($query) ;
}



sub addRelease{
	my ($dbh,$project_id,$release_id) = @_;
	my $query = qq{
		insert into Polyproject.project_release  (project_id,release_id,`default`) values ($project_id,$release_id,1);
	};

	$dbh->do($query) ;
}

sub addUser{
	my ($dbh,$project_id,$user_id) = @_;
	my $query = qq{
		insert into Polyproject.user_projects  (PROJECT_ID,USER_ID) values ($project_id,$user_id);
	};
	$dbh->do($query) ;
}

sub addMachine{
	my ($dbh,$project_id,$machine_id) = @_;
	my $query = qq{
		insert into Polyproject.projects_machines  (project_id,machine_id) values ($project_id,$machine_id);
	};
	$dbh->do($query) ;
}

sub addDb{
	my ($dbh,$project_id,$dbid) = @_;
	my $query = qq{
		insert into Polyproject.databases_projects  (project_id,db_id) values ($project_id,$dbid);
	};
	$dbh->do($query) ;
}


1;