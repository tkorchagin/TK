depot_name_str("src/asl/uth_ss_team/uth_ss_team_depot.asl").
planning_horisont(24).
start_plan_hour(18).

+current_id(_,_)
<-
	!start;
.

+planning_horisont(PlanHorNew)
<-
	-+planning_horisont(PlanHorNew);
.

+start_plan_hour(StartPlanHourNew)
<-
	-+start_plan_hour(StartPlanHourNew);
.

+!start
<-
	+start_time(system.time);
	.print("depot started");
	
	!send_data_to_depots;
.	


+!prepare_norms
<-
	for(direction_norm(direction(DirID),depot(DepID),first_shift(SH1),second_shift(SH2))){
		.print(direction_norm(direction(DirID),depot(DepID),first_shift(SH1),second_shift(SH2)));
		-+rest1(SH1);
		-+rest2(SH2);
		-+parts_arr([]);
		for(.member(N, [1,2,3])){
			PNorm1 = math.floor(SH1/4);
			PNorm2 = math.floor(SH2/4);
			//.print(PNorm2);
			
			?parts_arr(OldArr);
			.concat([[N, PNorm1],[N+4, PNorm2]], OldArr, NewArr);
			-+parts_arr(NewArr);
			
			?rest1(OldRest1);
			?rest2(OldRest2);
			
			-+rest1(OldRest1 - PNorm1);
			-+rest1(OldRest2 - PNorm2);
		}
		?rest1(Rest1);
		?rest2(Rest2);
		
		?parts_arr(OldArr);
		.concat([[4, Rest1],[8, Rest2]], OldArr, NewArr);
		
		+part_direction_norm(direction(DirID),depot(DepID), part_norms(NewArr));
	}
.


+!send_data_to_depots
<-
	!prepare_norms;
	
	.my_name(MyName);
	.print(send_data_to_depots);
	.findall(DepID,
		part_direction_norm(direction(_),depot(DepID), part_norms(_)),
			DepotsArr);
			
	for(.member(DepotID, DepotsArr)){
		!get_dep_name(DepotID, DepName);
		?depot_name_str(DepotNameStr);
		!create_agent(DepName, DepotNameStr, Flag);
		?planning_horisont(PlanningHorisont);
		if (Flag = true){
			//.print(DepotID);
			.send(DepName,tell,depotID(DepotID));
			.send(DepName,tell,parent(MyName));
			.send(DepName,tell,planning_horisont(PlanningHorisont));
			//.print(send(DepName,tell,parent(MyName)));
			?start_plan_hour(DC);
			.send(DepName,tell,start_plan_hour(DC));
	
			.findall(part_direction_norm(direction(D), depot(DepotID), part_norms(PARR)), 
					part_direction_norm(direction(D), depot(DepotID), part_norms(PARR)), PartDirectionDorms);
			.send(DepName,tell,PartDirectionDorms);
			//.print(send(DepName,tell,PartDirectionDorms));
			
			.findall(team(id(TID),depot(DepotID),MODE,STATE),
					team(id(TID),depot(DepotID),MODE,STATE), TeamsModeStateArr);
			.send(DepName,tell,TeamsModeStateArr);
			//.print(send(DepName,tell,TeamsModeStateArr));
			
			.findall(DirID, part_direction_norm(direction(DirID),depot(DepotID), _), DirectinsArr);
			
			for(.member(DirectionID, DirectinsArr)){
				//.print(DirectionID);
				.findall(team_allowed(team(T),direction(DirectionID)),
						team_allowed(team(T),direction(DirectionID)), AllowedTeamsArr);
				.findall(buffer(direction(DirectionID),time(TIME)),
						buffer(direction(DirectionID),time(TIME)), Buffers);
				
				.send(DepName,tell,AllowedTeamsArr);
				//.print(send(DepName,tell,AllowedTeamsArr));
				
				.send(DepName,tell,Buffers);
				//.print(send(DepName,tell,Buffers));
			}
			.send(DepName,achieve,start);
			//.print(send(DepName,achieve,start));
		}
	}
.

+!create_agent(Name,Path,Flag)
<-
	.all_names(AllNames);
	if(not .member(Name,AllNames)) {
		.create_agent(Name,Path);
		Flag = true;
	} else {
		Flag = false;
	}	
.


+!get_dep_name(DepotID, DepName)
<-
	.concat("dep", DepotID, DepIDSTR);
	.term2string(DepName, DepIDSTR);
.


+to_work_data([DepID, ToWorkArr])
<-
	//.print(ToWorkArr);
	for(.member(to_work(id(Source), direction(DirID), work_from(WorkFrom), call_type(CFlag)),
			ToWorkArr)){
		.puts("dep_#{DepID}; to_work(id(#{Source}), direction(#{DirID}), work_from(#{WorkFrom}), call_type(#{CFlag}))");
	}
.
