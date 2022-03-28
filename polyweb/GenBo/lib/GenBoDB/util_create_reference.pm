package util_create_reference;
use Carp;
use strict;
use Set::IntSpan::Fast ;

my $size_slice = 10000;


sub new_chr_reference {
	my ($project,$chr_name,$variations,$cpt) = @_;
	#$cpt =1 unless $cpt;
	
	my $buffer = $project->buffer;
	warn "new chromosome for this poject create from scratch";
	my $span = Set::IntSpan::Fast::XS->new();
	my $span_slice = constructSlice($buffer,$chr_name,$span);
	my $slices = returnArraySpans($span_slice);
	my $span_var = construct_span_variation($variations->{$chr_name});
	my $iter = $span_var->iterate_runs();
    while (my ( $start, $end ) = $iter->()) {
	
	# foreach my $var (sort {$a->{start} <=> $b->{start}} @{$variations->{$chr_name}}){
	 	
    		if ($span_slice->contains_all_range($start,$end)){
    			
				my $good_slice = findSlice($slices,$start);
				#warn " --> ".$good_slice->as_string();
				$span = $span->union($good_slice);
    		}
    		else {
    			# je cree un nouveau temset mais il faut absolument verifier que celui-ci du coup n'overlape pas avec un gene
    			# la consequence etait un gene sur deux references celle cree par la variation et celle du gene 
    			my $real_start = ($start-$size_slice);
    			$real_start = 1 if $real_start<=0;
    			 my $tempset =  Set::IntSpan::Fast::XS->new($real_start."-".($end+$size_slice));
    			if ($span_slice->contains($start-$size_slice)) {
    				$tempset = $tempset->union(findSlice($slices,$real_start));
    			}
    			if ($span_slice->contains($end+$size_slice)) { 
    				$tempset = $tempset->union(findSlice($slices,$end+$size_slice));
    			}
    			$span = $span->union($tempset);
    			
    		}
    			
    }
    
    my $good_slices = returnArraySpans($span);
  
    foreach my $sp (@$good_slices){
    		
    	    	$cpt = createAllObjectsFromSpan($project,$chr_name,$sp,$cpt);
    }
    
    
    warn "end create ==> ".scalar(@$good_slices);	
    return $cpt;
}

sub construct_span_variation {
	my ($variations) = @_;
	my $span =  Set::IntSpan::Fast->new();
	foreach my $var (@{$variations}){
		$span->add_range($var->{start},$var->{end});
	}
	return $span;
}
sub update_chr_reference {
	my ($project,$chr,$variations) = @_;
	warn "update chr :".$chr->name();
	my $buffer = $project->buffer();
	my $span = $project->getContigSpan($chr);
	
	my $chr_name = $chr->name();
	my $span_slice = constructSlice($buffer,$chr_name,$span);
	
	my $slices = returnArraySpans($span_slice);
	
 	my @new_slice;
 
	foreach my $v (@{$variations->{$chr_name}}){ 
		my $debug;
		
		#$debug=1 if $v->{position} == 71634707;
		
		warn "FIND " if $debug;
		unless ($span->contains( $v->{position} )) {
		
			if ($span_slice->contains( $v->{position} )) {
				my $good_slice = findSlice($slices,$v->{position});
				warn "new gene slice ".$good_slice->as_string()." ".$debug;
				
				
				$span = $span->union($good_slice);
				createAllObjectsFromSpan($project,$chr_name,$good_slice);
				
				push(@new_slice,$good_slice);
			}
			else {
				my $tempset  = Set::IntSpan::Fast::XS->new(($v->{position}-$size_slice)."-".($v->{position}+$size_slice));
				my $inter = $span->intersection($tempset);
				if ($inter->is_empty()){
					warn "new empty slice ".$tempset->as_string();
							
					createAllObjectsFromSpan($project,$chr_name,$tempset);
					$span = $span->union($tempset);
					push(@new_slice,$tempset);
				}
				else {
					warn "new set ".$tempset->as_string() if $debug;
					my ($st,$en) = split("-",$inter->as_string);
					my $sps = returnArraySpans($span);
					my $find = findSlice($sps,$st);
					warn "splice find ".$find->as_string()  if $debug;;
					warn "start ".$st." end ".$en  if $debug;;
					my $diff = $tempset->diff($find) ;				
					my ($st2,$en2) = split("-",$diff->as_string);
					warn "st2 ".$st2." end2 ".$en2  if $debug;;
				
					my $newspan = updateReference($chr,$st2,$en2,$project);
					$span = $span->union($newspan);
						
					warn ("problem tempset overlap");
				}
			}
			confess() if $debug;
			#findSlice($buffer,$chr, $v->{position});
		}
		
		else {
			die() if $debug;
			warn "nothing to do " if $debug;
		}
	}
	
}



