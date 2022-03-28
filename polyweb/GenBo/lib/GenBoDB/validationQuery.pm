package validationQuery;
use strict;
use Data::Dumper;
use Carp;
use Moose;
use MooseX::Method::Signatures;
use IO::Compress::Gzip qw(gzip $GzipError) ;

has 'dbh' => (
	is =>'ro',
	
	#weaken=>1,
	required => 1,
);
 
has 'db' =>(
	is =>'ro',	
	lazy=>1,
	default =>sub {
		my $self = shift;
	
		return "validation_".$self->capture_name();
	}
);

has 'capture_name' =>(
	is =>'ro',	
	required => 1,
);
has 'exists_db'=>(
	is =>'ro',	
	lazy=>1,
	default =>sub {
		my $self = shift;
		my $dbname = $self->db;
		my $query = qq{SHOW DATABASES LIKE '$dbname'};
		my $sth = $self->dbh->prepare($query);
		$sth->execute();
		my $s = $sth->fetchrow_hashref();
		return 1 if $s;
		return undef;
	}
);
sub getVariationByPolyId {
	my ($self,$id) =@_;
	my $db = $self->db;
	my $query = qq{
		select variation_id as id from $db.variations where polyid='$id';
	};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s->{id};
}

sub getVariationByVcfId  {
	my ($self,$id) =@_;
	my $db = $self->db;
	my $query = qq{
		select variation_id as id  from $db.variations where vcfid='$id';
	};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s->{id};
}

method getVariationByGenBoId(Str :$id!) {
	my $db = $self->db;
	my $id2 = "chr".$id;
	my $query = qq{
		select variation_id as id  from $db.variations where polyid='$id' or vcfid ='$id' or vcfid = "$id2";
	};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	return $s->{id};
}

method getValidations (Int :$id , Str :$project, Str :$sample){
		my $db = $self->db;
	my $query = qq{select validation as validation ,validation_sanger as sanger from $db.validations where variation_id=$id and project_name='$project'  and sample_name='$sample' order by modification_date; };
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();	
	
	return ($s->{validation},$s->{sanger});
}

method get_variations_validated(Str :$project_name!, Str :$sample_name!){
	my $db = $self->db;
	my $query = qq{SELECT v.validation_id as validation_id,  vr.vcfid as vcfid, validation, validation_sanger FROM $db.validations v, $db.variations vr where
v.variation_id=vr.variation_id and v.sample_name="$sample_name" and v.project_name="$project_name";};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	#my $s = $sth->fetchall_arrayref();	
	my $variations;
	while ( my $v  = $sth->fetchrow_hashref() ){
	#foreach my $v (@{$sth->fetchall_arrayref()}){
		
		my $var;
		($var->{chromosome},$var->{start},$var->{ref},$var->{alt}) = split("_",$v->{vcfid});
		$var->{validation} = $v->{validation};
		$var->{validation_id} = $v->{validation_id};
		$var->{validation_sanger} = $v->{validation_sanger} if $v->{validation_sanger};
		
		push(@$variations,$var);
	}
	return $variations;
}


method get_variations_ions(Str :$project_name!, Str :$sample_name!){
	my $db = $self->db;
	my $query = qq{SELECT v.validation_id as validation_id,  vr.vcfid as vcfid, validation, validation_sanger FROM $db.validations v, $db.variations vr where
v.variation_id=vr.variation_id and v.sample_name="$sample_name" and v.project_name="$project_name" and v.validation_sanger=0 and v.validation!=-3;};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	#my $s = $sth->fetchall_arrayref();	
	my $variations;
	while ( my $v  = $sth->fetchrow_hashref() ){
		my $var;
		($var->{chromosome},$var->{start},$var->{ref},$var->{alt}) = split("_",$v->{vcfid});
		$var->{vcf_id} = $v->{vcfid};
		$var->{validation} = $v->{validation};
		$var->{validation_id} = $v->{validation_id};
		$var->{validation_sanger} = $v->{validation_sanger} if $v->{validation_sanger};
		$variations->{$v->{vcfid}} = $var;
		#push(@$variations,$var);
	}
	return $variations;
}

method get_variations_in_validation_table(Str :$project_name!, Str :$sample_name!){
	my $db = $self->db;
	my $query = qq{SELECT * FROM $db.validations v, $db.variations vr where v.variation_id=vr.variation_id 
		and v.sample_name="$sample_name" and v.project_name="$project_name";};
    #my $query = qq{SELECT * FROM $db.validations v, $db.variations vr where v.variation_id=vr.variation_id and v.sample_name="$sample_name" and v.project_name="$project_name" and  v.validation_sanger>0 ;};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	
	#my $s = $sth->fetchall_arrayref();	
	my $variations;
	while ( my $v  = $sth->fetchrow_hashref() ){
	#foreach my $v (@{$sth->fetchall_arrayref()}){
		delete $v->{sam_lines};
		$variations->{$v->{vcfid}} = $v; 
		$variations->{$v->{polyid}} = $v; 
		
	}
	return $variations;
}




