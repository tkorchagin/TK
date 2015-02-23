//no_cleanup.

//debug_input.

//debug_output.

solver_path("uth_ss_team/auction_solver.asl").

min_rest(16).

debug_time(time(20,03,0)).
debug_date(date(2015,1,9)).

direction_prefix("uth_ss_team_z_direction_").
direction_path("./uth_ss_team/uth_ss_team_direction.asl").
part_path("./uth_ss_team/uth_ss_team_part.asl").

depot_prefix("uth_ss_team_z_depot_").
depot_path("./uth_ss_team/uth_ss_team_depot.asl").

team_prefix("uth_ss_team_z_team_").
team_path("./uth_ss_team/uth_ss_team_team.asl").

stations([]).

+current_id(CurrentTime, N) <-
	!execute;
.

+!execute
<-
	?current_id(ExtId, ExtN); 
	?time(time(HH,MM,StS));
	.print("Model time (HH : MM : SS) : ",HH," : ",MM," : ",StS,".");
	.my_name(Name);
	-+name(Name);
	-+main(Name);
	.time(FH,FM,FS);
	+start_time(FH,FM,FS);
	
	!round(HH + MM/60,TimeHrs);
	!hours_to_end(TimeHrs,HtE);
	+hours_to_end(HtE);
	
	tell(plan_begin, id(ExtId, ExtN));
	tell(version(Version));
		.print("Start processing data...");
	!process_data;
	.print("Finished processing");

	.print("Start Solving...");
	!solve_problem;
	.print("Finished Solving!");	
.


+!round(A,Ar) <- Ar = math.round(A * 1000.00) * 0.001.


+!hours_to_end(Hrs,New_Hours)
<-	
	?start_plan_hour(DC);
	
	if (Hrs > DC){
		New_Hours = 3 - ((Hrs - DC) mod 3);
	} else {
		New_Hours = (DC - Hrs) mod 3;
	}
.


+?time(Time) : debug_input & debug_time(Time).
+?time(time(SH,SM,SS)): excel_mode <- .time(SH,SM,SS).
+?time(time(SH,SM,SS)) <- ?time(SH,SM,SS).


+!process_data <- 
	?time(Time);
	?name(Name);
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
			.concat(DirID, "_", PartNumber, PartID);
			.print(PartID);
			+part(id(PartID), need(PartNorm));
		}
	}
	
	.findall(TeamID, 
		team(id(TeamID), _, Mode, State) &
			team_allowed(team(TeamID),direction(DirID)) &
				part_direction_norm(direction(DirID), _, _), TeamList);
	for (.member(TeamID,TeamList)){
		?team(id(TeamID), _, Mode, State);
		.print("TeamID:", TeamID);
		+team(id(TeamID));
		
		for(.member(part(DirID,PartNorms),PartInfoList)){
			for(.member([PartNumber, PartNorm], PartNorms)){
				.concat(DirID, "_", PartNumber, PartID);
				!count_cost(
					PartNumber,
					Mode,
					State,
					TeamCost
				);
				+team_part_cost(team(TeamID),part(PartID),cost(TeamCost));
			}
		}
		
	}
.

+!solve_problem <-
	.print(solve_problem);
	//.wait(100000);
	
	.my_name(MyName);
	?solver_path(SolverPath);
	.create_agent(tp,SolverPath);
	.findall(team(id(Id)),
			team(id(Id)),Sources);
	.findall(part(id(Id),need(Cap)),
			part(id(Id),need(Cap)),Sinks);
	.findall(team_part_cost(team(Id1),part(Id2),cost(Cost)),
			team_part_cost(team(Id1),part(Id2),cost(Cost)),	
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
	.send(tp,tell,Costs);
	.send(tp,tell,epsilon_factor(100));
	.send(tp,achieve,start);
.	

+totals(util(TotU),cost(TotC),steps(TotS)) 
	<-
	.print("Total utility: ",TotU);
	.print("Total cost: ",TotC);
	.print("Total steps: ",TotS);
.


+!count_cost(PartNumber, Mode, State, TeamCost)
<-
	//.print("count_cost");
	//.print(Mode);
	//.print(State);
	TeamCost = 42*PartNumber;
.


+!finish <-
	?start_time(SH,SM,SS);
	?current_id(ExtId, ExtN); 
	tell(plan_end, id(ExtId, ExtN));
	.print("Done");

	.time(FH,FM,FS);
	!get_time_diff(FH-SH,FM-SM,FS-SS,OH,OM,OS);
	.print("Calculation time: ",OH," hours, ",OM," minutes, ",OS," seconds.");
.


+!stop <-
	tell(plan_end, id(ExtId, ExtN));
	.print("Done");
	+finished
.


+!get_time_diff(DH,DM,DS,DH,DM,DS): DS >= 0 & DM >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH,DM-1,60+DS): DM >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH-1,60+DM,DS): DS >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH-1,60+DM-1,60+DS) <- true.


@debug_print1
+!print(A) : debug_output 
		<-	.print(A).

@debug_print2 		
+!print(_) : not debug_output.


@pcheck1
+!check(A) : A <- 
		A =.. [Predicate|Tail];
		.abolish(check_counter(Predicate,_));
.
		
@pcheck2
+!check(A) : not A <-
	A =.. [Predicate|Tail];
	if(check_counter(Predicate,CC)) {
		if(CC < 500) {
			.wait(30);
			-check_counter(Predicate,CC);
			+check_counter(Predicate,CC+1);
			
		} else {
			.print("Check of ",Predicate," takes too long. Will STOP in 10 sec!");
			.wait(10000);
			?main(Main);
			.send(Main,achieve,stop);
		}
	} else {
		+check_counter(Predicate,0);
	};
	!check(A);
.	

+!tell(A) <-
			.print(tell(A));
			tell(A);
.

+parts(Parts)
<-
	!finish;
	for(.member(part(id(PartID),TeamsList), Parts)) {
		.puts("To part #{PartID} assign teams: #{TeamsList}.");
	}
.
