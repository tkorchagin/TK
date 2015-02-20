//debug.
//opdebug.

step(0).
sent(0).
freesend.
weight(1).

epsilon_factor(10).


//////// Bertsekas algorithm

person_prefix("p").
object_prefix("o").


/* 
nobjects(N) :- dimension(N).
npersons(N) :- dimension(N).

/**/



/* there's a following interface

Inputs:

I. source(id(Id),exceed(Capacity)) -
	supplier of (any) resource units 
	1. Id - any unique (among sources) atom | numeric identifier
	2. Capacity  - Integer number of units available at the source

II. sink(id(Id),need(Capacity)) -
	consumer of resource units
	1. Id - any unique (among sinks) atom | numeric identifier
	2. Capacity - Integer number of units wanted at the sink
	
III. crosscost(source(SourceId),sink(SinkId),cost(Cost)) - 
	Cost (any real) of transportation of one unit from source 
	SourceId to sink SinkId

Outputs:

I. 	transportation_streams([A1,A2,...]) - 
		list of records of the form 
		Ai = stream(source(SourceId),sink(SinkId),quantity(Q)),
		where Q - is nonnegative quantity of item flow from source SourceID
		to sink SinkId.

II. totals(util(TotU),cost(TotC),steps(TotS)) -
		auxiliiary (debug) info about calculation
*/


@sdljnfksrjnf[atomic]
+epsilon_factor(EF)[source(A)] : A \== self <-
	.abolish(epsilon_factor(_));
	+epsilon_factor(EF);
.	
	

+!check_start <-	

	!check(.count(source(_,_),Nsources) & nsources(Nsources));
	!check(.count(sink(_,_),Nsinks) & nsinks(Nsinks));
	!check(.count(crosscost(_,_,_),Ncosts) & ncosts(Ncosts));
.


+!start <-

	!check_start;	

	.findall(N,sink(_,need(N)),SinkVols);
	.findall(N,source(_,exceed(N)),SourceVols);

	TotSinks = math.sum(SinkVols);
	.length(SinkVols,Nsinks);
	-+nsinks(Nsinks);
	TotSources = math.sum(SourceVols);
	.length(SourceVols,Nsources);
	-+nsources(Nsources);
	
	
	if(TotSinks > TotSources) {
		-+nobjects(TotSinks);
		-+npersons(TotSources);
		-+direction(direct);
		.findall(pclass(Id,N),source(id(Id),exceed(N)),PersonClasses);
		.findall(oclass(Id,N),sink(id(Id),need(N)),ObjectClasses);
		.findall(pocost(I,J,Cost), 
			crosscost(source(I),sink(J),cost(Cost)),POCosts);
		-+pclasses(PersonClasses);
		-+oclasses(ObjectClasses);
	} else {
		-+nobjects(TotSources);
		-+npersons(TotSinks);
		-+direction(reverse);
		.findall(pclass(Id,N),sink(id(Id),need(N)),PersonClasses);
		.findall(oclass(Id,N),source(id(Id),exceed(N)),ObjectClasses);
		.findall(pocost(I,J,Cost), crosscost(source(J),sink(I),cost(Cost)),
				POCosts);
		-+pclasses(PersonClasses);
		-+oclasses(ObjectClasses);
	}
	
	+inwork;

	-+objects([]);
	?nobjects(NO);
	?object_prefix(OCP);
	?npersons(NP);
	.my_name(MyName);

	for(.member(oclass(OClass,NOC),ObjectClasses)) {
		.concat(OCP,OClass,OP);
		-+currClassObjects([]);
		for(.range(J,1,NOC)) {
			!get_name(OP,J,Object);
			.create_agent(Object,"object.asl");
			.send(Object,tell,[npersons(NP),main(MyName),
					myclass(OClass)]);
			?currClassObjects(CCOList);			
			.concat([Object],CCOList,NewCCOList);
			-+currClassObjects(NewCCOList);			
		}
		?currClassObjects(CCOList);
		+objectsByClass(OClass,CCOList);
		?objects(Olist);
		.concat(CCOList,Olist,NewOlist);
		-+objects(NewOlist);
	}
	
	+objects_created;

	-+persons([]);
	?person_prefix(PCP);
	?epsilon_factor(EpsFact);

	for(.member(pclass(PClass,NPC),PersonClasses)) {
		.concat(PCP,PClass,PP);
		.findall(PClassCost,
			.member(pocost(PClass,_,PClassCost),POCosts) 
			,PClassCosts);
		.max(PClassCosts,MaxPClassCost);
		Eps = MaxPClassCost / EpsFact;
		for(.range(I,1,NPC)) {
			!get_name(PP,I,Person);
			.create_agent(Person,"person.asl");
			.send(Person,tell,[nobjects(NO),main(MyName),
					myclass(PClass),
					epsilon(Eps)]);
			?persons(Plist);
			.concat([Person],Plist,NewPlist);
			-+persons(NewPlist);
					
			for(.member(oclass(OClass,NOC),ObjectClasses)) {
				.concat(OCP,OClass,OP);
				.member(pocost(PClass,OClass,Cost),POCosts);	// determining cost 
				Util = MaxPClassCost - Cost + 1;
				for(.range(J,1,NOC)) {
					!get_name(OP,J,Object);
					.send(Person,tell,util(Object,Util));
					.send(Person,tell,cost(Object,Cost));
					.send(Object,tell,util(Person,Util));
				}
			}
		}
	} 
	+persons_created;


	!check(finished_objects_round);
	.abolish(finished_objects_round);
	
	!check(finished_persons_round);
	.abolish(finished_persons_round);

	?persons(Persons);
	?objects(Objects);
	.send(Persons,achieve,set_objects(Objects));
	!check(finished_persons_round);
	.abolish(finished_persons_round);
	.send(Objects,achieve,set_persons(Persons));
	
	!check(finished_objects_round);
	.abolish(finished_objects_round);
		
	!run;