method get_variations_todo(Str :$project_name!, Str :$sample_name!){
	my $db = $self->db;
	my $query = qq{SELECT * FROM $db.validations v, $db.variations vr where v.variation_id=vr.variation_id and v.sample_name="$sample_name" and v.project_name="$project_name" and v.validation_sanger=0 and v.validation =-3;};
    #my $query = qq{SELECT * FROM $db.validations v, $db.variations vr where v.variation_id=vr.variation_id and v.sample_name="$sample_name" and v.project_name="$project_name" and  v.validation_sanger>0 ;};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	#my $s = $sth->fetchall_arrayref();	
	my $variations;
	while ( my $v  = $sth->fetchrow_hashref() ){
	#foreach my $v (@{$sth->fetchall_arrayref()}){
		delete $v->{sam_lines};
		$variations->{$v->{vcfid}} = $v; 
		$variations->{$v->{polyid}} = $v; 
		
	}
	return $variations;
}

method get_variations_sanger(Str :$project_name!, Str :$sample_name!){
	my $db = $self->db;
	my $query = qq{SELECT v.validation_id as validation_id,  vr.vcfid as vcfid, validation, validation_sanger FROM $db.validations v, $db.variations vr where
v.variation_id=vr.variation_id and v.sample_name="$sample_name" and v.project_name="$project_name" and v.validation_sanger != 0;};
	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	#my $s = $sth->fetchall_arrayref();	
	my $variations;
	while ( my $v  = $sth->fetchrow_hashref() ){
		#foreach my $v (@{$sth->fetchall_arrayref()}){
		
		my $var;
		($var->{chromosome},$var->{start},$var->{ref},$var->{alt}) = split("_",$v->{vcfid});
		$var->{vcf_id} = $v->{vcfid};
		$var->{validation} = $v->{validation};
		$var->{validation_id} = $v->{validation_id};
		$var->{validation_sanger} = $v->{validation_sanger} if $v->{validation_sanger};
		$variations->{$v->{vcfid}} = $var;
		
	}
	return $variations;
}

method get_exons (Str :$project_name!,Str :$sample_name){ 
	my $db = $self->db;
	my $query = qq{select * from $db.exons where  project_name="$project_name" and sample_name ="$sample_name";};
	my $sth = $self->dbh->prepare($query) ;
	
	$sth->execute() || die();
	my $exons;
	while ( my $v  = $sth->fetchrow_hashref() ){
	#foreach my $v (@{$sth->fetchall_arrayref()}){
		my $id = join("-",$v->{chromosome},$v->{start},$v->{end});
		$exons->{$id} = $v;
	
	}
	return $exons;
	}
	
method getTodoVariations (Str :$project_name, Str :$sample_name) {
	my $db = $self->db;
my $sql = qq{SELECT validation_id ,sample_name as patient_name ,vcfid as variation_name ,validation  FROM $db.validations v, $db.variations vr where v.project_name="NGS2013_0201" and v.variation_id=vr.variation_id; };

my $sth = $self->dbh->prepare($sql);
$sth->execute();
my $hres = $sth->fetchall_hashref("validation_id");

my $validations;
foreach my $id (keys %$hres){
	my $var;
	($var->{chr},$var->{start},$var->{ref},$var->{alt}) = split("_",$hres->{$id}->{variation_name});
	$var->{chr_name} =~ s/chr//;
	$var->{validation} = $hres->{$id}->{validation};
	push(@{$validations->{$hres->{$id}->{patient_name}}},$var);
	
}

}
method createVariation(Str :$polyid!, Str :$vcfid!, Str :$genboid, Str :$version!){ 
	
	my $id = $self->getVariationByVcfId($vcfid);
	return $id if $id;
	my $db = $self->db;
	my $query = qq{
		insert into $db.variations (polyid,vcfid,genbo_id,version) values ('$polyid','$vcfid','$genboid','$version');
	};
	
	$self->dbh->do($query) || return undef;
	return $self->getVariationByVcfId($vcfid);
	
}

