/////////////// main agent which start other agents and controls input-ouptput //////////////////////////

/*

// v. 1.0.0.2 update: time part distribution added

// v. 1.0.0.3 update: teams overtime is taken into account for by double-run of "depot.iterate" (meets interface v.8) 

// v. 1.0.0.4 update: empty depots not created 

// v. 1.0.0.5 update: min_rest = 16 always. Holidays are separated.

// v. 1.0.0.6 update: Fact and Additional Utility is differently calculated.

// v. 1.0.0.7 update: 	1) atomic bug in team_team::!position(_,_) plan is fixed.
//						2) output reserve(utility) bug fixed 
//						3) atomic bug in team_team::set_free is fixed
//						4) team_part::?is_vacant is made askOne instead of achieve

// v. 1.0.0.8 update: 	1) team_team::!check_response(_,false) plan is made atomic 
//						2) buffer time from team get to work to loco-start is added into model 
//						
// v. 1.0.0.9 update: 	Optimization Algorithm is updated. 3-hours intervals are filled from 1 to 8.   
//						 
//						
// v. 1.0.0.10 update: 	Rest Ratio parameter is included into Team-Part Utility function   
//						 
//						 
// v. 1.0.0.11 update: 	Holidays priority is set lower then homerest's one   
//						 
//						 

// v. 1.0.0.12 update: 	Teams in work are set to plan depending on whether they have finished 
							current work or not

// v. 1.0.0.13 update: 	Fixed bug in team add hours = 0 when fact hours \==0
   
// v. 1.0.0.14 update: 	All teams are set to plan in the order they finished (will finish) 
							their (current) work

   v. 1.0.0.15 update: 	is_holiday() flag is   added for teams still in work 
   
   v. 1.0.0.16 update: 	Overtime status field is replaced by WorkPercentage status field for team
   
   v. 1.0.0.17 update: Foolproof for team_team::max_buffer is added
   v. 1.0.0.18 update: Foolproof for no teams is added
   v. 1.0.0.19 update: Foolproof for no direction_norm is added
   v. 1.0.0.20 update: team::team::maxcycle belief is made a rule
   v. 1.0.0.21 update: output to_work includes drive_from & work_from fields
   v. 1.0.0.22 update: output to_work includes new field: range in the sorted list (due to interface spec v.15)

   v. 1.0.0.23 update: avg_rest_ratio calculation in team::depot::output_plans  is made foolproof 

   v. 1.0.0.24 update: rank calculation has changed  
   
   v. 1.0.0.25 update: 
   						1) priority is now dependent on whether team has returned home or not
						
						2)	v24 update is corrected 
   
   						3) v23 update is corrected
						
//						 

*/

version("Team SS planner version 1.0.0.25").

//no_cleanup.                           

//debug_input.

//debug_output.

min_rest(16).

debug_time(time(15,03,0)).
debug_date(date(2013,12,9)).

direction_prefix("uth_ss_team_z_direction_").
direction_path("src/asl/uth_ss_team/uth_ss_team_direction.asl").

part_path("src/asl/uth_ss_team/uth_ss_team_part.asl").

depot_prefix("uth_ss_team_z_depot_").
depot_path("src/asl/uth_ss_team/uth_ss_team_depot.asl").

team_prefix("uth_ss_team_z_team_").
team_path("src/asl/uth_ss_team/uth_ss_team_team.asl").


stations([]).


+current_id(CurrentTime, N) <- +start.

////////////////////////////////////////// TIME & DATE REQUEST ////////////////////////////// 	


+?time(Time) : debug_input & debug_time(Time).
+?time(time(SH,SM,SS)): excel_mode <- .time(SH,SM,SS).
+?time(time(SH,SM,SS)) <- ?time(SH,SM,SS).



+!finish <-
				?start_time(SH,SM,SS);
				?current_id(ExtId, ExtN); 
				tell(plan_end, id(ExtId, ExtN));
				.print("Done");

				.time(FH,FM,FS);
				!get_time_diff(FH-SH,FM-SM,FS-SS,OH,OM,OS);
				.print("Calculation time: ",OH," hours, ",OM," minutes, ",OS," seconds.").

				
+start <- !execute. 
+!execute				<-
				?current_id(ExtId, ExtN); 
				?time(time(HH,MM,StS));
				?version(Version);
				.print(Version);
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

				.print("Norms:");
				?depots(DepotNames);
				if(DepotNames \== []) {
					.send(DepotNames,achieve,print_norms);
	
					.print("Start planning...");
					!run;
					.print("Finished planning.");
					.print("Facts after planning:");
					
					.send(DepotNames,achieve,output);				
					!check(depots_output_finished);
					
					.wait(100);
				} else {
					.print("Error - no direction norms or depots are defined");
				}

				!finish.

				
//-!execute <-	.print("Abnormal termination. STOP.");
	//			!stop.


