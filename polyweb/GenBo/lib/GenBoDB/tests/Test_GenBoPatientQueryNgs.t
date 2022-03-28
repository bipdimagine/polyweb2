use 5.010;
use File::Compare;
use Test::More;
plan tests => 11;

use FindBin qw($Bin);
use lib "$Bin/../../obj-lite/";
use lib "$Bin/../";
use GBuffer;
use GenBoPatientQueryNgs;

my $projectName = "NGS2012_0185";
my $patientId = "23443790";

my $buffer = GBuffer->new();
my $project = $buffer->newProject(-name => $projectName);
my $dbh = $project->buffer->dbh;

print "\n\n### RESULTS:\n\n";
Test_getCaptureBedFileForThisPatient($dbh, $patientId);
Test_getCallingMethodForThisPatient($dbh, $patientId);
Test_getAlignMethodForThisPatient($dbh, $patientId);
Test_getMethodNameForThisPatient_SNP($dbh, $patientId);
Test_getMethodNameForThisPatient_ALIGN($dbh, $patientId);
Test_getCaptureInfos($dbh, $patientId);
print "\n\n";



sub Test_getCaptureBedFileForThisPatient {
	my ($dbh, $patientId) = @_;
	my ($obsTypeFile, $obsBedFile) = GenBoPatientQueryNgs::getCaptureBedFileForThisPatient($dbh, $patientId);
	my $expTypeFile = 'agilent';
	my $expBedFile = 'agilent.v50.bed';
	my $isEqual = 0;
	if (($expTypeFile eq $obsTypeFile) and ($expBedFile eq $obsBedFile)) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureBedFileForThisPatient");
}

sub Test_getCallingMethodForThisPatient {
	my ($dbh, $patientId) = @_;
	my ($obsCallingMethod) = GenBoPatientQueryNgs::getCallingMethodForThisPatient($dbh, $patientId);
	my $expCallingMethod = 'unifiedgenotyper';
	my $isEqual = 0;
	if ($expCallingMethod eq $obsCallingMethod) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCallingMethodForThisPatient");
}

sub Test_getAlignMethodForThisPatient {
	my ($dbh, $patientId) = @_;
	my ($obsAlignMethod) = GenBoPatientQueryNgs::getAlignMethodForThisPatient($dbh, $patientId);
	my $expAlignMethod = 'bwa';
	my $isEqual = 0;
	if ($expAlignMethod eq $obsAlignMethod) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getAlignMethodForThisPatient");
}

sub Test_getMethodNameForThisPatient_SNP {
	my ($dbh, $patientId) = @_;
	my ($obsCallingMethod) = GenBoPatientQueryNgs::getMethodNameForThisPatient($dbh, $patientId, 'SNP');
	my $expCallingMethod = 'unifiedgenotyper';
	my $isEqual = 0;
	if ($expCallingMethod eq $obsCallingMethod) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getMethodNameForThisPatient_SNP");
}

sub Test_getMethodNameForThisPatient_ALIGN {
	my ($dbh, $patientId) = @_;
	my ($obsAlignMethod) = GenBoPatientQueryNgs::getMethodNameForThisPatient($dbh, $patientId, 'ALIGN');
	my $expAlignMethod = 'bwa';
	my $isEqual = 0;
	if ($expAlignMethod eq $obsAlignMethod) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getMethodNameForThisPatient_ALIGN");
}

sub Test_getCaptureInfos {
	my ($dbh, $patientId) = @_;
	my ($obsHashCaptureInfo) = GenBoPatientQueryNgs::getCaptureInfos($dbh, $patientId, 'ALIGN');
	my %expHashCaptureInfo;
	$expHashCaptureInfo{'filename'} = 'agilent.v50.bed';
	$expHashCaptureInfo{'version'} = '50';
	$expHashCaptureInfo{'name'} = 'agilent_v50';
	$expHashCaptureInfo{'type'} = 'agilent';
	$expHashCaptureInfo{'description'} = '50 Mb';
	$expHashCaptureInfo{'capture_id'} = '2';
	my $isEqual = 0;
	if ($expHashCaptureInfo{'filename'} eq $$obsHashCaptureInfo{'filename'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_filename");
	$isEqual = 0;
	if ($expHashCaptureInfo{'version'} eq $$obsHashCaptureInfo{'version'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_version");
	$isEqual = 0;
	if ($expHashCaptureInfo{'name'} eq $$obsHashCaptureInfo{'name'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_name");
	$isEqual = 0;
	if ($expHashCaptureInfo{'type'} eq $$obsHashCaptureInfo{'type'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_type");
	$isEqual = 0;
	if ($expHashCaptureInfo{'description'} eq $$obsHashCaptureInfo{'description'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_description");
	$isEqual = 0;
	if ($expHashCaptureInfo{'capture_id'} eq $$obsHashCaptureInfo{'capture_id'}) { $isEqual = 1; }
	ok($isEqual == 1, "Test - getCaptureInfos_capture_id");
}