method existsValidation(Int :$variation_id, Str :$project!, Str :$sample!, Str :$user!){
	my $db = $self->db;
	my $query = qq{
		select validation_id as id  from $db.validations where variation_id=$variation_id and project_name='$project' and user_name='$user' and sample_name='$sample' ;
	};

	my $sth = $self->dbh->prepare($query);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();
	return $s->{id};
}
method createValidation (Int :$variation_id, Str :$project!, Str :$sample!, Str :$user!,Str :$vcf_line!, Int :$validation_status!, Str :$bam_line, Str :$method){ 
	my $db = $self->db;
	my $validation_id = $self->existsValidation(variation_id=>$variation_id,project=>$project,sample=>$sample,user=>$user);

	if ($validation_id){
		my $query = qq{
		update $db.validations set vcf_line=?, modification_date=NOW(),sam_lines=COMPRESS(?),validation=?,method=? where validation_id = $validation_id;
	};
	my $sth= $self->dbh->prepare($query);
	$sth->execute($vcf_line,$bam_line,$validation_status,$method);
	$sth->finish;
	return 1;
	}
	else {								 
	my $query = qq{
		insert into $db.validations (variation_id,project_name,sample_name,user_name,validation,vcf_line,creation_date,modification_date,sam_lines,method) values (?,?,?,?,?,?,NOW(),NOW(),COMPRESS(?),?);
	};
	my $sth= $self->dbh->prepare($query);
	$sth->execute($variation_id,$project,$sample,$user,$validation_status,$vcf_line,$bam_line,$method);
	$sth->finish;
	#$self->dbh->do($query) || return undef;
	return 1;
	}
}

method update_variation_validation(Int :$validation_id, Str :$heho, Str :$method){
	my $db = $self->db;
	my $query = qq{update $db.validations set validation_sanger=$heho , modification_date=NOW() where validation_id=$validation_id};
	#my $query = qq{insert into $db.sanger_validations (validation_id,validation,method,creation_date) values(?,?,?,NOW()) };
	warn $query;
	$self->dbh->do($query);
	
	#$self->dbh->do($query) || return undef;
	return 1;
}


method update_exon_validation(Str :$exon_id){
	my $db = $self->db;
	my $query = qq{update $db.exons set done=1 , modification_date=NOW() where exon_id="$exon_id"};
	$self->dbh->do($query);
	return 1;
}
sub compressData{
	my ($data) = @_;
	my $data2;
	 gzip \$data => \$data2
        or die "gzip failed: $GzipError\n";
    return $data2;
}
method exon_todo (Str :$project_name!, Str :$id!,Str :$sample_name, Str :$chromosome!, Str :$start!, Str :$end!, Str :$transcript!, Str :$user_name, Int :$todo!, Str :$name, Str :$gene! ){ 
	#$bam_line = "toto";
	my $db = $self->db;
	my $query = qq{
		insert into $db.exons (exon_id , project_name,sample_name,gene,chromosome,start,end,transcript,user_name,todo,creation_date,modification_date) 
		                       values("$id","$project_name","$sample_name","$gene","$chromosome",$start,$end,"$transcript","$user_name",$todo,NOW(),NOW() )
		on DUPLICATE KEY UPDATE todo=$todo, modification_date= NOW();
	};
	warn $query;
	$self->dbh->do($query) || die($query);
	return 1;
	}

method is_todo (Str :$project_name!, Str :$id!){ 
	#$bam_line = "toto";
	my $db = $self->db;
	my $query = qq{select * from $db.exons where exon_id="$id" and project_name="$project_name";};
	my $sth = $self->dbh->prepare($query) ;
	
	$sth->execute() || die();
	my $s = $sth->fetchrow_hashref();
	 if (exists $s->{exon_id} && !$s->{done}){
	 	return (1);
	 }
	return;
	}

method save_report (Str :$project!, Str :$sample!,Str :$conclusion!, Str :$json, Str :$user_name){ 
	my $db = $self->db;
	my $query =qq{insert into $db.reports(project,sample,creation_date,json,conclusion,user_name)  values (?,?,NOW(),?,?,?)
		on DUPLICATE KEY UPDATE creation_date=NOW(),json=?,conclusion=?;
	};
	my $sth = $self->dbh->prepare($query) ;
	$sth->bind_param(1,$project);
	$sth->bind_param(2,$sample);
	$sth->bind_param(3,$json);
	$sth->bind_param(4,$conclusion);
	$sth->bind_param(5,$user_name);
	$sth->bind_param(6,$json);
	$sth->bind_param(7,$conclusion);
	
	$sth->execute() || die();
	#$self->dbh->do($query) || die($query);
	return 1;
}
method get_report (Str :$project!, Str :$sample!){ 
	my $db = $self->db;
	my $query =qq{select * from $db.reports where project="$project" and sample="$sample"};
	my $sth = $self->dbh->prepare($query) ;
	$sth->execute() || die();
	my $s = $sth->fetchrow_hashref();
	
	return $s;
	return 1;
}
1;