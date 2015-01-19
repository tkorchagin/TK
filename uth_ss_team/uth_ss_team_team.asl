/////////////// team agent which tries to fill the vacant place in norms   //////////////////////////


/////////////////////////// initial data /////////////////////////////////////////////


cycles(0).

 

maxcycles(20*Nteams) :- nteams(Nteams).

 

///////////////////////////////////////// Process Teams ////////////////////////////////////


+!init <-
			.my_name(Name);
			-+name(Name);
			!check(main(Main));

			?id(Id);
			.send(Main,askOne,hours_to_end(_));
			.send(Main, askOne,debug_output);
			.send(Main, askOne,min_rest(_));
			
			?direction_names(DirList);
			.length(DirList,DirLen);
			-+ndirections(DirLen);
			if(DirLen == 0) {
				.puts("Team no #{Id} has no allowed directions. Will not be planned");
			} else {
				.send(DirList,askOne,buffer(_,_));
			}
			
			?depot_name(DepName);
				

			.send(DepName,askOne,night_interval(_,_));
			.send(DepName, askHow, "+!trunc_hour(_,_)");
			
			!print("team started");
			.send(Main,tell,team_started(Id));

.			

//@skdd12b2[atomic]
+buffer(_,_) : .count(buffer(_,_),N) & ndirections(N)
			<-
			.findall(BTime, buffer(_,BTime), TimeSet);
			.max(TimeSet, MaxBTime);
			+max_buffer(MaxBTime);
			+directions_complete.

			
+?max_buffer(0): ndirections(0).			

////////////////////////////////////////////////////////////////////////////////////////////////




+?night_interval(StartNight,EndNight) 
			<-
			!check(depot_name(DepName));
			.send(DepName,askOne,night_interval(_,_));
			!check(night_interval(StartNight,EndNight));
.		

			
////////////////////////////////////////////////////////////////////////////////////////////////



+!calc_team <-
			if (not ndirections(0))	{ 
				!check(directions_complete);
			};

			!calc_fact_add_rem;
			
			?fact(FactHours);
			?add(tuple(AddHours,AddStart));

			!decompose_to_parts(fact,FactHours); 
			!decompose_to_parts(add,AddHours);
			
			?ndirections(Ndirections);
			
			.findall(FactNo,hours(fact,FactNo,_),FactPartList);
			.findall(AddNo,hours(add,AddNo,_),AddPartList);

			.union(FactPartList,AddPartList,PartNoList);
			
			?direction_names(Directions);
			!clean_part_names_intervals;
			for(.member(PartNo,[1,2,3,4,5,6,7,8])) {
				if(.member(PartNo,PartNoList)) {
					.send(Directions,askOne, part_name(PartNo,PartName));
					if (not ndirections(0))	{
						!check(directions_answered(PartNo));
					};
				};
				.findall(PartName,part_name(PartNo,PartName),PartNamesByNo);
				!add_part_names_interval(PartNo,PartNamesByNo);

			};
			.abolish(directions_answered(_));
				
			.count(hours(fact,_,_),Nfact);
			.count(hours(add,_,_),Nadd);
			
			?work_end(WorkEndTime);
			?work_percentage(WorkPercentage);
			
			if(holiday) {
				CutPriority =  -3;
			} else {
				CutPriority = -2;
			};

			if(in_work) {
				+plusutil(fact,
					tuple(-1, 
						200 - WorkPercentage));
				
			} else {
				+plusutil(fact,tuple(
					 200 - WorkEndTime, 
						200 - WorkPercentage));
			}
			
			+plusutil(add,
				tuple(CutPriority, 200 - WorkPercentage));  
								
			?fact(FactHours);
			?add(tuple(AddHours,AddStart));

			if(	 (FactHours > 0) | (AddHours > 0))
			{
				+freehours;
			};
			
			?id(Id);
			?depot_name(DepName);
			.send(DepName,tell,team_ready(id(Id)));
