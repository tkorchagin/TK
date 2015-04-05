
+endOfFile
<-
	!start;
.

+!start <-
	+start_time(system.time);
	.print("main started");
	
	!send_data_to_depots;
.	


+!send_data_to_depots
<-
	.my_name(MyName);
	.print(send_data_to_depots);
	.findall(DepotID,
		part_direction_norm(direction(DirID),depot(_), part_norms(_)),
			DepotsArr);
			
	for(.member(DepotID, DepotsArr)){
		!get_dep_name(DepotID, DepName);
		.create_agent(DepName, "./uth_ss_team_depot.asl");
		.send(DepName,tell,depotID(DepotID));
		.send(DepName,tell,parent(MyName));
		.print(send(DepName,tell,parent(MyName)));

		.findall(part_direction_norm(_, depot(DepotID), _), 
			part_direction_norm(_, depot(DepotID), _), PartDirectionDorms);
		.send(DepName,tell,PartDirectionDorms);
		.print(send(DepName,tell,PartDirectionDorms));
		
		.findall(DirID,
			part_direction_norm(direction(DirID),depot(DepotID), _),
				DirectinsArr);
		
		for(.member(DirectionID, DirectinsArr)){
			.findall(team_allowed(team(_),direction(DirectionID)),
				team_allowed(team(_),direction(DirectionID)), AllowedTeamsArr);
			.findall(buffer(direction(DirectionID),time(_)),
				buffer(direction(DirectionID),time(_)), Buffers);
			
			.send(DepName,tell,AllowedTeamsArr);
			.print(send(DepName,tell,AllowedTeamsArr));
			
			.send(DepName,tell,Buffers);
			.print(send(DepName,tell,Buffers));
		}
		
		.send(DepName,achieve,start);
		.print(send(DepName,achieve,start));
	}
.


+!get_dep_name(DepotID, DepName)
<-
	.concat("dep", DepotID, DepIDSTR);
	.term2string(DepName, DepIDSTR);
.


+to_work_data([DepID, ToWorkArr])
<-
	for(.member(to_work(id(Source), direction(DirID), work_from(WorkFrom), call_type(CFlag)),
			ToWorkArr)){
		.puts("dep_#{DepID}; to_work(id(#{Source}), direction(#{DirID}), work_from(#{WorkFrom}), call_type(#{CFlag}))");
	}
.