+!stop <- 		tell(plan_end, id(ExtId, ExtN));
				.print("Done");
				+finished.
				
				
 		
				
+!hours_to_end(Hrs,18-Hrs) : Hrs < 18.
+!hours_to_end(Hrs,24-Hrs+18) : Hrs >= 18.

				


/////////////////////////////////////    Pre-process     ///////////////////////////////


+!name_from_id(Id,Prefix,Name) 
			<-
			.term2string(Id,IdSt);
			.concat(Prefix,IdSt,NameSt);
			.term2string(Name,NameSt);
.			

@get_part_name
+!get_part_name(DirName,I,PartName)	<-
		.term2string(I,Ist);
		.term2string(DirName,DirNameSt);
		.concat(DirNameSt, "_",Ist, PartNameSt);
		.term2string(PartName,PartNameSt);
.

+!process_data <- 
				
		/// depot agents creation and data transfer
		
		?time(Time);
		?name(Name);
		
		.plan_label(PlanCheck1,pcheck1);
		.plan_label(PlanCheck2,pcheck2);
		.plan_label(GetPartName,get_part_name);
		.plan_label(Print1,debug_print1);
		.plan_label(Print2,debug_print2);
		
		.findall(DepId,depot(id(DepId),_) &
			direction_norm(_,depot(DepId),
						_,_),DepotsList1);
		.union(DepotsList1,[],DepotsList);
		.length(DepotsList,Ndepots);
		-+ndepots(Ndepots);
						
		?depot_prefix(DPref);
		?depot_path(DepPath);
		?direction_prefix(DirPref);
		?direction_path(DirPath);
		?part_path(PartPath);
		?team_prefix(TeamPref);
		?team_path(TeamPath);

		-+depots([]);
		for(.member(DepId,DepotsList)) {
		
			!name_from_id(DepId,DPref,DepName);
			.create_agent(DepName,DepPath);
			
			.send(DepName,tell,time(Time));
			?depot(id(DepId),night_start(NST));
			
			.send(DepName,tell,[id(DepId),
								night_start(NST),
								main(Name)]);
			
			.send(DepName,tellHow,[
				PlanCheck1,PlanCheck2,
				Print1,Print2]);
			
			.send(DepName,achieve,init);

			?depots(Depots);
			+depot_name(id(DepId),name(DepName));
			-+depots([DepName|Depots]);
			
			/// direction agents creation and data transfer  
			
			.findall(DirId,
				direction_norm(direction(DirId),depot(DepId),
						first_shift(FNorm),second_shift(SNorm)),DirList);

			-directions(depot(DepId),_);
			+directions(depot(DepId),[]);
			for(.member(DirId,DirList)) {
				
				!name_from_id(DirId,DirPref,DirName);
				+dirname(id(DirId),name(DirName));
				.create_agent(DirName,DirPath);
				
				?direction_norm(direction(DirId),depot(DepId),
						first_shift(FNorm),second_shift(SNorm));
				?buffer(direction(DirId), time(BufTime));
						

				//.findall(TeamId,team_allowed(team(TeamId),direction(DirId)),
				//			TeamList);
						
				.send(DirName,tell,[id(DirId),
									norm(shift(1),FNorm),
									norm(shift(2),SNorm),
									depot(DepId),
									depot_name(DepName),
									main(Name),
									buffer(DirId,BufTime)
									]);

				
				.send(DirName,tellHow,
						[PlanCheck1,PlanCheck2,GetPartName,
						Print1,Print2]);

				.send(DirName,achieve,init);
				
				!check(dir_data_ready(DirName));
				.print(dir_data_ready(DirName));
				.abolish(dir_data_ready(DirName));

				?directions(depot(DepId),Directions);
				-directions(depot(DepId),Directions);
				+directions(depot(DepId),[DirName|Directions]);

				-parts(depot(DepId),direction(DirId),_);
				+parts(depot(DepId),direction(DirId),[]);
				-parts_by_shift(depot(DepId),   
						direction(DirId),shift(1),_);
				+parts_by_shift(depot(DepId),
						direction(DirId),shift(1),[]);
				-parts_by_shift(depot(DepId),
						direction(DirId),shift(2),_);
				+parts_by_shift(depot(DepId),
						direction(DirId),shift(2),[]);
				for(.member(I,[1,2,3,4,5,6,7,8])) {
					!get_part_name(DirName,I,PartName);
					.create_agent(PartName,PartPath);

					.count(team_planned(id(_), 
							direction(DirId), part(I)), Nplans);
							
					.send(PartName,tell,[
							no(I),
							main(Name),
							direction_name(DirName),
							depot_name(DepName),
							nplans(Nplans)
							]);
									
					.send(PartName,tellHow,[PlanCheck1,PlanCheck2,
							Print1,Print2]);

					.send(PartName,achieve,init);
					
					!check(init_done(I,DirName));
					.abolish(init_done(I,DirName));
					
					?parts(depot(DepId),direction(DirId),Parts);
					-parts(depot(DepId),direction(DirId),Parts);
					+parts(depot(DepId),direction(DirId),[PartName|Parts]);
					
					ShiftNo = math.floor((I-1)/4)+1;
					?parts_by_shift(depot(DepId),direction(DirId),
							shift(ShiftNo), PartsByShift);
					-parts_by_shift(depot(DepId),direction(DirId),
							shift(ShiftNo), PartsByShift);
					+parts_by_shift(depot(DepId),direction(DirId),
							shift(ShiftNo), [PartName|PartsByShift]);

					};
				?parts(depot(DepId),direction(DirId),Parts);
				-parts(depot(DepId),direction(DirId),Parts);
				?parts_by_shift(depot(DepId), direction(DirId),
												shift(1),PartsShift1);
				-parts_by_shift(depot(DepId), direction(DirId),
												shift(1),PartsShift1);
				?parts_by_shift(depot(DepId), direction(DirId),
												shift(2),PartsShift2);
				-parts_by_shift(depot(DepId), direction(DirId),
												shift(2),PartsShift2);
				
				.send(DirName,tell,[
							parts(Parts),
							parts_shift1(PartsShift1),
							parts_shift2(PartsShift2)
							]);
					
			};
			
			?directions(depot(DepId),Directions);
			.length(Directions,Ndirections);
			.send(DepName,tell,directions(Directions));
			.send(DepName,tell,ndirections(Ndirections));
			.abolish(direction_norm(_,depot(DepId),_,_));
			
			
			/// team agents creation and data transfer
			/// direction agents creation and data transfer  
			
			.findall(TeamId, team(id(TeamId), depot(DepId), Mode, State),
					TeamList);

			-teams(depot(DepId),_);
			+teams(depot(DepId),[]);
			for(.member(TeamId,TeamList)) {
	
				!name_from_id(TeamId,TeamPref,TeamName);
				.create_agent(TeamName,TeamPath);
				
				?team(id(TeamId), depot(DepId), Mode, State);
				
	
				.findall(DirName,team_allowed(team(TeamId),direction(DirId)) 
						& dirname(id(DirId),name(DirName)),
								DirList1);
								
				.length(DirList1,Ndirections1);

				.send(TeamName,tell,[id(TeamId),
									depot(DepId),
									Mode,
									State,
									depot_name(DepName),
									main(Name),
									direction_names(DirList1),
									ndirections(Ndirections1)
									]);

				if(team_planned(id(TeamId), direction(DirPlan), part(PartPlan))) {
					?dirname(id(DirPlan),name(DirPlanName));
					!get_part_name(DirPlanName,PartPlan,PartPlanName);
					.send(TeamName,tell,planned(part_name(PartPlanName)));
				};

				.send(TeamName,tellHow,[PlanCheck1,PlanCheck2,
						Print1,Print2]);

				.send(TeamName,achieve,init);
				!check(team_started(Id));

				.abolish(team_started(TeamId));
				!print(["Team ",TeamId,"started"]);
				
				?teams(depot(DepId),Teams);
				-teams(depot(DepId),Teams);
				+teams(depot(DepId),[TeamName|Teams]);
			};
			
			?teams(depot(DepId),Teams);
			.length(Teams,Nteams);
			.send(DepName,tell,teams(Teams));
			.send(DepName,tell,nteams(Nteams));
			.send(Teams,tell,nteams (Nteams));
			
			.abolish(team(_,depot(DepId),_,_));
			
			.abolish(dirname(_,_));
			
		};
		.abolish(depot(_,_));