.			


//@sfkbv74r4[atomic]
+part_name(PartNo,_) : 
		.count(part_name(PartNo,_),N) & ndirections(N)
		<-	
		+directions_answered(PartNo).


///////////////////////////////////////////////////////////////////////////////////


+!clean_part_names_intervals <-
				.abolish(part_names_interval(_,_,_));
.

+!add_part_names_interval(PartNo,PartNamesByNo) <-
				+part_names_interval(1,PartNo,PartNamesByNo);
				+part_names_interval(2,PartNo,PartNamesByNo);
.				


+?part_names_interval(PartList) : run(NR) & interval(I) 
				& part_names_interval(NR,I,PartList). 
			
					
//@pupdpni[atomic]	
+!update_part_names_interval(NewPartList) : interval(I) & run(NR)
			<-
				-part_names_interval(NR,I,_);
				+part_names_interval(NR,I,NewPartList);
.
			


///////////////////////////// CALC FACT, ADD & REM CAPABILITIES //////////////////////

+state(work_nights(NightsWorked), work_percentage(WorkPercentage))
		<-
		+work_nights(NightsWorked);
		+work_percentage(WorkPercentage);
.		


+!decompose_to_parts(Mode,FactHours)	// Mode = Fact, Add 
			<-
			for(.member(I,[1,2,3,4,5,6,7,8])) {
				FactPartHours = math.min(3, math.max(FactHours - (8 - I) * 3,0));
				-hours(Mode,I,_);
				if(FactPartHours > 0) {
					+hours(Mode,I,FactPartHours);
				};
			};
.



+!calc_fact_add_rem
			: work(will_work(WorkHours), will_rest(RestHours1), 
				is_holiday(Holiday)) 
			<- 
			+in_work;
			if(Holiday == yes) {
				+holiday;
			};
			
			+work_end(WorkHours);
			?min_rest(MinRestHours1);
			?max_buffer(BufTime);
			RestHours = RestHours1 + BufTime;
			MinRestHours = MinRestHours1 + BufTime; 
			
			?work_nights(NightsWorked);
			?night_interval(StartNight,EndNight);
			?hours_to_end(PrevHours);
			
			//FACT
			FreeHours = 24 + PrevHours - WorkHours;  // NB - can be > 24!
			!trunc_hour(24 + PrevHours - WorkHours - RestHours,FactHours);
			!trunc_hour(48 + PrevHours - WorkHours - RestHours,FactHours_tomorrow);
			!trunc_hour(72 + PrevHours - WorkHours - RestHours,FactHours_datomorrow);
	
			
			+fact(FactHours);
			+fact_tomorrow(FactHours_tomorrow);
			+fact_datomorrow(FactHours_datomorrow);
			
			
			// ADD
//			if (FactHours == 0) {
				if (NightsWorked == 2) {
					!get_nonight_hours(FreeHours - MinRestHours,AddHours,AddStart);
				} else {
					!trunc_hour(FreeHours - MinRestHours,AddHours);
					AddStart = 24 - AddHours;
				};
				+start_work(AddStart);
	/*		} else {
				AddHours = 0;
				AddStart = 0;
				+start_work(24 - FactHours);
			};*/
			// AddCost = AddStart;

			
			+add(tuple(AddHours,AddStart));
			
			// REM
			//if (OverHours > 7) {
				//RemEnd = math.max(WorkHours + 42, WorkHours + RestHours + 24);
				//+dayoff;
			//} else {
				if (NightsWorked == 2) {
					RemEnd = 24 + (EndNight mod 24);	// You postpone team to the day after tomorrow	
				} else {
					RemEnd = 24;						// You postpone team to end of the tomorrow
				};
			//};

			+remend(RemEnd);
.


