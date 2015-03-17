infinity(1000000000).
const_part(10).
const_direction(1000).

const_fact(10).
const_add(100).

/*
source(id(t1),exceed(1)). 
source(id(t2),exceed(1)). 
source(id(t3),exceed(1)).
source(id(t4),exceed(1)).

sink(id(r1),need(1)).
sink(id(r2),need(1)).



allowed_sources(sink(r1),sources([t1,t3,t4])). 
allowed_sources(sink(r2),sources([t3,t4])).


crosscost(source(t1),sink(r1),cost(650)).
crosscost(source(t1),sink(r2),cost(2)).
crosscost(source(t2),sink(r1),cost(1)).
crosscost(source(t2),sink(r2),cost(10)).
crosscost(source(t3),sink(r1),cost(50)).
crosscost(source(t3),sink(r2),cost(30)).
crosscost(source(t4),sink(r1),cost(502)).
crosscost(source(t4),sink(r2),cost(1)).

*/




!start.


+!start <-
	.my_name(MyName);
	+start_time(system.time);
	
	!process_data;
	
	.create_agent(tp,"src/transportation.asl");
	.findall(source(id(Id),exceed(Cap)),
			source(id(Id),exceed(Cap)),Sources);
	.findall(sink(id(Id),need(Cap)),
			sink(id(Id),need(Cap)),Sinks);
	.findall(allowed_sources(A,B),
			allowed_sources(A,B),AllowedSources);
	.findall(crosscost(source(Id1),sink(Id2),cost(Cost)),
			crosscost(source(Id1),sink(Id2),cost(Cost)),	
			Costs);
	.length(Sources,Nsources);
	.length(Sinks,Nsinks);
	.length(Costs,Ncosts);
	.send(tp,tell,[nsources(Nsources),
		nsinks(Nsinks),
		ncosts(Ncosts),
		parent(MyName)]);
	.send(tp,tell,Sources);
	.send(tp,tell,Sinks);
	.send(tp,tell,AllowedSources);
	.send(tp,tell,Costs);
	.send(tp,tell,epsilon_factor(100));
	.send(tp,achieve,start);
.	


+!process_data <- 
	/*
		+part_direction_norm(
			direction(2001939893),
			depot(2000036956),
			part_norms(
				[
					[1,2],[2,2],[3,2],[4,2],[5,0],[6,1],[7,2],[8,0]
				]
			)
		)
	
		+team(id(2002108559), depot(2000036518), Mode, State)
		+team_allowed(team(2002093013),direction(2001939893))
	*/
	
	.findall(part(DirID,PartNorms), 
		part_direction_norm(direction(DirID), 
			depot(_), part_norms(PartNorms)), PartInfoList);
	
	for(.member(part(DirID,PartNorms),PartInfoList)){
		for(.member([PartNumber, PartNorm], PartNorms)){
			if (PartNorm > 0){
				!get_p_name(DirID, PartNumber, PartID);
				+sink(id(PartID),need(PartNorm));
				//.print(sink(id(PartID),need(PartNorm)));
			}
		}
	}
	
	.print("findall started...");
	.findall(TeamID, part_direction_norm(direction(DirID), _, _)
		 & team_allowed(team(TeamID),direction(DirID)) 
		 & team(id(TeamID), _, Mode, State), TeamList);
	.print("findall finished");
	
	.findall(team_allowed(_,_), team_allowed(_,_), AllowedTeams);
	for(.member(team_allowed(team(TeamID), direction(DirID)), AllowedTeams)){
		?part_direction_norm(direction(DirID), _, part_norms(PartList));
		
		for(.member([PartNumber, PartNorm], PartList)){
			if(PartNorm > 0){
				!get_p_name(DirID, PartNumber, PartID);
				if(allowed_sources(sink(PartID),sources(SourceList))){
					.concat(SourceList, [TeamID], NewSourceList);
					-+allowed_sources(sink(PartID),sources(NewSourceList));
				} else {
					+allowed_sources(sink(PartID),sources([TeamID]));
				}
			}
		}
	}
	
	for (.member(TeamID,TeamList)){
		?team(id(TeamID), _, Mode, State);
		-+source(id(TeamID),exceed(1));
		//.print(source(id(TeamID),exceed(1)));
		!count_cost_by_direction(TeamID, CostTeamDir);
		for(.member(part(DirID,PartNorms),PartInfoList)){
			for(.member([PartNumber, PartNorm], PartNorms)){
				if(PartNorm > 0){
					!get_p_name(DirID, PartNumber, PartID);
					!count_cost_partN(PartNumber, Mode, CostTeamPart);
					+crosscost(source(TeamID), sink(PartID), 
						cost(CostTeamPart + CostTeamDir));
				}
			}
		}
	}
	
