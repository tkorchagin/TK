debug.
//opdebug.
nokill.

step(0).
sent(0).
freesend.
weight(1).

epsilon_factor(10).
oclass_path("src/object_class.asl").
pclass_path("src/person_class.asl").

//////// Bertsekas algorithm

person_prefix("p").
object_prefix("o").


version("Version 5.0").

/*

Version 4.2 : 	1) LocalMaxSteps corrected
					2) Sinks & Sources messed up - fixed
					3) Non-positove capacities are filtered 
					4) Costs number is put under control
					5) MyClass flows in pclass were not checked for empty list
					
Version 4.2.1 : 	1) Double inversion of NewBidProfits eliminated		

Version 5.0: You Can Specify Allowed Sources for Each Sink    

This routine implements solution of the 
Trasportation Problem described at 
sec. 4 (pp. 84-89) of the paper 
Dimitri P. BERTSEKAS and David A. CASTANON
THE AUCTION ALGORITHM FOR THE TRANSPORTATION PROBLEM. 
published in 
Annals of Operations Research 20(1989) pp. 67 - 96

*/


/* there's a following interface

Inputs:

I. source(id(Id),exceed(Capacity)) -
	supplier of (any) resource units 
	1. Id - any unique (among sources) atom | numeric identifier
	2. Capacity  - Integer number of units available at the source

II. sink(id(Id), need(Capacity)) -
	consumer of resource units
	1. Id - any unique (among sinks) atom | numeric identifier
	2. Capacity - Integer number of units wanted at the sink
	
III. crosscost(source(SourceId),sink(SinkId),cost(Cost)) - 
	Cost (any real) of transportation of one unit from source 
	SourceId to sink SinkId

IV. allowed_sources(sink(id(Id),sources([Id1,...,IdN]))

	1. Id - sink identifier
	3. Id1,...,IdN - Ids of sources, which can be directed to this sink

	
Outputs:

I. 	transportation_streams([A1,A2,...]) - 
		list of records of the form 
		Ai = stream(source(SourceId),sink(SinkId),quantity(Q)),
		where Q - is nonnegative quantity of item flow from source SourceID
		to sink SinkId.

II. totals(util(TotU),cost(TotC),steps(TotS)) -
		auxiliiary (debug) info about calculation
*/

init.

+init <-
				// identify myself
				?version(Version);
				.print("Transportation task solver utility",
				" based on Bertsekas-Catanon auction algorithm. ", Version);

.	


@sdljnfksrjnf[atomic]
+epsilon_factor(EF)[source(A)] : A \== self <-
	.abolish(epsilon_factor(_));
	+epsilon_factor(EF);
.	
	

+!check_start <-	

	!check(.count(source(_,_),Nsources) & nsources(Nsources));
	!check(.count(sink(_,_),Nsinks) & nsinks(Nsinks));
	//!check(.count(crosscost(_,_,_),Ncosts) & ncosts(Ncosts));
.





+!stop(A) <-
	.print("Error: ",A);
	.print("Will Stop in 100 sec.");
	.wait(100000);
	.stopMAS;
.

@sdfdsf[atomic]
+!iterate_step 
	<-
	?step(Step);
	-+step(Step+1);
.	

