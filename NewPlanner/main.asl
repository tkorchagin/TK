infinity(1000000000).

const_direction(1000).
const_fact(10).
const_add(100).

min_rest(16).


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
	
	
	
	/*
	.print("started: .findall(team_allowed(_,_), ...)");
	.findall([A11,B11], team_allowed(team(A11),direction(B11)), AllowedTeams);
	.print("ended: .findall(team_allowed(_,_), ...)");
	
	.length(AllowedTeams, N);
	
	.print(AllowedTeams);
	
	
	.wait(100000000);
	*/
	.findall([DirID,DepId],
		part_direction_norm(direction(DirID), depot(DepID),_),DirDepsArr);
	
	.print(DirDepsArr);
		
	for (.member([DirID, DepID], DirDepsArr)){
		?part_direction_norm(direction(DirID),depot(DepID),part_norms(PartList));
		for (team(id(TeamID), depot(DepID), _, _)){
			.print(id(TeamID));
			if (team_allowed(team(TeamID), direction(DirID))) {
				for(.member([PartNumber, PartNorm], PartList)){
					if(allowed_sources(sink(PartID),sources(SourceList))){
						.concat(SourceList, [TeamID], NewSourceList);
						-+allowed_sources(sink(PartID),sources(NewSourceList));
					} else {
						+allowed_sources(sink(PartID),sources([TeamID]));
					}
				}
			}
		}
	}
	
	/*
	for(.member(team_allowed(team(TeamID), direction(DirID)), AllowedTeams)){
		?part_direction_norm(direction(DirID), _, part_norms(PartList));
		.print(direction(DirID), part_norms(PartList));
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
	*/
	
	!set_max_buff;
	
	for (.member(TeamID,TeamList)){
		?team(id(TeamID), _, Mode, State);
		-+source(id(TeamID),exceed(1));
		//.print(source(id(TeamID),exceed(1)));
		!count_cost_by_direction(TeamID, CostTeamDir);
		for(.member(part(DirID,PartNorms),PartInfoList)){
			for(.member([PartNumber, PartNorm], PartNorms)){
				if(PartNorm > 0){
					!get_p_name(DirID, PartNumber, PartID);
					!count_cost_partN(PartNumber, Mode, State, CostTeamPart);
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

+!count_cost_partN(PartNumber, Mode, State, CostTeamPart)
<-
	if (State = state(work_nights(NightsWorked1), _)) {
		NightsWorked = NightsWorked1;
	} else {
		if (State = state(_, work_nights(NightsWorked1), _)){
			NightsWorked = NightsWorked1;
		} else {
			NightsWorked = 0;
		}
	}

	if (Mode = work(will_work(MoreWorkHours), will_rest(RestHours))){
		//.print(work, MoreWorkHours);
		!calc_fact_add_work(MoreWorkHours, RestHours, NightsWorked,
			FactHours, AddHours);
		//.print(calc_fact_add_work(MoreWorkHours, RestHours, NightsWorked, FactHours, AddHours));
	} else {
		if (Mode = rest(past_rest(PastRestHours), will_rest(MoreRestHours), _)){
			//.print(rest, MoreRestHours);
			!calc_fact_add_rest(PastRestHours, MoreRestHours, NightsWorked,
				FactHours, AddHours);
			//.print(calc_fact_add_rest(PastRestHours, MoreRestHours, NightsWorked, FactHours, AddHours));
		} else {
			if (Mode = vacation(will_start(TimeStart))){
				//.print(vacant);
				!calc_fact_add_vacation(TimeStart, FactHours);
				//.print(calc_fact_add_vacation(TimeStart, FactHours));
			}
		}
	}
	
	?infinity(Inf);
	if (.ground(FactHours)) {
		FactStartTime = 24 - FactHours;
	} else {
		FactStartTime = Inf;
	}
	
	if (.ground(AddHours)) {
		AddStartTime = 24 - AddHours;
	} else {
		AddStartTime = Inf;
	}
	
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


+!set_max_buff
<-
	.findall(Time, buffer(_,time(Time)), TimeArr);
	.max(TimeArr, BufTime);
	-+max_buffer(BufTime);
.

+!calc_fact_add_work(WorkHours, RestHours1, NightsWorked, FactHours, AddHours)
<-
	// work
	// work(will_work(WorkHours)
	// will_rest(RestHours1)

	?min_rest(MinRestHours1);
	?max_buffer(BufTime);
	RestHours = RestHours1 + BufTime;
	MinRestHours = MinRestHours1 + BufTime; 
	
	?start_plan_hour(StartPlanHour);
	StartNight = 24 - StartPlanHour;
	EndNight = (StartNight + 5) mod 24;
	
	?start_time(StartTime);
	!hours_to_end(StartTime, PrevHours);
	
	//FACT
	FreeHours = 24 + PrevHours - WorkHours;  // NB - can be > 24!
	!trunc_hour(24 + PrevHours - WorkHours - RestHours,FactHours);
	
	// ADD
	if (NightsWorked == 2) {
		!get_nonight_hours(FreeHours - MinRestHours,AddHours,AddStart);
	} else {
		!trunc_hour(FreeHours - MinRestHours,AddHours);
	};
.


+!calc_fact_add_rest(PastRestHours, MoreRestHours1, NightsWorked, FactHours, AddHours)
<-
	// past_rest(PastRestHours)
	// will_rest(MoreRestHours1)

	?min_rest(MinRestHours1);
	?max_buffer(BufTime);
	MoreRestHours = MoreRestHours1 + BufTime;
	MinRestHours = MinRestHours1 + BufTime; 
	
	?start_plan_hour(StartPlanHour);
	StartNight = 24 - StartPlanHour;
	EndNight = (StartNight + 5) mod 24;
	
	?start_time(StartTime);
	!hours_to_end(StartTime, PrevHours);

	//FACT
	!trunc_hour(24 + PrevHours - MoreRestHours,FactHours);
	
	// ADD
	MinMoreRestHours = math.max(0,MinRestHours - PastRestHours);
	if (NightsWorked == 2) {
		!get_nonight_hours(24 - MinMoreRestHours,AddHours,AddStart);
	} else {
		AddHours = 24 - MinMoreRestHours;
	};
.


+!calc_fact_add_vacation(TimeStart1, FactHours)
<-
	// vacation(will_start(TimeStart1))

	?max_buffer(BufTime);
	TimeStart = TimeStart1 + BufTime;
	!trunc_hour(24 - TimeStart,FactHours);
.


+!hours_to_end(Hrs,New_Hours)
<-	
	?start_plan_hour(DC);
	
	if (Hrs > DC){
		New_Hours = 3 - ((Hrs - DC) mod 3);
	} else {
		New_Hours = (DC - Hrs) mod 3;
	}
.

+!get_nonight_hours(AH,0,0) : AH <= 0.

+!get_nonight_hours(AvHours,AvHours,24 - AvHours) // planned start recently after night
	: night_interval(_,NE) & (24 - AvHours) < (NE + 4). 
		
+!get_nonight_hours(AvHours,24 - NE, NE) // planned start shortly before night
	: night_interval(NS,NE) & (24 - AvHours) < NE & (24 - AvHours) > NS - 4.
				
+!get_nonight_hours(_,0,0).	

+!trunc_hour(Hours,24): Hours >= 24.			
+!trunc_hour(Hours,0): Hours <= 0.
+!trunc_hour(Hours,math.round(Hours*100) * 0.01): Hours > 0 & Hours < 24.


+!count_cost_by_direction(TeamID, CostTeamDir)
<-
	//.print(count_cost_by_direction, " ", TeamID);
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

