=head1 NAME

GenBoRelationWrite : Use to insert records in the table RELATION of the database

=head1 SYNOPSIS


=head1 DESCRIPTION

GenBoRelationWrite provides a set of functions to write in the table RELATION of the database

=head1 METHODS

=cut

package GenBoRelationWrite;
use FindBin qw($Bin);
use lib "$Bin/../../GenBoDB";
use GenBoDelete;
use Carp;
use strict;

=head2 _addRelation
	Title   : _addRelation
 	Usage   : GenBoRelationWrite::_addRelation($dbh,$GenBoId1,$GenBoId2,$typeRelationId,$start,$end,$start2,$end2,$strand,$allele,$consequence,$methodId);
 	Function: Insert a relation in the table RELATION for the specified GenBos ids with the differents attributes passed to the method
 	Returns : The id of the inserted relation (int)
 	Args    : A connection to the database, the first and second GenBo id of the relation (int), the type of the relation id (int), the positions and strand (int), the allele concerns a variation (string), the consequence if concerns a varaiation (string)
	Note    : Argument method is not used
=cut

sub _addRelation {
	my ($dbh,$genboId1,$genboId2,$type,$start,$end,$start2,$end2,$strand,$score,$text,$consequence,$method) = @_;
	$strand=0 unless $strand;
	$score=-1 unless $score;
	$text='' unless $text;
	$consequence='' unless $consequence;
	$method='' unless $method;
	
	my $r = GenBoRelationQuery::getRelationId($dbh,$genboId1,$genboId2,$type);
	GenBoDelete::deleteByRelationId($dbh,$r->{id})if defined $r ;
#	return $r->{id} if defined $r;
	my $query = qq{
		insert into RELATION (GENBO_ID,GENBO2_ID,TYPE_RELATION_ID,START1,END1,START2,END2,STRAND,SCORE,TEXT,CONSEQUENCE,METHOD) 
		values ('$genboId1','$genboId2','$type','$start','$end','$start2','$end2','$strand','$score','$text','$consequence','$method');
	};
	$dbh->do($query) ;
	
	$r = GenBoRelationQuery::getRelationId($dbh,$genboId1,$genboId2,$type);
	return $r->{id};
	
}


=head2 addRelation
	Title   : addRelation
 	Usage   : GenBoRelationWrite::addRelation($dbh,$GenBoId1,$GenBoId2,$typeId,$start,$end,$start2,$end2,$strand);
 	Function: Insert a relation in the table RELATION for the specified GenBos ids with the differents attributes passed to the method
 	Returns : The id of the inserted relation (int)
 	Args    : A connection to the database, the first and second GenBo id of the relation (int), the type of the relation id (int), the positions and strand (int)
	Note    : 
=cut


sub addRelation {
	my ($dbh,$genboId1,$genboId2,$type,$start,$end,$start2,$end2,$strand) = @_;
	$strand=1 unless $strand;
	confess("problem with argument id1- $genboId1 id2- $genboId2 \nst $start end $end\n st2 $start2 end2 $end2 \n strand $strand type $type\n") unless $genboId1 && $genboId2 && $start && $end && $type && $start2 && $end2;
	#my $r = GenBoRelationQuery::getRelationId($dbh,$genboId1,$genboId2,$type);
	#warn $r;
	#return $r->{id} if exists $r->{id};
	
	my $query = qq{
		insert into RELATION (GENBO_ID,GENBO2_ID,TYPE_RELATION_ID,START1,END1,START2,END2,STRAND) 
		values ('$genboId1','$genboId2','$type','$start','$end','$start2','$end2','$strand') 
		 on duplicate KEY UPDATE START1=$start , END1=$end, START2=$start2, END2=$end2, STRAND=$strand   
	};

	$dbh->do($query) || die($query);
	my $r = GenBoRelationQuery::getRelationId($dbh,$genboId1,$genboId2,$type);
	return $r->{id};	
}

=head2 addAnnex
	Title   : addAnnex
 	Usage   : GenBoRelationWrite::addAnnex($dbh,$relationId,$methodId,$score,$allele);
 	Function: Insert an annex in the table RELATION_ANNEX for the specified relation id with the differents attributes passed to the method
 	Returns : Nothing
 	Args    : A connection to the database, the id of the relation to add the annex (int), the method id (int), the score (int), the allele (string)
	Note    : 
=cut

sub addAnnex {
	my ($dbh,$relationid,$method_id,$score,$text) = @_;
	confess("problem with argument program") unless $method_id;
	confess("problem with argument relationid") unless $relationid;
	my $query = qq{ insert into RELATION_ANNEX(relation_id,method_id,score,text) values($relationid,$method_id,$score,"$text") 
				  on duplicate KEY UPDATE score=$score , text="$text"	  
	};

	$dbh->do($query);
	
	return ;
}

=head2 addAnnex
	Title   : addAnnex
 	Usage   : GenBoRelationWrite::addAnnex($dbh,$relationId,$methodId,$score,$allele);
 	Function: Insert an annex in the table RELATION_ANNEX for the specified relation id with the differents attributes passed to the method
 	Returns : Nothing
 	Args    : A connection to the database, the id of the relation to add the annex (int), the method id (int), the score (int), the allele (string)
	Note    : 
=cut

sub newAnnexForRelation {
	my ($args) = @_;
	my $dbh = $args->{dbh};
	
	#confess("problem with argument score") unless $args->{score};
	my $score = $args->{score};
	my $relation_id = $args->{relation_id};
	my $method_id = $args->{method_id};
	my $text = $args->{text};
	my $score_2 = $args->{score_2};
	my $score_3 = $args->{score_3};
	my $score_4 = $args->{score_4};
	$score_2 = 0 unless $score_2;
	$score_3 = 0 unless $score_3;
	$score_4 = 0 unless $score_4;
	confess("problem dbh") unless $dbh;
	confess("problem with method") unless $method_id;
	confess("problem with argument relationid") unless $relation_id;
	confess("problem with argument score") unless exists $args->{score};
	my $he = $args->{he};
	my $ho = $args->{ho};
	my $query = qq{ insert into RELATION_ANNEX(relation_id,method_id,score,text,score2,score3,score4,he,ho) values($relation_id,$method_id,$score,"$text",$score_2,$score_3,$score_4,$he,$ho) 
				  on duplicate KEY UPDATE score=$score , text='$text',score2=$score_2,score3=$score_3,score4 = $score_4,he = '$he', ho = '$ho'	  
	};
	$dbh->do($query);# || die ($query);
	
	return ;
}


=head2 valider
	Title   : valider
 	Usage   : GenBoRelationWrite::valider($dbh,$relationId,$status);
 	Function: To validate the relation of the specified id with the specified status
 	Returns : Nothing
 	Args    : A connection to the database, the id of the relation to validate (int), the status of the validation (int)
	Note    : 
=cut

sub valider{
	my($dbh,$id,$valeur) = @_;
	my $sql = qq {
		update RELATION set IS_VALID='$valeur' where RELATION_ID= '$id';
	};
	return ($dbh->do($sql));
}


1;