+!start <-
	!iterate_step;
	!check_start;
	
	
	
	.findall(N,sink(_,need(N)),SinkVols);
	.findall(N,source(_,exceed(N)),SourceVols);
	

	TotSinks = math.sum(SinkVols);
	.length(SinkVols,Nsinks);
	//-+nsinks(Nsinks);
	if(Nsinks <= 0) {
		!stop("total sinks <= 0");
	}
	TotSources = math.sum(SourceVols);
	.length(SourceVols,Nsources);
	//-+nsources(Nsources);
	if(Nsources <= 0) {
		!stop("total sources <= 0");
	}
	.min(SourceVols,MinSourceVol);
	.min(SinkVols,MinSinkVol);
	
	if(MinSourceVol <=0 | MinSinkVol <=0) {
		!stop("One or more of capacities <= 0");
	}
	
	.findall(Id,source(id(Id),_),AllSources);
	for(sink(id(SinkId),_)) {
		if(not allowed_sources(sink(SinkId),_)) {
			+allowed_sources(sink(SinkId),sources(AllSources));
		}
	}
	
	.abolish(allowed_persons(_,_));
	if(TotSinks > TotSources) {
		-+nobjects(TotSinks);
		-+npersons(TotSources);
		-+direction(direct);
		-+nperson_classes(Nsources);
		-+nobject_classes(Nsinks);
		.findall(pclass(Id,N),source(id(Id),exceed(N)),PersonClasses);
		.findall(oclass(Id,N),sink(id(Id),need(N)),ObjectClasses);
		.findall(pocost(I,J,Cost), crosscost(source(I),sink(J),cost(Cost)),
				POCosts);
		-+pclasses(PersonClasses);
		-+oclasses(ObjectClasses);
		for(allowed_sources(sink(ASink),sources(ListOfSources)))
		{
			+allowed_persons(object(ASink),persons(ListOfSources));
		}

	} else {
		-+nobjects(TotSources);
		-+npersons(TotSinks);
		-+direction(reverse);
		-+nperson_classes(Nsinks);
		-+nobject_classes(Nsources);
		.findall(pclass(Id,N),sink(id(Id),need(N)),PersonClasses);
		.findall(oclass(Id,N),source(id(Id),exceed(N)),ObjectClasses);
		.findall(pocost(I,J,Cost), crosscost(source(J),sink(I),cost(Cost)),
				POCosts);
		-+pclasses(PersonClasses);
		-+oclasses(ObjectClasses);
		for(.member(oclass(SourceId,_),ObjectClasses))
		{
			.findall(SinkId, 
				allowed_sources(sink(SinkId),sources(ListOfSources))
				& .member(SourceId,ListOfSources),
					ListOfSinks);
			+allowed_persons(object(SourceId),persons(ListOfSinks));
		}
	}
	
	
	
	?nobject_classes(NOClasses);
	?nperson_classes(NPClasses);

	.my_name(MyName);
	
	-+object_classes([]);
	?object_prefix(OCP);

	.abolish(oclass_agent(_,_));
	for(.member(oclass(OClass,NOC),ObjectClasses)) {
		!get_name(OCP,OClass,OClassAgent);
		?oclass_path(OCAPath);
		.create_agent(OClassAgent,OCAPath);
		+oclass_agent(id(OClass),agent(OClassAgent));
		.send(OClassAgent,tell,[
				main(MyName),
				myclass(OClass),
				myclassCapacity(NOC)]);
		?object_classes(OClist);
		.concat([OClassAgent],OClist,NewOClist);
		-+object_classes(NewOClist);
	}
	
	!wait(finished_object_classes_round);
	
	+object_classes_created;

	-+person_classes([]);
	?person_prefix(PCP);
	?epsilon_factor(EpsFact);
	
	.abolish(pclass_agent(_,_));
	for(.member(pclass(PClass,NPC),PersonClasses)) {
		!get_name(PCP,PClass,PClassAgent);
		?pclass_path(PCAPath);
		.create_agent(PClassAgent,PCAPath);
		+pclass_agent(id(PClass),agent(PClassAgent));
		?person_classes(PClist);
		.concat([PClassAgent],PClist,NewPClist);
		-+person_classes(NewPClist);
		.findall(PClassCost,
			.member(pocost(PClass,_,PClassCost),POCosts) 
			,PClassCosts);
		if(.length(PClassCosts,PClassCostsNum) & PClassCostsNum < NOClasses) {
			.concat("Number of costs ",PClassCostsNum,
				" for person class ",PClass,
				" is less then number of object classes", NOClasses,
				CostMessage); 
			!stop(CostMessage);
		}
		.max(PClassCosts,MaxPClassCost);
		Eps = MaxPClassCost / EpsFact;
		.send(PClassAgent,tell,[
				main(MyName),
				nobject_classes(NOClasses),
				myclass(PClass),
				myclassCapacity(NPC),
				epsilon(Eps)]);
		-+pClassPersons([]);
		.term2string(PClassAgent,PClassPrefix);
		!wait(nobject_classes_got[source(PClassAgent)]);
		!wait(main_got[source(PClassAgent)]);
		for(.member(oclass(OClass,NOC),ObjectClasses)) {
			.member(pocost(PClass,OClass,Cost),POCosts);	// determining cost 
			Util = MaxPClassCost - Cost + 1;
			.send(PClassAgent,tell,
						[cost(OClass,Cost)	// PClass Agent has to know the price 
						,util(OClass,Util)]);
		}
	
	} 
	+person_classes_created;
	
	!wait(finished_person_classes_round);

	?person_classes(PClasses);
	?object_classes(OClasses);
	
	for(.member(oclass(OClass,_),ObjectClasses)) {
		?allowed_persons(object(OClass),persons(Allowed_persons));
		.length(Allowed_persons,NAllowedPC);
		?oclass_agent(id(OClass),agent(OClassAgent));
		.send(OClassAgent,tell,	nperson_classes(NAllowedPC));
		.findall(PClassAgent,
			.member(PClass,Allowed_persons) &
			pclass_agent(id(PClass),agent(PClassAgent)),
			ThisObjectPersonClasses);
		.send(OClassAgent,achieve,set_person_classes(ThisObjectPersonClasses));
	}
	
	!wait(finished_object_classes_round);
		
	+inwork;
	!send(PClasses,achieve,start);