+!calc_fact_add_rem
		: rest(past_rest(PastRestHours), will_rest(MoreRestHours1), 
				is_holiday(Holiday))  
			<- 
			+on_rest;
			?min_rest(MinRestHours1);
			?max_buffer(BufTime);
			MoreRestHours = MoreRestHours1 + BufTime;
			MinRestHours = MinRestHours1 + BufTime; 
			+work_end(-PastRestHours);
			
			?work_nights(NightsWorked);
			?night_interval(StartNight,EndNight);
			?hours_to_end(PrevHours);
			
			if(Holiday == yes) {
				+holiday;
			};

			//FACT
			!trunc_hour(24 + PrevHours - MoreRestHours,FactHours);
			!trunc_hour(48 + PrevHours - MoreRestHours,FactHours_tomorrow);
			!trunc_hour(72 + PrevHours - MoreRestHours,FactHours_datomorrow);
	
			
			+fact(FactHours);
			+fact_tomorrow(FactHours_tomorrow);
			+fact_datomorrow(FactHours_datomorrow);
			
			// ADD
//			if (FactHours == 0) {
				MinMoreRestHours = math.max(0,MinRestHours - PastRestHours);
				if (NightsWorked == 2) {
					!get_nonight_hours(24 - MinMoreRestHours,AddHours,AddStart);
				} else {
					AddHours = 24 - MinMoreRestHours;
					AddStart = MinMoreRestHours;
				};
				+start_work(AddStart);
	/*		} else {
				AddHours = 0;
				AddCost = 0;
				AddStart = 24;
				+start_work(24-FactHours);
			};*/
			

			+add(tuple(AddHours,AddStart));


			// REM
			RemHours = FactHours;
			RemCost = FactHours;
			//if (OverHours > 7) {
			//	RemEnd = math.max(42 - PastRestHours, MoreRestHours + 24);
			//	+dayoff;
			//} else {
				if (NightsWorked == 2) {
					RemEnd = 24 + (EndNight mod 24);			
				} else {
					RemEnd = 24;
				};
			//};

			
			//Rem
			
			+remend(RemEnd);
.

+!calc_fact_add_rem
		: vacation(will_start(TimeStart1))
			<- 
			?max_buffer(BufTime);
			TimeStart = TimeStart1 + BufTime;
			+work_end(-10000);

			!trunc_hour(24 - TimeStart,FactHours);
			!trunc_hour(48 - TimeStart,FactHours_tomorrow);
			!trunc_hour(72 - TimeStart,FactHours_datomorrow);
			
			+start_work(TimeStart);
			
			+fact(FactHours);
			+fact_tomorrow(FactHours_tomorrow);
			+fact_datomorrow(FactHours_datomorrow);
			
			+add(tuple(0,0));

			+remend(24);
.

/////////////////////////// try to avoid night work ////////////////////////////////////

+!get_nonight_hours(AH,0,0) : AH <= 0.

+!get_nonight_hours(AvHours,AvHours,24 - AvHours)
		: night_interval(_,NE) & (24 - AvHours) < (NE + 4). // planned start recently after night
		
		
+!get_nonight_hours(AvHours,24 - NE, NE)					// planned start shortly before night
		: night_interval(NS,NE) & (24 - AvHours) < NE & (24 - AvHours) > NS - 4.
				
		
+!get_nonight_hours(_,0,0).		


//////////////////////////// rest ratio needed to estimate utility ////////////////////////////////////


+!get_rest_ratio(TimeStart,RestRatio) 
			: work(will_work(WorkHours), will_rest(RestHours1),_) 
			<-
			?fact(FactHours);
			?max_buffer(BufTime);
			?hours_to_end(PrevHours);

			FactRestHours = PrevHours + TimeStart -  WorkHours - BufTime;
			RestRatio = FactRestHours / RestHours1;
.

+!get_rest_ratio(TimeStart,RestRatio) 
			: rest(past_rest(PastRestHours), will_rest(MoreRestHours1),_)
			<-
			?fact(FactHours);
			?max_buffer(BufTime);
			?hours_to_end(PrevHours);

			FactRestHours = PrevHours + PastRestHours + TimeStart - BufTime;
			RestRatio = FactRestHours / (PastRestHours + MoreRestHours1);