.

+!get_name(Prefix,I,Name) <-
		.concat(Prefix,I,NameStr);
		.term2string(Name,NameStr);
.

objectClass(Object,OClass) :-
	objectsByClass(OClass,COList) 
	& .member(Object,COList).

@bkbwve[atomic]
+!remlambda(Lambda) <- -lambda(Lambda).


@ljnbdgfd[atomic]
+!addweight(Share)[source(Source)] <-
	?weight(Weight);
	.send(Source,tell,added);
	-+weight(Weight+Share);
	!print(weight(Weight+Share));
.	


@eswnefs90[atomic]
+!sent_handle(N,Recip) <- 
		?sent(Sent);
		-+sent(Sent+N);
		?weight(Weight);
		?npersons(Dim);
		Share = Weight / (N+Dim);
		.send(Recip,achieve,addweight(Share));	// share the weight with recipients
		!addweight(-N*Share);
.


@eswneasafs90[atomic]
+?share_weight(Share) <- 
		?weight(Weight);
		?npersons(Dim);
		Share = Weight / (1+Dim);
		!addweight(-Share);
.


+!send(Recip,Mode,Message) : .list(Recip)
		<-
		!check(freesend);
		.abolish(freesend);
		.length(Recip,N);
		!sent_handle(N,Recip);		
		for(.member(Agent,Recip)) {
			!check(added[source(Agent)]);
		}
		.abolish(added[source(Agent)] & .member(Agent,Recip));
		.send(Recip,Mode,Message);
		+freesend;
.

+!send(Recip,Mode,Message) 
		<-
		!check(freesend);
		.abolish(freesend);
		!sent_handle(1,Recip);
		!wait(added[source(Recip)]);		
		.send(Recip,Mode,Message);
		+freesend;
.



@sadkljcn[atomic]
+weight(W) : inwork & math.abs(W-1) < 0.00000000000001
				<- +finished.

	
+finished
	<-
	?objects(Objects);
	.send(Objects,achieve,output);
	?persons(Persons);
	.send(Persons,askOne,actual_utility(U,C,Step));
.

+!run <-
	+inwork;
	?persons(Persons);
	!send(Persons,achieve,start);
.

@adlvfmsd[atomic]
+assigned(PClass,OClass)[_] : .count(assigned(_,_)[_],N) & npersons(N)
		<-
		!calc_output_classes;
		!kill_objects; 
.


+!calc_output_classes 
		<-
		?pclasses(PersonClasses);
		?oclasses(ObjectClasses);
		for(.member(pclass(PClass,_),PersonClasses)) {
			for(.member(oclass(OClass,_),ObjectClasses)) {
				.count(assigned(PClass,OClass)[_],NPO);
				if(direction(direct)) {
					+assign_class(PClass,OClass,NPO);
				} else {
					+assign_class(OClass,PClass,NPO);
				}
			}
		}
		.findall(stream(source(Source),sink(Sink),quantity(Quantity)),
			assign_class(Source,Sink,Quantity),Streams);
		?parent(Parent);
		.send(Parent,tell,transportation_streams(Streams));
.				

+!calc_output_classes.				

@adbfns4567bdmv[atomic]
+!kill_objects
 : not debug & objects_created <-
	-objects_created;
	?objects(Objects);
	?persons(Persons);
	for(.member(Agent,Objects)) {
		.kill_agent(Agent);
	}
.

+!kill_objects.

@adbfnsbdmwev[atomic]
+!kill_persons
 : not debug & persons_created <-
	-persons_created;
	?persons(Persons);
	for(.member(Agent,Persons)) {
		.kill_agent(Agent);
	}
.

+!kill_persons.

@sfdjnvru[atomic]
+person_end[_] : 
		.count(person_end[_],N) & npersons(N)
		<-
		.abolish(person_end);
		+finished_persons_round;  
.

@sfdjnvqeru[atomic]
+object_end[_] : 
		.count(object_end[_],N) & nobjects(N)
		<-
		.abolish(object_end);
		.count(assigned_object[_],Nass);
		-+assigned_objects(Nass);
		+finished_objects_round;  
.

-finished_objects_round <-
	.abolish(assigned_object).



@rnveot[atomic]
+actual_utility(_,_,_)[_] 
	: .count(actual_utility(_,_,_)[_],N) & npersons(N)
	<-
	.findall(U,actual_utility(U,_,_)[_],Utils);
	.findall(C,actual_utility(_,C,_)[_],Costs);
	.findall(Step,actual_utility(_,_,Step)[_],Steps);
	.abolish(actual_utility(_,_,_)[_]);
	-+totUtil(math.sum(Utils));
	-+totCost(math.sum(Costs));
	-+totSteps(math.sum(Steps));
	?parent(Parent);
	?totUtil(TotU);
	?totCost(TotC);
	?totSteps(TotS);
	.send(Parent,tell,totals(util(TotU),cost(TotC),steps(TotS)));
	+finished_persons_round;
	!kill_persons;
.

+!check(A) : A.
+!check(A) <- .wait(10); !check(A).

+!print(A) : opdebug <- .print(A).
+!print(A).

+!wait(A) <- 
		!check(A);
		.abolish(A);
.

