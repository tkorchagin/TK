/////////////// depot agent which plans for the depot  //////////////////////////

///////////////////// control and initial data /////////////////////////////////

rep_cycles(0).

max_repcycles(2).


///////////////////// FACT TIME AND ADD & REM TIME RETURNED BY TEAMS //////////////////////

//@nidc8ee[atomic]
+team_ready(_) : .count(team_ready(_),N) & nteams(N)
				<-
				+team_data_ready;
.



//////////////////////////////////////////////////////////////////////////////////////////

+!init  
				<-
				.my_name(Name);
				-+name(Name);
				
				!check(main(Main));
				.send(Main, askOne,debug_output);

			
				?night_start(StartNight);
				+night_interval(StartNight, (StartNight + 5) mod 24);
				
				+util(tuple(-10000,-10000));
.




+!run <-
				?id(Id);
				if(not (ndirections(0) | nteams(0))) {
					.print("Start processing data...");
					!process_data;
					.print("Finished processing");
					
					.abolish(plan_ready(_,_));
					for(.member(I,[1,2,3,4,5,6,7,8])) {
						-+interval(I);
						-+rep_cycles(0);
						-+util(-100000);
						-+run(2);
						!iterate(2);				
						-+rep_cycles(0);
						-+util(-100000);
						-+run(1);
						!iterate(1);				
					};
					.print("Finished"); 
				} else {
					.puts("Plnannig will not be done for depot # #{Id} due to lack of direction or teams data");
				};	
				!check(main(Main));
				.send(Main,tell,depot_finished(Id));						
.


+!iterate(NR) : interval(I) & plan_ready(I,NR).
+!iterate(NR) : interval(I) & not plan_ready(I,NR)
		<-				
				!print(runno(run(NR),not_plan_ready(NR)));
				?teams(TeamList);
				!print(depotteamlist(TeamList));
				.abolish(round_finished(_));
				.send(TeamList,achieve,run_interval(I,NR));
				//.wait({+round_finished});
				!check(round_finished);
				
				?util(Util1);
				.abolish(util(_));
				.abolish(util(_,_));
				?directions(DirList);
				.send(DirList,achieve,calc_util(NR));
				!check(util(Util));
				?id(Id);
				.print(uTIL(Id,I,Util));
				if(util(Util1)) {
					?rep_cycles(NN);
					-+rep_cycles(NN+1);
					if(max_repcycles(NN+1)) {
						+plan_ready(I,NR);
					};
				};
				!iterate(NR);
.       

+!iterate(NR) <- .print("Incorrect run No:", NR).
 
+!tell(A) <-
		?main(Main);
		.send(Main,achieve,tell(A));
.		

//@shqeg8ubv8[atomic]
+round_finished(_) : .count(round_finished(_),N) & nteams(N)
				<-
				!print(round_FINISHED);
				+round_finished;
.
				


//@shg8ubv8[atomic]
+util(_,_) : .count(util(_,_),N) & ndirections(N)  
			<-
			if(run(1)) {
				.findall(tuple(A1,B1),util(_,tuple(A1,B1)),UtilList);
				!get_sum_util(UtilList,Util);
			} else {
				.findall(A1,util(_,A1),UtilList);
				Util = math.sum(UtilList);
			};
			!print([Util,UtilList]);
			-+util(Util);
.


+!get_sum_util([],tuple(0,0)).

+!get_sum_util([tuple(A,B)|Tail],
	tuple(Asum,Bsum)) <-
		!get_sum_util(Tail,tuple(A1,B1));
		Asum = A+A1;
		Bsum = B+B1;
.		



/////////////////////////////////////    INPUT     ///////////////////////////////


+!process_data 
				<-
			?teams(TeamList);
			if(TeamList \==[]) {
				.send(TeamList,achieve,calc_team);
				!check(team_data_ready);
			

				?directions(DirList);
				if(DirList \==[]) {
					.send(DirList,achieve,process_data);
					.wait({+directions_ready});
				} else {
					?id(Id);
					.puts("No directions available in depot #{Id}");
				}
			} else {
				?id(Id);
				.puts("No teams available in depot #{Id}");
			}
			