.

+!get_name(Prefix,I,Name) <-
		.concat(Prefix,I,NameStr);
		.term2string(Name,NameStr);
.

@ljnbdgfd[atomic]
+!addweight(Share)[source(Source)] //: Share \== 0 
<-
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
		?nperson_classes(Dim);
		Share = Weight / (N+Dim);
		.send(Recip,achieve,addweight(Share));	// share the weight with recipients
		!addweight(-N*Share);
.


@eswneasafs90[atomic]
+?share_weight(Share) <- 
		?weight(Weight);
		?nperson_classes(Dim);
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
	-finished;
	if(debug) {
		?step(Step);
		+finished(Step);
	}
	?object_classes(ObjectClasses);
	//.send(ObjectClasses,achieve,output);
	-finished_person_classes;
	?person_classes(PersonClasses);
	.send(PersonClasses,askOne,results(_));
.

@sfdjn234vru[atomic]
+person_class_end[_] : 
		.count(person_class_end[_],N) & nperson_classes(N)
		<-
		.abolish(person_class_end);
		+finished_person_classes_round;  
.


@sfdjnvqeru[atomic]
+object_class_end[_] : 
		.count(object_class_end[_],N) & nobject_classes(N)
	<-
	.abolish(object_class_end);
	+finished_object_classes_round;  
.


@rnveot[atomic]
+results(_)[_] 
	: .count(results(_)[_],N) & nperson_classes(N)
	<-
	.findall(U,results(tuple(_,totals(U,_,_)))[_],Utils);
	.findall(C,results(tuple(_,totals(_,C,_)))[_],Costs);
	.findall(Step,results(tuple(_,totals(_,_,Step)))[_],Steps);

	-+totUtil(math.sum(Utils));
	-+totCost(math.sum(Costs));
	-+totSteps(math.sum(Steps));
	?parent(Parent);
	?totUtil(TotU);
	?totCost(TotC);
	?totSteps(TotS);
	.send(Parent,tell,totals(util(TotU),cost(TotC),steps(TotS)));

	?step(Step);
	+finished_person_classes_output(Step);
.

//control passed by this belief to get out from atomic flow here
+finished_person_classes_output(Step) <- 
	.print(run_no(Step));
	!finish;
.

+!finish <-
	if(not nokill) {
		!kill_object_classes; 
		!kill_person_classes;
	}
	!calculate_streams(Streams);
	!clear_all_data;
	
	?parent(Parent);
	.send(Parent,tell,transportation_streams(Streams));
		// sending this message means that all activity 
		// is finished in this step
.


@adbfns4567bdmv[atomic]
+!kill_object_classes
 : object_classes_created <-
	?object_classes(ObjectClasses);
	for(.member(Agent,ObjectClasses)) {
		.kill_agent(Agent);
	}
	-object_classes_created;
.

+!kill_object_classes.

+!kill_person_classes
 : person_classes_created <-
 	?step(Step);
 	!wait(finished_person_classes_output(Step));
	?person_classes(PClasses);
	for(.member(Agent,PClasses)) {
		.kill_agent(Agent);
	}
	-person_classes_created;
.

+!kill_person_classes.


+!calculate_streams(Streams)
<-
	.findall(stream(source(Source),sink(Sink),quantity(Flow)),
		direction(reverse) 
			& results(tuple(flows(Flows,Sink),_))
			& .member(flow(Flow,Source),Flows)
		
		|
		direction(direct) 
			& results(tuple(flows(Flows,Source),_))
			& .member(flow(Flow,Sink),Flows)
		
		, Streams);

			
	if(debug) {
		?step(Step);
		+streams(step(Step),Streams);
	}

.


+!clear_all_data <-
	!check(debug | (
		(not object_classes_created) & (not person_classes_created)));		
			// check that cleanup is finished, before sending the result

	//.abolish(direction(_));
	.abolish(sink(_,_));
	.abolish(source(_,_));
	//.abolish(crosscost(_,_,_));
	.abolish(nsinks(_));
	.abolish(nsources(_));
	//.abolish(ncosts(_));
	.abolish(results(_)[_]);
	.abolish(allowed_sources(_,_));
.


+!check(A) : A.
+!check(A) <- .wait(10); !check(A).

+!print(A) : opdebug <- .print(A).
+!print(A).

+!wait(A) <- 
		!check(A);
		.abolish(A);
.