.


+!get_rest_ratio(_,1). 


/////////////////////////////////////////////////////////////////////////////////////////////////


+!trunc_hour(Hours,24): Hours >= 24.			
+!trunc_hour(Hours,0): Hours <= 0.
+!trunc_hour(Hours,math.round(Hours*100) * 0.01): Hours > 0 & Hours < 24.


//////////////////////////////////// MAIN ////////////////////////////////////////////

+!run_interval(I,NR) <- 
		-+interval(I);
		-+cycles(0);
		!run(NR);
.		


+!run(NR): planned(_) <- !print(run(NR,planned)); 
			-+run(NR); !finish_round.

+!run(_) : nodirection(0) <-  !print(run(NR,nodirection)); !finish_round. 

+!run(NR)  <-
		!print(run(NR,position));
		-+run(NR);
		!position;
.		

					
//////////////////////////////////////// from loco distribution //////////////////////////////////////
		
+!position : freehours
			<- 
			?part_names_interval(PartList);
			!print(part_names(PartList));
			.abolish(chance);						// no info about stations vacancy
			!position(PartList,false).

+!position : not freehours <- !print(position(NR,nofreehours)); !finish_round.
			
+!position(_,_): planned(_) <- 			
				!print(planned);
				!finish_round.  // if postion was found on previous iteration

+!position([],_): chance 
		& cycles (CN) & maxcycles(MCN) & CN < MCN
		<- 	-+cycles(CN+1);						// and not MaxCycles cycles passed -
			!print(chance); !position. 			// redo vacant place search

+!position([],_): cycles (CN) & maxcycles(MCN) & CN < MCN  
			<- 		
			!print(nochance);					// all places are occupied
			-+cycles(CN+1);						// and not MaxCycles cycles passed -
			!finish_round.						// try another cycle
													
+!position([],_) <-  	
			!print(stopsearch);
			!stop_search.						// all places are occupied
												// and MaxCycles cycles passed
																	

+!position([PartName|Tail],_) <-
			!print(find);
			?name(Name);
			?run(NR);
			?part_name(PartNo,PartName);
			?plusutil(NR,PartNo,PU);
			
			.send(PartName,askOne,is_vacant(Name,PU,NR,Reply),is_vacant(Name,PU,NR,Reply));
			!print(send(PartName,askOne,is_vacant(Name,PU,NR,Reply)));
			!print(reply(Reply));
			!check_response(PartName,Reply);
			!position(Tail,Reply).
			
+!check_response(PartName,busy)<-
			!print(response(PartName,busy));
			+chance.		// some stations are busy dealing with loco requests - ask them later


@padsositionplan[atomic]			
+!check_response(PartName,false) <-
				?part_names_interval(PartNames);
				.delete(PartName,PartNames,NewPartList);
				!update_part_names_interval(NewPartList);
				!print(response(PartName,false,NewPartList));
.			




+!check_response(PartName,vacant)<-
			?part_name(PartNo,PartName);	
			!print(response(PartName,vacant));
			?name(Name); 
			+planned(part_name(PartName));
			?depot_name(Depot);
			.send(Depot,tell,planned(Name));
			?plusutil(1,PartNo,PU);
			!print(add_team(PartName,PU));
			.abolish(added);
			.send(PartName,achieve,add_team(Name,PU));
			!check(added);
.			


+?plusutil(1,PartNo,tuple(A,B)): hours(fact,PartNo,_) <- 
			?plusutil(fact,tuple(A,B)).

+?plusutil(1,PartNo,tuple(A,B)): hours(add,PartNo,_) <- 
			?plusutil(add,tuple(A,B)).		

