////////////// direction agent which controls the vacancies refill  //////////////////

team_list(1,[]).
team_count(0).

team_list(2,[]).


+!init <-
			.my_name(Name);
			-+name(Name); 
			!check(no(No1));
			!check(main(Main));
			.send(Main, askOne,debug_output);
			
			!check(direction_name(DirName));
		
			.send(DirName, askOne, norm(part(No1), PartNorm)); 
			!check(norm(part(No1), PartNorm));
			+norm(PartNorm);
			.send(Main, tell,init_done(No1,DirName));
			
.			


+!process_data 
		<-
		?depot_name(DepName);
		?name(Name);
		if(nplans(N) & N > 0) {
			.send(DepName,askOne,teams(TeamList),teams(TeamList));
			.send(TeamList,askAll,planned(part_name(Name)));
			!check(team_data_gathered);
		}

		!update_vacant;
		?direction_name(DirName);
		?no(No1);
		.send(DirName,tell,part_processed(No1));
.

@u98hfo9 //[atomic]
+!calc_util(NR) <-
		?team_list(NR,TUL);
		!get_sum_util(NR,TUL,Util);
		?name(Name);
		!print(util(Name,Util));
		?no(No1);
		?direction_name(DirName);
		.send(DirName,tell,util(No1,Util));				
.


-!calc_util(NR)  <-
		?team_list(NR,TUL);
.

+!get_sum_util(1,[],tuple(0,0)).

+!get_sum_util(1,[tuple(tuple(A,B),_)|Tail],
	tuple(Asum,Bsum)) <-
		!get_sum_util(1,Tail,tuple(A1,B1));
		Asum = A+A1;
		Bsum = B+B1;
.		


+!get_sum_util(2,[],0).

+!get_sum_util(2,[tuple(A,_)|Tail],Sum) <-
		!get_sum_util(2,Tail,A1);
		Sum = A+A1;
.		


///////////////////////////////////  OUTPUTS  ///////////////////////////////////


+!tell(A) <-
		?main(Main);
		.send(Main,achieve,tell(A));
.		
///////////////////////////////////////////////////////////////////////////////////////

@dc0sax3c[atomic]
+planned(_)[source(Team)] 
		<- 
		if(vacant) {
			.send(Team,askOne,plusutil(fact,PU), plusutil(fact,PU));
			.send(Team,askOne,plusutil(2,PU2), plusutil(2,PU2));
			!add_team(Team,PU,PU2);
		} else {
			?id(Id);
			.send(Team,achieve,set_free);
		}
		.count(planned(_),N1);
		if(nplans(N1)) {
			+team_data_gathered;
		};
.



///////////////////////////// from loco distribution ////////////////////////////////////
		

@paddteam1[atomic]		
+!add_team(Team,PlusUtil,PU2)  
		<- 
			?team_list(1,LL);
			?team_list(2,LL2);
			?team_count(N); 
			.union([tuple(PlusUtil,Team)],LL,NewLL);
			.union([tuple(PU2,Team)],LL2,NewLL2);
			!print(add_sl(tuple(PlusUtil,Team)));
			-team_list(1,_);
			-team_list(2,_);
			+team_list(1,NewLL);
			+team_list(2,NewLL2);
			!print(add_sl(team_list(1,NewLL), team_list(2,NewLL2)));
			+team(Team);	
			-+team_count(N+1);
			!update_vacant;
			-busy(Name);
			.send(Team,tell,added);
.

@puvadaddteam1[atomic]	
+!update_vacant: team_count(L) & norm(N) & L < N 
					<-	
					+vacant.

@puvadaddteam1qee[atomic]						
+!update_vacant <-	 -vacant;
.

@isvacant0[atomic]
+?is_vacant(Name,_,_,false) : norm(0)		// If no need of this shift
	<-		
			//.send(Name,tell,reply(false));
			!print(send(Name,tell,reply(false)));
.

@isvacant[atomic]
+?is_vacant(Name,_,_,vacant): vacant <-
				-vacant;
				+busy(Name);
				//.send(Name,tell,reply(vacant));
				!print(send(Name,tell,reply(vacant)));
.


@isvacant2[atomic]
+?is_vacant(Name,_,_,busy): busy(_)
<- //.send(Name,tell,reply(busy)); 
	!print(send(Name,tell,reply(busy)));
.				

@isvacant3[atomic]								// if no more place - then check utility
+?is_vacant(Name,PlusUtil,NR,Reply): not vacant
			<-
 			!print(["not vacant,",Name]);
			?team_list(NR,A);
			!print([tl(A),tuple(PlusUtil,Name)]);
			if( A = [tuple(Util1,Name1)|T] & .sort([PlusUtil,Util1],[Util1,_] ) & 
				not PlusUtil = Util1) {  					// Utility is better
				!print(swap(tuple(PlusUtil,Name),tuple(Util1,Name1)));
				+busy(Name);
				-team_list(NR,A);
				+team_list(NR,T);
				CNR = 3-NR;
				?team_list(CNR,T2L);
				.delete(tuple(_,Name1),T2L,T2LNew);
				-team_list(CNR,_);
				+team_list(CNR,T2LNew);
				!print(rem(team_list(NR,T)));
				?team_count(N);
				-+team_count(N-1);
				-team(Name1);	
				.send(Name1,achieve,set_free); 
				Reply = vacant;
			} else {
				Reply = false;
			};
			//.send(Name,tell,reply(Reply));
			!print(send(Name,tell,reply(Reply)));
			
.


///////////////////////////////////////////////////////////////////////////////////////////
				

