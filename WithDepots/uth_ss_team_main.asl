
+endOfFile
<-
	!start;
.

+!start <-
	+start_time(system.time);
	.print("depot started");
	
	!send_data_to_depots;
.	

+!send_data_to_depots
<-
	.my_name(MyName);
	.print(send_data_to_depots);
	.findall(DepID,
		part_direction_norm(direction(_),depot(DepID), part_norms(_)),
			DepotsArr);
			
	for(.member(DepotID, DepotsArr)){
		!get_dep_name(DepotID, DepName);
		!create_agent(DepName,"./uth_ss_team_depot.asl", Flag);

		if (Flag = true){
			//.print(DepotID);
			.send(DepName,tell,depotID(DepotID));
			.send(DepName,tell,parent(MyName));
			
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
