#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../../../../../GenBo/lib/";
use lib "$Bin/../../../../../GenBo";
use lib "$Bin/../../../../../GenBo/lib/GenBoDB";
use lib "$Bin/../../../../../GenBo/lib/obj-nodb";
use lib "$Bin/../../../../../GenBo/lib/obj-nodb/packages";
use lib "$Bin/../../../../../GenBo/lib/kyoto";

use lib "$Bin/../../../GenBo/lib/obj-nodb/";

use Getopt::Long;
use GBuffer;


my $analysis_id =0;
my $step_id = "toto" ;
my $status = "titi";
my $patient ;


GetOptions(
	'analysis_id=s' => \$analysis_id,
	'step_id=s' => \$step_id,
	'status=s' => \$status,
	'patient=s' => \$patient,
	);
	
change_step_status($analysis_id, $step_id, $status, $patient);
	
sub change_step_status {
	my ($analysis_id, $step_id, $new_status, $patient) = @_ ;
	my $buffer = GBuffer -> new();
	my $dbh = $buffer->dbh();
	$dbh->{AutoCommit} = 0;
	$dbh->do("use Polypipeline;");
	
	$ENV{'DATABASE'} = "";
	my $sql= qq{UPDATE Polypipeline.`Analysis_Steps` SET status ="$new_status", end=NOW() WHERE analysis_id="$analysis_id" AND  step_id ="$step_id" AND patient = "$patient";};
#	warn $sql ;
	$dbh->do($sql);
	$dbh->commit;
	$dbh->disconnect;
}


exit(0);






	

	