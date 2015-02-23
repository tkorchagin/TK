//debug.
//opdebug.
person_path("uth_ss_team/person.asl").
object_path("uth_ss_team/object.asl").

step(0).
sent(0).
freesend.
weight(1).

epsilon_factor(10).

fake_part_id(T098765T089067hsfkibvdhfi).
infty(10000000).


//////// Bertsekas algorithm

person_prefix("p").
object_prefix("o").


/* there's a following interface

Inputs:

I. team(id(Id)) -
	supplier of (any) resource units 
	1. Id - any unique (among sources) atom | numeric identifier
II. part(id(Id),need(Capacity)) -
	consumer of resource units
	1. Id - any unique (among sinks) atom | numeric identifier
	2. Capacity - Integer number of units wanted at the sink
III. team_part_cost(team  (TeeamId),sink(SinkId),cost(Cost)) - 
	Cost (any real) of transportation of one unit from source 
	SourceId to sink SinkId

Outputs:
I. 	parts([A1,A2,...]) - 
		list of records of the form 
		Ai = part(id(PartId),teams([id(T1),...])),
II. totals(util(TotU),cost(TotC),steps(TotS)) -
		auxiliiary (debug) info about calculation
*/


@sdljnfksrjnf[atomic]
+epsilon_factor(EF)[team(A)] : A \== self <-
	.abolish(epsilon_factor(_));
	+epsilon_factor(EF);
.	
	

+!check_start <-	
	!check(.count(part(_,_),Nsinks) & nsinks(Nsinks));
	!check(.count(team_part_cost(_,_,_),Ncosts) & ncosts(Ncosts));
.


+!start <-
	!check_start;	

	.findall(N,part(_,need(N)),PartVols);
	.count(team(_),TotTeams);

	NObjects = math.sum(PartVols);
	
	-+nobjects(NObjects);
	
	if(NObjects < TotTeams) {
		-+nobjects(TotTeams);
		?fake_part_id(FakePartId);
		?infty(Infty);
		+part(id(FakePartId),need(TotTeams - NObjects + 1));
		for(team(id(TeamId))) {
			+team_part_cost(team(TeamId),part(FakePartId),cost(Infty));
		}
	}
	
	
	-+npersons(TotTeams);
	-+direction(direct);
	.findall(pclass(Id,1),team(id(Id)),PersonClasses);
	.findall(oclass(Id,N),part(id(Id),need(N)),ObjectClasses);
	.findall(pocost(I,J,Cost), 
		team_part_cost(team(I),part(J),cost(Cost)), POCosts);
	-+pclasses(PersonClasses);
	-+oclasses(ObjectClasses);
	
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
			?object_path(ObjectPath);
			.create_agent(Object,ObjectPath);
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
			?person_path(PersonPath);
			.create_agent(Person,PersonPath);
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
				.print(NOC);
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

	//.print(1);
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
		!wait(added[team(Recip)]);		
		.send(Recip,Mode,Message);
		+freesend;
.



@sadkljcn[atomic]
+weight(W) : inwork & math.abs(W-1) < 0.00000000000001
<-
	+finished
.

	
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
		.print(calc_output_classes);
		?pclasses(PersonClasses);
		?oclasses(ObjectClasses);
		
		for(.member(pclass(PersonID,ObjectID),PersonClasses)) {
		//.print(PersonID,ObjectID);
			if (assign_list(ObjectID,_)){
				?assign_list(ObjectID, AList);
				.concat([PersonID], AList, NewList);
				-+assign_list(ObjectID, NewList);
			} else {
				+assign_list(ObjectID, [PersonID]);
			}
			
		}
		
		for(.member(pclass(PClass,_),PersonClasses)) {
			for(.member(oclass(OClass),ObjectClasses)) {
				.count(assigned(PClass,OClass)[_],NPO);
				if(direction(direct)) {
					+assign_class(PClass,OClass,NPO);
				} else {
					+assign_class(OClass,PClass,NPO);
				}
			}
		}
		
		.findall(part(id(PartID),TeamsList), assign_list(PartID,TeamsList),Parts);
			
		?parent(Parent);
		.send(Parent,tell,parts(Parts));
		.send(Parent,tell,streams(Streams));
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