.		

/////////////////////////////////////  MAIN //////////////////////////////////////////////


+!run <-
		?depots(DepList);
		.send(DepList,achieve,run);
		!check(depots_finished);
.

//@sdweg21s4[atomic]
+depot_output_finished(_) : .count(depot_output_finished(_),N) & ndepots(N)
			<-
			+depots_output_finished.

//@eweg2as1s4[atomic]
+depot_finished(_) : .count(depot_finished(_),N) & ndepots(N)
			<-
			+depots_finished.


///////////////////////////////////////// UTILITIES ///////////////////////////////////////				
				
+!get_time_diff(DH,DM,DS,DH,DM,DS): DS >= 0 & DM >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH,DM-1,60+DS): DM >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH-1,60+DM,DS): DS >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH-1,60+DM-1,60+DS) <- true.
		



+!sum_list([],0).
+!sum_list([Result|Tail], Result + SumTail) <- !sum_list(Tail,SumTail).  


+!round(A,Ar) <- Ar = math.round(A * 1000.00) * 0.001.


				
/////////////////////////////////////////////////////////////////////////////////////////

@debug_print1
+!print(A) : debug_output 
		<-	.print(A).

@debug_print2 		
+!print(_) : not debug_output.


////////////////////////////////////////////////////////////////////////////////////////

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

