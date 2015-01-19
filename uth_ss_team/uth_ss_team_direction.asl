////////////// direction agent which controls the vacancies refill  //////////////////

+!init <-
			.my_name(Name);
			-+name(Name);
			!check(main(Main));

			!check(id(Id));
			
			.send(Main, askAll, team_allowed(team(_), direction(Id)));
			.send(Main, askOne,debug_output);
			if (byParts){
				!check(.count(norm(part(_),_),8));
			} else {
				!check(.count(norm(shift(_),_),2));
			}
			
			.send(Main,tell,dir_data_ready(Name));
.			


+part_norms(PartList)  : byParts
<-
	for(.member(List,PartList)){
		List = [NPart, PartNorm];
		//.print(NPart, PartNorm);
		+norm(part(NPart), PartNorm); 
	};
.

+norm(shift(NS),ShiftNorm)  : not byParts
		<-
		-sum(NS,_);
		+sum(NS,0);
		for(.member(I,[2,3,4])) {
			NPart = 4*(NS-1) + I;
			?sum(NS,Sum);
			NextSum = math.round(I * ShiftNorm / 4);
			ThisSum = math.round((I-1) * ShiftNorm / 4);
			PartNorm = NextSum - ThisSum;
			-sum(NS,_);
			+sum(NS,Sum + PartNorm);
			+norm(part(NPart), PartNorm); 
		};
		?sum(NS,Sum);
		+norm(part(4*(NS-1) + 1), ShiftNorm - Sum); 
.

//@afpiemr4e[atomic]
+part_processed(_):  .count(part_processed(_),8)
<-
		+parts_processed;
.

+!process_data 
		<-
		?parts(Parts);
		.send(Parts,achieve,process_data);
		!check(parts_processed);
		
		?id(Id);
		?depot_name(DepName);
		.send(DepName,tell,direction_processed(Id));
.

//@u98hfo9[atomic]
+!calc_util(NR) <-
		-+run(NR);
		?parts(Parts);  
		.abolish(util(_,_));
		.abolish(util(_));
		.send(Parts,achieve,calc_util(NR));
		!check(util(Util));
		?name(Name);
		!print(util(Name,Util));
		?id(Id);
		?depot_name(DepName);
		.send(DepName,tell,util(Id,Util));				
.

//@shg8ubv8[atomic]
+util(_,_) : .count(util(_,_),8)	<-
			if(run(1)) {
				.findall(tuple(A1,B1),util(_,tuple(A1,B1)),UtilList);
				!get_sum_util(UtilList,Util);
			} else {
				.findall(A1,util(_,A1),UtilList);
				Util = math.sum(UtilList);
			};
			!print(util([Util,UtilList]));
			-+util(Util);
.



+!get_sum_util([],tuple(0,0)).

+!get_sum_util([tuple(A,B)|Tail],
	tuple(Asum,Bsum)) <-
		!get_sum_util(Tail,tuple(A1,B1));
		Asum = A+A1;
		Bsum = B+B1;
.		


///////////////////////////////////  OUTPUTS  ///////////////////////////////////


+!print_norms
<-
	if (byParts){
		?id(Id);
		for (.range(I, 1, 8)){
			?norm(part(I), INorm);
			.puts("Part #{I} norm for direction #{Id} is: #{INorm} teams.");
		}
	} else {
		?norm(shift(1),FNorm);
		?norm(shift(2),SNorm);
		?id(Id);
		.puts("First shift norm for direction #{Id} is: #{FNorm} teams.");
		.puts("Second shift norm for direction #{Id} is: #{SNorm} teams.");
	}
.

//@bre9bvf[atomic]
+team_count(_)[source(_)] : .count(team_count(_)[source(_)] ,4)
		<-
		.findall(N,team_count(N)[source(_)],NList);
		NSum = math.sum(NList);
		+shift_sum(NSum);
.

+!output_facts
		<- 
		?parts_shift1(Parts1);
		?parts_shift2(Parts2);
		.abolish(team_count(_));
		.abolish(shift_sum(_));
		.send(Parts1,askOne,team_count(N1));
		!check(shift_sum(SS1));
		+shift_sum(1,SS1);
		.abolish(team_count(_));
		.abolish(shift_sum(_));
		.send(Parts2,askOne,team_count(N2));
		!check(shift_sum(SS2));
		+shift_sum(2,SS2);
						
		?id(Id);
		if (byParts){
			+temp1(0)
			+temp2(0);
			for (.range(I, 1, 4)){
				?norm(part(I), Norm1);
				?temp1(TNorm);
				-+temp1(TNorm + Norm1)
			}
			for (.range(I, 5, 8)){
				?norm(part(I), Norm2);
				?temp2(TNorm);
				-+temp2(TNorm + Norm2)
			}
			?temp1(FNorm);
			?temp2(SNorm);
			!tell(direction(id(Id),shift(1),norm(FNorm), plan(SS1)));
			!tell(direction(id(Id),shift(2),norm(SNorm),plan(SS2)));
			
		} else {
			?norm(shift(1),FNorm);
			?norm(shift(2),SNorm);
			!tell(direction(id(Id),shift(1),norm(FNorm), plan(SS1)));
			!tell(direction(id(Id),shift(2),norm(SNorm),plan(SS2)));
		}
			
		
		//.puts("Total fact for direction #{Id}, shift #1 is: #{SS1} teams.");
		//.puts("Total fact for direction #{Id}, shift #2 is: #{SS2} teams.");
		
		?depot_name(Depot);
		.send(Depot,tell,direction_output_done(Id));
.


+!tell(A) <-
		?main(Main);
		.send(Main,achieve,tell(A));
.		

///////////////////////////////////////////////////////////////////////////////////////////
				
+?part_name(PartNo,PartName) <-
	?name(Name);
	!get_part_name(Name,PartNo,PartName);
	.