.

+!get_p_name(DirID, PartNumber, PartID)
<-
	.concat(dir, DirID, "_", PartNumber, PartIDSTR);
	.term2string(PartID, PartIDSTR);
.

+!count_cost_partN(PartNumber, Mode, CostTeamPart)
<-
	if (Mode = work(will_work(MoreWorkHours), will_rest(RestHours))){
		!count_work_cost(MoreWorkHours, PartNumber, RestHours, CostTeamPart);
		//.print(work, MoreWorkHours);
	} else {
		if (Mode = rest(past_rest(PastRestHours), will_rest(MoreRestHours), _)){
			!count_rest_cost(PartNumber, PastRestHours, MoreRestHours, CostTeamPart)
			//.print(rest, MoreRestHours);
		} else {
			//.print(vacant);
			?infinity(Inf);
			CostTeamPart = Inf;
		}
	}
.

+!count_work_cost(MoreWorkHours, PartNumber, RestHours, CostTeamPart)
<-
	//.print(count_work_cost(MoreWorkHours, RestHours, PartNumber));
	?infinity(Inf);
	
	if (RestHours > 16){
		AddStartTime = MoreWorkHours + 16;
	} else {
		AddStartTime = Inf;
	}
	FactStartTime = MoreWorkHours + RestHours;
	
	?start_time(StartTime);
	PartStartTime = PartNumber*3 + StartTime;
	
	if (PartStartTime > FactStartTime) {
		?const_fact(Const1);
		CostTeamPart = (8 - PartNumber + 1) * Const1;
	} else {
		if (PartStartTime > AddStartTime) {
			?const_add(Const2);
			CostTeamPart = (8 - PartNumber + 1) * Const2;
		} else {
			CostTeamPart = Inf;
		}
	}
.


+!count_rest_cost(PartNumber, PastRestHours, MoreRestHours, CostTeamPart)
<-
	//.print(count_work_cost(PastRestHours, MoreRestHours, PartNumber));
	?infinity(Inf);
	
	AddStartTime = PastRestHours + MoreRestHours;
	FactStartTime = AddStartTime + 16;
	
	?start_time(StartTime);
	PartStartTime = PartNumber*3 + StartTime;
	
	if (PartStartTime > FactStartTime) {
		?const_fact(Const1);
		CostTeamPart = (8 - PartNumber + 1) * Const1;
	} else {
		if (PartStartTime > AddStartTime) {
			?const_add(Const2);
			CostTeamPart = (8 - PartNumber + 1) * Const2;
		} else {
			CostTeamPart = Inf;
		}
	}
.


+!count_cost_by_direction(TeamID, CostTeamDir)
<-
	.print(count_cost_by_direction, " ", TeamID);
	.count(team_allowed(team(TeamID), _), N);
	?const_direction(Const2);
	CostTeamDir = N*Const2;
.


+totals(util(TotU),cost(TotC),steps(TotS)) 
	<-
	.print("Total utility: ",TotU);
	.print("Total cost: ",TotC);
	.print("Total steps: ",TotS);
.

+transportation_streams(Streams)
	<-
	for(.member(stream(source(Source),sink(Sink),quantity(Quantity)),
		Streams)) {
		.puts("Assign from source #{Source} to sink #{Sink} total of #{Quantity} resources");
	}
	?start_time(ST);
	.print("calculation time: ",(system.time-ST)/1000," s");
.

