#use 5.010;
use File::Compare;
use Test::More;
plan tests => 32;

use FindBin qw($Bin);
use lib "$Bin/../../obj-lite/";
use lib "$Bin/../";
use Data::Dumper;
use GBuffer;
use GenBoProjectQueryNgs;
use GenBoProjectQuery;

my $projectName = "NGS2012_0185";

my $buffer = GBuffer->new();
my $project = $buffer->newProject(-name => $projectName);
my $projectId = $project->id();
my $dbh = $project->buffer->dbh;

print "\n\n### RESULTS:\n\n";
Test_getOwnerProject();
Test_getUserId($dbh);
Test_getDbId($dbh);
Test_getReleaseId($dbh);
Test_getAllProjects($dbh);
Test_countObjects($dbh, $projectId);
Test_getProjectTypes($dbh);
Test_getOriginMethods_SNP($dbh, $projectId);
Test_getOriginMethods_ALIGN($dbh, $projectId);
Test_getSequencingMachines($dbh, $projectId);
Test_getDuplicateVariations_HG19($dbh, $projectId);
Test_getDuplicateVariations_withHg19($dbh, $projectId);
Test_getDuplicateVariations_withHg18($dbh, $projectId);
Test_getMethodsFromName($dbh);
Test_getGenomeRelease($dbh, $projectId);
Test_getObjects($dbh, $projectId);
Test_getAllPatientsNameOrIdFromProjectId_name($dbh);
Test_getAllPatientsNameOrIdFromProjectId_id($dbh, $projectId);
Test_getPatientsNameOrIdFromProjectId_name($dbh);
Test_getPatientsNameOrIdFromProjectId_id($dbh, $projectId);
Test_getCaptureInfos_uniqueCapture($dbh, $projectId);
Test_getCaptureInfos_multipleCapture();
Test_getCaptureId($dbh);
#Test_getOriginMethodsFromPatientId($dbh);
print "\n\n";