/* //from v.13.
+?plusutil(1,PartNo,tuple(Anew-WE,B,C)): hours(fact,PartNo,_) <- 
			?plusutil(fact,tuple(A,B,C));
			!get_rest_ratio(3*(PartNo-1),RestRatio);
			RR = math.round(RestRatio*100);
			if(in_work) {
				Anew = RR - 100;
			} else{
				Anew = RR;
			};
			?work_end(WE);
.

									
+?plusutil(1,PartNo,tuple(A,Bnew-WE,C)): hours(add,PartNo,_) <- 
			?plusutil(add,tuple(A,B,C));			
			!get_rest_ratio(3*(PartNo-1),RestRatio);
			RR = math.round(RestRatio*100);
			if(in_work) {
				Bnew = RR - 100;
			} else{
				Bnew = RR;
			};
			?work_end(WE);
.			
*/
			
+?plusutil(1,_,_) <- .print("Plusutil has wrong argument. STOP."); !stop.

//@f8gt4rr[atomic]
+!set_free
			<-
				.abolish(planned(_));
				-+cycles(0);
				?depot_name(Depot);
				?name(Name);
				.send(Depot,untell,planned(Name));
				!print("SetFree");
				!position;
.


+!stop_search <- 
		.print("Max number of cycles reached without convergence. Will STOP in 30 sec.");
		.wait(30000);
		?main(Main);
		.send(Main,achieve,stop);
.	


+!finish_round <-
		?depot_name(Depot);
		?id(Id);
		.send(Depot,tell,round_finished(Id));
.		
	

+!output_plan 
			<-
			?id(Id);
			
			if(planned(part_name(PartName))) {
				!print(planned(part_name(PartName)));
				.send(PartName,askOne,no(No1),no(No1));
				if(hours(fact,No1,FactPartHours)) {
					TimeStart = No1 * 3 - FactPartHours;
					CPref = "full_";
				} else {
					?hours(add,No1,AddPartHours);
					TimeStart = No1 * 3 - AddPartHours;
					CPref = "cut_";
				};
				if(holiday) {
					CPost = "holiday";
				} else { 
					CPost = "rest";
				};
				.concat(CPref,CPost,CTypeSt);
				.term2string(CType,CTypeSt);
				.send(PartName,askOne,direction_name(DirName)
					,direction_name(DirName));
				!print(send(PartName,askOne,direction_name(DirName)));
				.send(DirName,askOne,id(DirId),id(DirId));
				!get_rest_ratio(TimeStart,RestRatio);
				+rest_ratio(RestRatio);
				?buffer(DirId,DirBufTime);
				
				?plusutil(1,No1,tuple(U1,U2));  
				//?plusutil(2,U4);
				Util = U1*1000000 + U2*1000 +
						 + U4;
				Rank = 90000000 - Util;
				
				!tell(to_work(id(Id), direction(DirId),  
							work_from(TimeStart - DirBufTime),
							drive_from(TimeStart),call_type(CType),
							rank(Rank)));
				//!tell(rest_ratio(id(Id),RestRatio));

			} else {
				!print(not_planned);
				?remend(Time);
				if(dayoff) {
					!tell(to_dayoff(id(Id), work_from(Time)));
				} else {
					!tell(to_rest(id(Id), work_from(Time)));
				};
				if(freehours) {
					?start_work(StartTime);
					!tell(reserve(id(Id), 
							available_from(StartTime), 
							util(Util)));
				};
			};
			?depot_name(Depot);
			.send(Depot,tell,team_output_done(Id));

.			

+!output_rest_ratio <-
		if(planned(_)) { 
			?rest_ratio(RestRatio);
			?depot_name(Depot);
			?id(Id);
			!tell(rest_ratio(team(Id),ratio(RestRatio)));
			.send(Depot,tell,team_rest_ratio(RestRatio));
		}
.		
			

//////////////////////////////////////////////////////////////////////////////////////////


+!tell(A) <-
		?main(Main);
		.send(Main,achieve,tell(A));
.		


