=head1 NAME

GenBoFilter : use for save and retreive filter parameter

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoCacheQuery provides a set of functions to create a cache (stored informations in the table CACHE_ELECTRO in the database)

=head1 METHODS

=cut


package GenBoFilter;
 
use strict;
use Carp;
use Data::Dumper;



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

	my ($dbh,$filter_name,$project_id,$user_id) = @_;	
	my $sql = qq{select fu.filter_id from $main::my_project_db.filters f,$main::my_project_db.filters_users fu where FILTER_NAME='$filter_name' and PROJECT_ID=$project_id and f.filter_id=fu.filter_id and fu.USER_ID=$user_id};
	return connect::returnOneVal($dbh,$sql);
}

sub get_user_id {
	my ($dbh,$user_name) = @_;	
	#warn $main::TOTO;
	

	
	my $sql = qq{SELECT * FROM bipd_users.USER U WHERE U.LOGIN = '$user_name'};

	
	return connect::returnOneVal($dbh,$sql);
}

sub newFilter {
	my ($dbh, $filter_name, $project_id, $user_id) = @_;
	my $id = getid($dbh, $filter_name, $project_id, $user_id);
	if ($id){
		delete_param($dbh,$id);
		return $id;
	}
	my $query = qq{
		call new_filter('$filter_name',$project_id,$user_id);
	};
	$dbh->do($query);
	return getid($dbh, $filter_name, $project_id, $user_id);
}

sub addParam {
	
	my ($dbh, $filter_id,$param_name,$param_value) = @_;
	 
	my $query = qq{
		insert into $main::my_project_db.filters_param (FILTER_ID,PARAM_NAME,PARAM_VALUE) values ($filter_id,'$param_name','$param_value')
		 ON DUPLICATE KEY UPDATE PARAM_VALUE='$param_value'
		;
	};

	$dbh->do($query) ;
}

sub delete_param {
	my ($dbh, $filter_id) = @_;
		my $query = qq{
			delete from $main::my_project_db.filters_param where FILTER_ID = $filter_id;
		};
		$dbh->do($query);
		
}

sub delete_filter {
	my ($dbh, $filter_id,$user_id) = @_;
	
	my $query2 = qq{
			call $main::my_project_db.delete_filter($filter_id,$user_id);
		};
		
	
		$dbh->do($query2);
		return;
}

sub getParam {
	my ($dbh,$filter_id) = @_;
		my $query = qq{select PARAM_NAME as name, PARAM_VALUE as value from $main::my_project_db.filters_param  where FILTER_ID= $filter_id}; 
			my $sth = $dbh->prepare($query);
	$sth->execute();
	
	return $sth->fetchall_hashref("name");
}

sub getAllFilterName {
	my ($dbh, $project_id,$user_id) = @_;
	
	my $query = qq{select f.filter_name as name , f.filter_id as id, creation_date as date from $main::my_project_db.filters f ,$main::my_project_db.filters_users fu where f.filter_id=fu.filter_id and fu.USER_ID=$user_id and PROJECT_ID=$project_id order by creation_date};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	return($sth->fetchall_hashref("id"));
	
}

1;