sub updateReference{
	my ($chr,$start,$end,$project) = @_;
	my $buffer = $project->buffer;
	warn "update Reference $start $end";
	my $pid = $project->id;
	
	
	my $sql = qq{select R.GENBO2_ID as id ,START1 as start , end1 as end from GENBO G ,RELATION R where origin_id=$pid and G.GENBO_id=R.GENBO2_ID and type_genbo_id = 2 and start1=$end+1;};
	my $sth = $buffer->dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();
	
	if (defined $s){
	my $newchr_start = $start;
	my $newchr_end = $s->{end};
	my $add = abs($start-$end)+1;	
	my $id = $s->{id};
	my $sql = qq{update RELATION set start1=$newchr_start,end2=end2+$add where GENBO2_ID = $id and type_relation_id=1};	
	$buffer->dbh->do($sql) || die("probleme lors de l'update position on chr");		
	my $sql2 = qq{update RELATION set start1=start1+$add,end1=end1+$add where GENBO_ID = $id and type_relation_id=5};
	$buffer->dbh->do($sql2) || die("probleme lors de l'update position on contig");		
	my $seq = get_sequence($buffer,$chr->name,$newchr_start,$newchr_end);
	warn $seq;
	my $seqGroupId=GenBoWrite::insertSequence($buffer->dbh,$id,$seq);			
	create_contig($project,$id,1,$add,1,$add,1);		 	
	return Set::IntSpan::Fast::XS->new($newchr_start."-".$newchr_end);
	}
	else {
	
	
	my $sql = qq{select R.GENBO2_ID as id ,START1 as start , end1 as end ,end2 as new_start from GENBO G ,RELATION R where origin_id=$pid and G.GENBO_id=R.GENBO2_ID and type_genbo_id = 2 and end1=$start-1;};
	my $sth = $buffer->dbh->prepare($sql);
	$sth->execute();
	my $s = $sth->fetchrow_hashref();
	confess() unless $s;
	my $id = $s->{id};
	
	
	my $newchr_start = $s->{start};
	my $newchr_end = $end;
	my $add = abs($start-$end)+1;
	
	
	my $sql = qq{update RELATION set end1=$newchr_end,end2=end2+$add where GENBO2_ID = $id and type_relation_id=1};	
	$buffer->dbh->do($sql) || die("probleme lors de l'update position on chr");		
	
	
	my $seq = get_sequence($buffer,$chr->name,$newchr_start,$newchr_end);
	warn $seq;
	my $seqGroupId=GenBoWrite::insertSequence($buffer->dbh,$id,$seq);
	###
	# position du nouveau contig
	###
	my $contig_start = $s->{new_start}+1;
	my $contig_end = ($contig_start+$add) -1;
	
				
	create_contig($project,$id,$contig_start,$contig_end,1,$add,1);
	return Set::IntSpan::Fast::XS->new($newchr_start."-".$newchr_end);
	
	}
	#warn "end";
	#confess();
	
	
}

sub returnArraySpans {
	my ($span) = @_;
	my @slices;
	my $iter = $span->iterate_runs();
 

  	while (my ( $from, $to ) = $iter->()) {
  	  	my $tempset  = Set::IntSpan::Fast::XS->new($from."-".$to);
  	 	push(@slices,$tempset);
  	}
  	return \@slices;
}


sub constructSlice {
 my ($buffer,$chr_name,$span) = @_;
my $db = $buffer->getRegistry()->get_DBAdaptor( "human", "core" );	
my $slice_adaptor = $db->get_SliceAdaptor();
my $slice =$slice_adaptor->fetch_by_region( 'chromosome', $chr_name );


my $gene_adaptor = $buffer->getRegistry()->get_adaptor( 'Human', 'Core', 'Gene' );
my $genes = $gene_adaptor->fetch_all_by_Slice($slice);
my $setAll = Set::IntSpan::Fast::XS->new();
my $nbgene = 0 ;
my $debug;
my $rstart;
my $rend;
while ( my $gene = shift @{$genes} ) {
	
		my $start       = $gene->start()-$size_slice;
		$start = 1 if $start <=0;
		my $end         = $gene->end()+$size_slice;
	#	if (($end-$start) < 50_000){
	#		$end += 25_000;
	#		$start -= 25_000; 
	#	} 
	
		my $tempset =  Set::IntSpan::Fast::XS->new($start."-".$end);	  			
	  	$setAll = $setAll->union($tempset);
	  	$nbgene ++; 
}
my $set_diff = $setAll->diff($span);

return $set_diff;
	
	
}

