package GenBoPatientQueryNgs;
 
use strict;
use Carp;
use Data::Dumper;




sub getCaptureBedFileForThisPatient {
	my ($dbh, $patientId) = @_;
	my $query = qq{
		select cap.type as type, cap.filename as fileName
	        FROM PolyprojectNGS.patient pat, PolyprojectNGS.capture_systems cap
	            where pat.genbo_id=$patientId and pat.capture_id=cap.capture_id;	
	};
	my $sthType = $dbh->prepare($query);
	$sthType->execute();
	my $type = $sthType->fetchall_hashref('type');
	my @tabType = keys %$type;
	my $typeFile = $tabType[0];
	my $sthBed = $dbh->prepare($query);
	$sthBed->execute();
	my $file = $sthBed->fetchall_hashref('fileName');
	my @tabBed = keys %$file;
	my $bedFile = $tabBed[0];
	return ($typeFile, $bedFile);
}


sub getCallingMethodForThisPatient {
	my ($dbh, $patientId) = @_;
	return getMethodNameForThisPatient($dbh, $patientId, 'SNP');
}

sub getAlignMethodForThisPatient {
	my ($dbh, $patientId) = @_;
	return getMethodNameForThisPatient($dbh, $patientId, 'ALIGN');
}

sub getMethodNameForThisPatient {
	my ($dbh, $patientId, $method) = @_;
	my $query = qq{
		SELECT m.name as methodName 
    		FROM PolyprojectNGS.patient p, PolyprojectNGS.run r, PolyprojectNGS.run_methods rm, PolyprojectNGS.methods m
        		where p.genbo_id=$patientId and p.run_id=r.run_id and r.run_id=rm.run_id and rm.method_id=m.method_id and m.type='$method';
	};
	my $sthType = $dbh->prepare($query);
	$sthType->execute();
	my $name = $sthType->fetchall_hashref('methodName');
	my @tab = keys $name;
	return \@tab;
}

sub getCaptureInfos {
	my ($dbh, $patientid) =@_;
	my $query = qq{SELECT c.* FROM PolyprojectNGS.patient p, PolyprojectNGS.capture_systems c where p.genbo_id=$patientid and p.capture_id=c.capture_id; };
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $res = $sth->fetchall_arrayref({});#$sth->fetch_hashref("id");
	return $res->[0] if $res;
}

#sub getGenBoId {
#	my ($dbh, $patientId) = @_;
#	my $query = qq{
#		SELECT p.genbo_id as genboId 
#    		FROM PolyprojectNGS.patient p
#        		where p.patient_id=$patientId;
#	};
#	my $sthType = $dbh->prepare($query);
#	$sthType->execute();
#	my $name = $sthType->fetchall_hashref('genboId');
#	my @tab = keys $name;
#	return $tab[0];
#}

1;