sub Test_getOwnerProject {
	my $projectName = "NGS2012_0120";
	my $buffer = GBuffer->new();
	my $project = $buffer->newProject(-name => $projectName);
	my $projectId = $project->id();
	my $dbh = $project->buffer->dbh;
	my ($obsHash) = GenBoProjectQueryNgs::getOwnerProject($dbh, $projectId);
	$obsHash = $$obsHash[0];
	my %expHash;
	$expHash{'firstname'} = 'Asma';
	$expHash{'email'} = 'asma.smahi@inserm.fr';
	my $isEqual = 0;
	if ($expHash{'firstname'} eq $$obsHash{'firstname'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getOwnerProject_firstname");
	$isEqual = 0;
	if ($expHash{'email'} eq $$obsHash{'email'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getOwnerProject_email");
}

sub Test_getUserId {
	my ($dbh) = @_;
	my $userName = 'mbras';
	my ($obsUserId) = GenBoProjectQueryNgs::getUserId($dbh, $userName);
	my $expUserId = '147';
	my $isEqual = 0;
	if ($expUserId eq $obsUserId) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getUserId");
}

sub Test_getDbId {
	my ($dbh) = @_;
	my $database = 'polydev';
	my ($obsId) = GenBoProjectQueryNgs::getDbId($dbh, $database);
	my $expId = '3';
	my $isEqual = 0;
	if ($expId eq $obsId) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getDbId");
}

sub Test_getSeqMachineId {
	my ($dbh) = @_;
	my $seqMachineName = 'SOLID5500';
	my ($obsId) = GenBoProjectQueryNgs::getSeqMachineId($dbh, $seqMachineName);
	my $expId = '4';
	my $isEqual = 0;
	if ($expId eq $obsId) { $isEqual = 1; }
	print "\nEXP: $expId - OBS: $obsId\n";
	ok($isEqual == 1, "Test - getSeqMachineId");
}

sub Test_getReleaseId {
	my ($dbh) = @_;
	my $releaseId = 'HG19';
	my ($obsId) = GenBoProjectQueryNgs::getReleaseId($dbh, $releaseId);
	my $expId = '919';
	my $isEqual = 0;
	if ($expId eq $obsId) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getReleaseId");
}

sub Test_getAllProjects {
	my ($dbh) = @_;
	my ($ObsListProjects) = GenBoProjectQueryNgs::getAllProjects($dbh);
	my $isEqual = 0;
	if (scalar(@$ObsListProjects) > 100) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getAllProjects");
}

sub Test_countObjects {
	my ($dbh, $projectId) = @_;
	my $dbName = 'Polyexome_HG19';
	my $typeId = '3';
	my ($obsNbObj) = GenBoProjectQueryNgs::countObjects($dbh, $dbName, $typeId, $projectId);
	my $expNbObj = 24;
	my $isEqual = 0;
	if (int($obsNbObj) == $expNbObj) { $isEqual = 1; }
	ok($isEqual == 1, "Test - countObjects");
}

sub Test_getProjectTypes {
	my ($dbh) = @_;
	my ($obsHash) = GenBoProjectQueryNgs::getProjectTypes($dbh);
	my %expHash;
	$expHash->{'1'}->{'name'} = 'array';
	$expHash->{'1'}->{'id'} = '1';
	$expHash->{'2'}->{'name'} = 'classic';
	$expHash->{'2'}->{'id'} = '2';
	$expHash->{'3'}->{'name'} = 'ngs';
	$expHash->{'3'}->{'id'} = '3';
	$expHash->{'4'}->{'name'} = 'cnv';
	$expHash->{'4'}->{'id'} = '4';
	$expHash->{'5'}->{'name'} = 'reference';
	$expHash->{'5'}->{'id'} = '5';
	$expHash->{'6'}->{'name'} = 'junk';
	$expHash->{'6'}->{'id'} = '6';
	my $isEqual = 0;
	if ($expHash->{'1'}->{'name'} eq $obsHash->{'1'}->{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getProjectTypes_array");
	$isEqual = 0;
	if ($expHash->{'2'}->{'name'} eq $obsHash->{'2'}->{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getProjectTypes_classic");
	$isEqual = 0;
	if ($expHash->{'3'}->{'name'} eq $obsHash->{'3'}->{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getProjectTypes_ngs");
	$isEqual = 0;
	if ($expHash->{'4'}->{'name'} eq $obsHash->{'4'}->{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getProjectTypes_cnv");
	$isEqual = 0;
	if ($expHash->{'5'}->{'name'} eq $obsHash->{'5'}->{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getProjectTypes_reference");
	$isEqual = 0;
	if ($expHash->{'6'}->{'name'} eq $obsHash->{'6'}->{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getProjectTypes_junk");
}

sub Test_getOriginMethods_SNP {
	my ($dbh, $projectId) = @_;
	my ($obsList) = GenBoProjectQueryNgs::getOriginMethods($dbh, $projectId, 'SNP');
	my @expList = ('unifiedgenotyper');
	my $isEqual = 0;
	if (scalar(@expList) == scalar(@$obsList)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getOriginMethods_SNP");
}

sub Test_getOriginMethods_ALIGN {
	my ($dbh, $projectId) = @_;
	my ($obsList) = GenBoProjectQueryNgs::getOriginMethods($dbh, $projectId, 'ALIGN');
	my @expList = ('bwa');
	my $isEqual = 0;
	if (scalar(@expList) == scalar(@$obsList)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getOriginMethods_ALIGN");
}

sub Test_getSequencingMachines {
	my ($dbh, $projectId) = @_;
	my ($obsList) = GenBoProjectQueryNgs::getSequencingMachines($dbh, $projectId);
	my @expList = ('SOLEXA');
	my $isEqual = 0;
	if (scalar(@expList) == scalar(@$obsList)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getSequencingMachines");
}

sub Test_getDuplicateVariations_HG19 {
	my $projectName = "NGS2012_0120";
	my $buffer = GBuffer->new();
	my $project = $buffer->newProject(-name => $projectName);
	my $projectId = $project->id();
	my $dbh = $project->buffer->dbh;
	my ($obsHashDupObj) = GenBoProjectQueryNgs::getDuplicateVariations_HG19($dbh, $projectId);
	my @obs = keys(%$obsHashDupObj);
	my $expNbElmts = 150299;
	my $isEqual = 0;
	if ($expNbElmts == scalar(@obs)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getDuplicateVariations_HG19");
}

sub Test_getDuplicateVariations_withHg19 {
	my $projectName = "NGS2012_0120";
	my $buffer = GBuffer->new();
	my $project = $buffer->newProject(-name => $projectName);
	my $projectId = $project->id();
	my $dbh = $project->buffer->dbh;
	my $version = 'HG19';
	my ($obsHashDupObj) = GenBoProjectQueryNgs::getDuplicateVariations($dbh, $projectId, $version);
	my @obs = keys(%$obsHashDupObj);
	my $expNbElmts = 150299;
	my $isEqual = 0;
	if ($expNbElmts == scalar(@obs)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getDuplicateVariations with HG19");
}

sub Test_getDuplicateVariations_withHg18 {
	my $projectName = "NGS2010_0013";
	my $buffer = GBuffer->new();
	my $project = $buffer->newProject(-name => $projectName);
	my $projectId = $project->id();
	my $dbh = $project->buffer->dbh;
	my $version = 'HG18';
	my ($obsHashDupObj) = GenBoProjectQueryNgs::getDuplicateVariations($dbh, $projectId, $version);
	my @obs = keys(%$obsHashDupObj);
	my $expNbElmts = 85989;
	my $isEqual = 0;
	if ($expNbElmts == scalar(@obs)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getDuplicateVariations with HG18");
}

sub Test_getMethodsFromName {
	my ($dbh) = @_;
	my $methodName  = 'bipd';
	my $typeName = 'SNP';
	my ($obsHashMethod) = GenBoProjectQueryNgs::getMethodsFromName($dbh, $methodName, $typeName);
	my %expHashMethod;
	$expHashMethod{'name'} = 'bipd';
	$expHashMethod{'id'} = '2';
	$expHashMethod{'type'} = 'SNP';
	my $isEqual = 0;
	if ($expHashMethod{'name'} eq $$obsHashMethod{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getMethodsFromName_name");
	$isEqual = 0;
	if ($expHashMethod{'id'} eq $$obsHashMethod{'id'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getMethodsFromName_id");
	$isEqual = 0;
	if ($expHashMethod{'type'} eq $$obsHashMethod{'type'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getMethodsFromName_type");
}

sub Test_getGenomeRelease {
	my ($dbh, $projectId) = @_;
	my ($obsListName) = GenBoProjectQueryNgs::getGenomeRelease($dbh, $projectId);
	my %expHashName;
	$expHashName{'name'} = 'HG19';
	my @expListName = ("%expHashName");
	my $isEqual = 0;
	if (scalar(@expListName) == scalar(@$obsListName)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getGenomeRelease_nbElmt");
	$isEqual = 0;
	my $obsHashName = $$obsListName[0];
	if ($expHashName{'name'} eq $$obsHashName{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getGenomeRelease_inHash");
	$isEqual = 0;
}

### TODO - Dois je faire ces deux tests ? Car ici je laisse en dur le login-pwd d'une personne... moyen...
sub Test_getProjectListForUser {}
sub Test_getAuthentificationForUser {}

sub Test_getObjects {
	my ($dbh, $projectId) = @_;
	my $typeId = '3';
	my ($obsListObjects) = GenBoProjectQueryNgs::getObjects($dbh, $projectId, $typeId);
	my $expNbObjects = 24;
	my $obsNbObjects = scalar(@$obsListObjects);
	my $isEqual = 0;
	if ($expNbObjects == $obsNbObjects) { $isEqual = 1; }
#	print "\nEXP: $expNbObjects - OBS: $obsNbObjects\n";
	ok($isEqual == 1, "Test - getObjects");
}

sub Test_getProjectByName {
	
}

sub Test_getAllPatientsNameOrIdFromProjectId_name {
	my ($dbh) = @_;
	my $projectId = 1004;
	my $typeAnalyse = 'name';
	my ($obsListObjects) = GenBoProjectQueryNgs::getAllPatientsNameOrIdFromProjectId($dbh, $projectId, $typeAnalyse);
	my $expNbObjects = 7;
	my $obsNbObjects = scalar(@$obsListObjects);
	my $isEqual = 0;
	if ($expNbObjects == $obsNbObjects) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getAllPatientsNameOrIdFromProjectId_name");
}

sub Test_getAllPatientsNameOrIdFromProjectId_id {
	my ($dbh, $projectId) = @_;
	my $typeAnalyse = 'id';
	my ($obsListObjects) = GenBoProjectQueryNgs::getAllPatientsNameOrIdFromProjectId($dbh, $projectId, $typeAnalyse);
	my $expNbObjects = 1;
	my $obsNbObjects = scalar(@$obsListObjects);
	my $isEqual = 0;
	if ($expNbObjects == $obsNbObjects) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getAllPatientsNameOrIdFromProjectId_id");
}

sub Test_getPatientsNameOrIdFromProjectId_name {
	my ($dbh) = @_;
	my $projectId = 1004;
	my $typeAnalyse = 'name';
	my $patientName = 'ARM';
	my ($obsListObjects) = GenBoProjectQueryNgs::getPatientsNameOrIdFromProjectId($dbh, $projectId, $patientName, $typeAnalyse);
	my $expNbObjects = 1;
	my $obsNbObjects = scalar(@$obsListObjects);
	my $isEqual = 0;
	if ($expNbObjects == $obsNbObjects) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getPatientsNameOrIdFromProjectId_name")
}

sub Test_getPatientsNameOrIdFromProjectId_id {
	my ($dbh, $projectId) = @_;
	my $typeAnalyse = 'id';
	my $patientId = '23443790';
	my ($obsListObjects) = GenBoProjectQueryNgs::getPatientsNameOrIdFromProjectId($dbh, $projectId, $patientId, $typeAnalyse);
	my $expNbObjects = 1;
	my $obsNbObjects = scalar(@$obsListObjects);
	my $isEqual = 0;
	if ($expNbObjects == $obsNbObjects) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getPatientsNameOrIdFromProjectId_name")
}

sub Test_getCaptureInfos_uniqueCapture {
	my ($dbh, $projectId) = @_;
	my ($obsListObjects) = GenBoProjectQueryNgs::getCaptureInfos($dbh, $projectId, 1);
	my $expName = 'agilent_v50';
	my $obsName = $obsListObjects->{'name'};
	my $isEqual = 0;
	if ($expName eq $obsName) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_uniqueCapture")
}

sub Test_getCaptureInfos_multipleCapture {
	my $projectName = "NGS2012_0186";
	my $buffer = GBuffer->new();
	my $project = $buffer->newProject(-name => $projectName);
	my $projectId = $project->id();
	my ($obs) = GenBoProjectQueryNgs::getCaptureInfos($dbh, $projectId, 1);
	my $exp = 'None';
	my $isEqual = 0;
	if ($exp eq $obs) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_multipleCapture")
}

sub Test_getCaptureId {
	my ($dbh) = @_;
	my $captureName = 'agilent_v50';
	my ($obsId) = GenBoProjectQueryNgs::getCaptureId($dbh, $captureName);
	my $expId = '2';
	my $isEqual = 0;
	if ($expId eq $obsId) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureId")
	
}

#sub Test_getOriginMethodsFromPatientId {
#	my ($dbh) = @_;
#	my $patientId = '23443790';
#	my $type = 'SNP';
#	my ($obsListObjects) = GenBoProjectQueryNgs::getOriginMethodsFromPatientId($dbh, $projectId, $type);
#	warn Dumper $obsListObjects;
#	my $expNbObjects = 1;
#	my $obsNbObjects = scalar(@$obsListObjects);
#	my $isEqual = 0;
#	if ($expNbObjects == $obsNbObjects) { $isEqual = 1; }
#	ok($isEqual == 1, "Test - getOriginMethodsFromPatientId")
#}