sub findSlice {
	my ($slices,$pos) = @_;
	foreach my $sl (@$slices){
		return $sl if $sl->contains($pos);
	}
	confess("big problem");
}	


sub createAllObjectsFromSpan {
	my ($project,$chr_name,$span,$cpt) = @_;
	
	my $cpt_ref = 1;
	my $cpt_contig = 1;
	my ($st2,$en2) = split("-",$span->as_string);
	my $len = ($en2-$st2)+1;
	my $id_ref;	
	confess($st2." ".$en2)  unless $st2;
	($id_ref,$cpt) = create_reference($project,$chr_name,$st2,$en2,$cpt);
	confess() unless $id_ref;
	my $id_contig;
		
	($id_contig,$cpt_contig) = create_contig($project,$id_ref,1,$len,1,$len,$cpt);
	return $cpt;
}



sub create_reference {
my($project,$chr_name,$start,$end,$cpt) = @_;
my $buffer = $project->buffer;
$cpt =1 unless $cpt;
my $typeChr = $buffer->getType("chromosome");
my $typeReference=$buffer->getType("reference");
my $typeRelationChr2Ref=GenBoRelationQuery::getRelationType($buffer->dbh,'chromosome2reference');
my $genbo = GenBoQuery::getGenboByName($buffer->dbh,$chr_name,$typeChr->id,0);
my $chr_id = $genbo->{id};
confess("can find chr ".$chr_name) unless $chr_id;


my $id;
my $seq =get_sequence($buffer,$chr_name,$start,$end);
 ($id,$cpt) = GenBoWrite::createGenBoWithCompteur($buffer->dbh,$cpt,$typeReference,$project->id); 
  my $seqGroupId=GenBoWrite::insertSequence($buffer->dbh,$id,$seq);
  GenBoRelationWrite::addRelation($buffer->dbh,$chr_id,$id,$typeRelationChr2Ref,$start,$end,1,$end-$start+1,1);
  return ($id,$cpt);
	
}

sub create_contig {
	my($project,$id_ref,$start_ref,$end_ref,$start_contig,$end_contig,$cpt) = @_;
	$cpt=1 unless defined $cpt;
	
	my $buffer = $project->buffer;
	my $typeContig=$buffer->getType("contig");
	my $typeRelationRef2ContigId=GenBoRelationQuery::getRelationType($buffer->dbh,'reference2contig');
	my ($contigId,$toto) = GenBoWrite::createGenBoWithCompteur($buffer->dbh,$cpt,$typeContig,$project->id);
	
	#my $seqGroupId=GenBoWrite::insertSequence($buffer->dbh,$contigId,$ref->getSequence);	
	GenBoRelationWrite::addRelation($buffer->dbh,$id_ref,$contigId,$typeRelationRef2ContigId,$start_ref,$end_ref,$start_contig,$end_contig,1);
	return $contigId;
}

sub get_sequence {
	my ($buffer,$chr_name,$start,$end) = @_;


	my $db = $buffer->getRegistry()->get_DBAdaptor( "human", "core" );	
	my $slice_adaptor = $db->get_SliceAdaptor();


	my $typeReference=$buffer->getType("reference");
	my $typeRelationChr2Ref=GenBoRelationQuery::getRelationType($buffer->dbh,'chromosome2reference');
	my $seq = $slice_adaptor->fetch_by_region(
			'chromosome',$chr_name,
			$start,
			$end
		)->seq();
		
		return $seq;
}
 	
sub length_chr {
	my ($buffer,$chr_name) = @_;
	
	my $db = $buffer->getRegistry()->get_DBAdaptor( "human", "core" );	
	my $slice_adaptor = $db->get_SliceAdaptor();
	my $slice = $slice_adaptor->fetch_by_region( 'chromosome', $chr_name );	
	return $slice->length();
}
 
