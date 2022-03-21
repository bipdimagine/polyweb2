package GenBoTypeQueryNgs;
use strict;
use Data::Dumper;
use GenBoTypeQuery;

our @ISA = qw(GenBoTypeQuery);



sub getGenBoTypes{
	my ($dbh) =@_;
	my $query = qq{
		SELECT TYPE_GENBO_ID as id,NAME as name, GENBO_OBJECT as object 
		 FROM PolyprojectNGS.type_genbo;
	};
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchall_hashref("id");
	return $s;
}

1;