.				

//@webf7ewbfc[atomic]
+direction_processed(_): .count(direction_processed(_),N) & ndirections(N)
		<-
		+directions_ready;
.


///////////////////////////////////  OUTPUTS  ///////////////////////////////////


+!print_norms <-
			?directions(DirList);
			.send(DirList,achieve,print_norms);
.


+!output <-
			!output_facts;
			!output_plans;

			?main(Main);
			?id(Id);
			.send(Main,tell,depot_output_finished(Id));
.

+!output_facts  
				<- 
				if(not ndirections(0)) {
					?directions(DirList);
					.send(DirList,achieve,output_facts);
					!print(send(DirList,achieve,output_facts));
					!check(directions_output_done);
				};	

.

+!output_plans 
			<-
				if(not nteams(0)) {
					.findall(Team,planned(Team),PlannedTeams);
					.length(PlannedTeams,Nplanned);
					-+n_planned_teams(Nplanned);
					?teams(Teams);
					.send(Teams,achieve,output_plan);
					!print(send(Teams,achieve,output_plan));
					!check(teams_output_done);
					.send(Teams,achieve,output_rest_ratio);
					!print(send(Teams,achieve,output_rest_ratio));
					if(Nplanned > 0) {
						!check(avg_rest_ratio(ARR));
					} else { 
						ARR = na;
					}
					?id(Id);
					!tell(depot_avg_rest_ratio(id(Id),rest_ratio(ARR)));
				};	

.			



//@aldf0q2de[atomic]
+print_done(_) : .count(print_done(_),N) & ndirections(N) 
			<-
			+print_done;
			.abolish(print_done(_));
.			

//@adsfss2de[atomic]
+direction_output_done(_) : .count(direction_output_done(_),N) & ndirections(N) 
			<-
			+directions_output_done;
			.abolish(direction_output_done(_));
.			

//@aqerds32e[atomic]
+team_output_done(_) : .count(team_output_done(_),N) & nteams(N) 
			<-
			+teams_output_done;
			.abolish(team_output_done(_));
.			


+team_rest_ratio(_)[_] : .count(team_rest_ratio(_)[_],N) & n_planned_teams(N) 
			<-
			.findall(RestRatio,team_rest_ratio(RestRatio)[source(_)],RRList);
			.abolish(team_statistics_done(_));
			RRSum = math.sum(RRList);
			ARR = RRSum / N;
			+avg_rest_ratio(ARR);
.			




////////////////////////////////////////////////////////////////////////////////				
				
+!get_time_diff(DH,DM,DS,DH,DM,DS): DS >= 0 & DM >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH,DM-1,60+DS): DM >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH-1,60+DM,DS): DS >= 0 <- true.
+!get_time_diff(DH,DM,DS,DH-1,60+DM-1,60+DS) <- true.
		
///////////////////////////////////////////////////////////////////////////////////////////

+?preceeds(date(Y,M,D),date(Y,M,D-1)): D > 1.   
+?preceeds(date(Y,M,1),date(Y,M-1,31)): .member(M-1,[3,5,7,8,10,12]).
+?preceeds(date(Y,M,1),date(Y,M-1,30)): .member(M-1,[4,6,9,11]).
+?preceeds(date(Y,M,1),date(Y,M-1,28)): M == 3 
				& ( (math.round(Y/100) * 100 == Y & (math.round(Y/400) * 400 \== Y ) ) 
				  |  ((math.round(Y/4) * 4 \== Y) )).
+?preceeds(date(Y,M,1),date(Y,M-1,29)): M == 3.
+?preceeds(date(Y,1,1),date(Y-1,12,31)).


/////////////////////////////////////////////////////////////////////////////////

+!trunc_day(Days,1): Days > 1.			
+!trunc_day(Days,0): Days < 0.
+!trunc_day(Days,A) <- A = math.round(Days*1000) * 0.001.



+!round(A,Ar) <- Ar = math.round(A * 1000.00) * 0.001.

				
/////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////

+!tell(A) <-
		?main(Main);
		.send(Main,achieve,tell(A));
.		


