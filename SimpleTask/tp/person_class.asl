//opdebug.
debug.

freesend.
freeadd.
inf(1000000).

check_timeout(5000).

prices_processed(0).
prices_received(0).

step(0).

localmaxstep(LMS) :- myclassCapacity(MCC) & .max([MCC,20],LMS).

dimension(Dim) :- nobject_classes(Dim).

weight(0).

cut_head(N,A,A) :- N <= 0.
cut_head(_,[],[]).
cut_head(N,[H|T],B) :- cut_head(N-1,T,B). 


get_head(N,_,[]) :- N <= 0.
get_head(N,[H|A],[H|B]) :- get_head(N-1,A,B).


get_multi_head(Quantity,_,[]) :- Quantity <= 0.
get_multi_head(Quantity,[H|A],[H|B]) :- 
	H = profit(_,Flow,_,_) 
	& get_multi_head(Quantity - Flow,A,B).

	
+nobject_classes(_) <-
	?main(Main);
	.send(Main,tell,nobject_classes_got);
.

+main(_) <-
	?main(Main);
	.send(Main,tell,main_got);
.


@wsrlbfjw[atomic]
+util(_,_) : nobject_classes(N) & .count(util(_,_),N)
		<- 
	?main(Main);
	.send(Main,tell,person_class_end);
.

+myclassCapacity(Capacity) <- +not_assigned(Capacity).


+!sleep <-
	?weight(Weight);
	-+weight(0);
	?main(Main);
	.send(Main,achieve,addweight(Weight));
	!wait(added[source(Main)]); 
.	



@ljnbdgfd[atomic]
+!addweight(Share)[source(self)] <-
	?weight(Weight);
	NewWeight = Weight+Share;
	-+weight(NewWeight);
	!print(weight(NewWeight));
.	


// for outer calls
+!addweight(S)[source(Source)] //: Source \== self 
	<-
	!addweight(S);
	.send(Source,tell,added);
	if(adebug) {
		+sent_added(system.time,Source);
	}
.	


+!send(Recip,Mode,Message) : .list(Recip)
	<-
	!check(freesend);
	.abolish(freesend);
	.length(Recip,N);
	.send(Recip,tell,lock);
	!sent_handle(N,Recip);		
	for(.member(Agent,Recip)) {
		!check(added[source(Agent)]);
	}
	.abolish(added[source(Agent)] & .member(Agent,Recip));
	.send(Recip,Mode,Message);
	.send(Recip,untell,lock);
	+freesend;
.

+!send(Recip,Mode,Message) 
	<-
	!check(freesend);
	.abolish(freesend);
	.send(Recip,tell,lock);
	!sent_handle(1,Recip);		
	!wait(added[source(Recip)]);
	.send(Recip,Mode,Message);
	.send(Recip,untell,lock);
	+freesend;
.

		
+!sent_handle(N,Recip) <- 
	?weight(Weight);
	?dimension(Dim);
	Share = Weight / (N+Dim);
	.send(Recip,achieve,addweight(Share));	// share the weight with recipients
	!addweight(-N*Share);
.


@vdjnafadfe4fd[atomic]
+!update_prices(Prices,OClass)[source(OCAgent)] 
	<-
	if(debug) {
		+history_prices(Prices,OClass);
	}
	+oclass_name(OClass,OCAgent);			// needed when sending bids
	.my_name(MyName);
	?myclassCapacity(Capacity);
	
	if(not price(_,OldFlow,MyName,OClass)) {OldFlow = 0};
		// calculate how many members of PClass was 
		// disposed in this OClass before 

	.abolish(price(price(_,_,_,OClass)));
		
	?not_assigned(NotAssigned);
	
	for(.member([Price,Flow,PClassAgent],Prices)) {
		if(Flow > 0) {
			+price(price(Price,Flow,PClassAgent,OClass));
		}
		if(PClassAgent == MyName) {
			-+not_assigned(NotAssigned + OldFlow - Flow);	
				// will work even if Flow = 0
		}
	}
.


+!start <- 
	?main(Main);
	?myclassCapacity(Capacity);
	-+not_assigned(Capacity);
	!put_into_queue(Main); 
.


@adsfjclks[atomic]	
+!get_next_token(BR+1) <-
	?prices_processed(BP);
	?prices_received(BR);
	-+prices_received(BR+1);
	if(debug) {
		+token_his(processed(BP),received(BR));
	}
.

	
+!put_into_queue(Object) <- 
	!get_next_token(TokRec);
	!getshare;
	if(not prices_processed(TokRec-1)) {
		if(debug) {
			+token_fail_history(rec(TokRec),source(Object));
		}
	}
	if(debug) {
		?prices_processed(TokProc);
		+token_history(proc(TokProc),rec(TokRec),source(Object));
	}
	!check(prices_processed(TokRec-1),10000); 
	-+localstep(0);
	!run(TokRec);
	-+prices_processed(TokRec);			// release
.
	
+!getshare <-
	?main(Main);
	.send(Main,askOne,share_weight(Share),share_weight(Share));
	.abolish(share_added);
	!addweight(Share);
.


+!run(Id): not_assigned(QuantityNotAssigned)  & QuantityNotAssigned > 0 
<-
	.my_name(Name);
	?main(Main);
	?myclassCapacity(MyClassCapacity);
	!check(price(_)); 
	?myclass(MyClass);
	?step(Step);
	
	.findall(price(Price,Flow,PClassAgent,OClass),
		price(price(Price,Flow,PClassAgent,OClass)),
			Prices); // fix prices
			
	!print(p(step(Step),prices(Prices)));
	
	
	.findall(flow(Flow,OClass),
			.member(price(_,Flow,Name,OClass),Prices) 
			,MyClassFlows);
			
	.findall(profit(Util - Price,Flow,PClassAgent,OClass),
			.member(price(Price,Flow,PClassAgent,OClass),Prices) 
			& PClassAgent \== Name & util(OClass,Util)
			,OtherProfitsUnsorted);		// equation (48) p.87 from ref.1
	
	if(debug) {
		+prices(step(Step),prices(Prices));
		+myclassflows(step(Step),flows(MyClassFlows));
		+otherprofits(step(Step),profits(OtherProfitsUnsorted));
	}

	if(OtherProfitsUnsorted == []) {
		//!stop("All vacancies are already mine");
		// nothing to do - all vacancies are filled by my class
	} else {
		?inf(Inf);
			
///		bid determination part		

		.sort(OtherProfitsUnsorted, OtherProfitsRev);		// - line changed
		.reverse(OtherProfitsRev, OtherProfits);
		?get_multi_head(QuantityNotAssigned,OtherProfits,NewBidProfits);
			//NewBidProfits is never empty
			// determine m from bottom line on p.87
			// now in NewBidProfits profits from first m flows
		NewBidProfits = [profit(_,_,_,MostProfitableOClass)|_];  
			// determine best OClass to handle NextProfit if there's only one nonzero flow (sse about screen below)
		.findall(flow(Flow,OClass),
			.member(flow(Flow,OClass),MyClassFlows)
			& not(.member(profit(_,_,_,OClass),NewBidProfits))
			,KeepAsIsFlows);
			// flows that are not from first m flows - first line on p. 88 
			// they are keps as is - no change
		-+newflows(KeepAsIsFlows);

			
		.reverse(NewBidProfits,
			[profit(HeadProfit,_,_,HeadOClass)|NewBidProfitsTail]);
		// NewBidProfitsTail - these flows have to be increased according to second 
		// equaition on p.88
		
		.findall(OClass,
			.member(profit(_,_,_,OClass),NewBidProfitsTail)
			,TailOblectClassesList);
		.union([],TailOblectClassesList,TailOblectClassesSet);
		.delete(NewBidProfitsHead,TailOblectClassesSet,TailOblectClasses);
		for(.member(CurOClass,TailOblectClasses)){
			.findall(CurFlow,
				.member(profit(_,CurFlow,_,CurOClass), OtherProfits) 
				,CurFlows);		// second equation on p.88 from ref.1
			AddCurFlow = math.sum(CurFlows);
			.member(flow(CurOClassFlow,CurOClass),MyClassFlows);
			?newflows(Flows);
			-+newflows([flow(CurOClassFlow + AddCurFlow,CurOClass)
				|Flows]);
		}
		// now in the belief newflows() are the flows for bids, except for the m-th flow
		?newflows(NewFlows);
		.findall(Flow,.member(flow(Flow,_),NewFlows),NewFlowsList);
		CurFlowsSum = math.sum(NewFlowsList);
		-+newflows([flow(MyClassCapacity - CurFlowsSum,HeadOClass)
				|NewFlows]);		
			// adding last flow as reamins according to 3d equation on p.88
			
		// Now its time to calculate bid values.
		
		// First, calculate number of non-zero flows for bids
		?newflows(AllNewFlows);
		.findall(OClass,.member(flow(Flow,OClass),AllNewFlows) & Flow > 0,
			NonZeroFlowClasses);
		.union([],NonZeroFlowClasses,NonZeroFlowClassesSet);
		.length(NonZeroFlowClassesSet,NonZeroFlowsNum);
		
		// Then, calculate NextProfit
		if(NonZeroFlowsNum > 1) {
			NextProfit = HeadProfit;
		} else {
			.findall(Profit,
				.member(profit(Profit,_,_,OClass), OtherProfits) 
				& OClass \== MostProfitableOClass, LessProfitableProfits);
			if(LessProfitableProfits \== []) {
				.max(LessProfitableProfits,NextProfit)
			} else {
				NextProfit  = -Inf;
			}
		}
		
		!print(next(NextProfit));
		
		?epsilon(Eps);

		//-+response_not_recieved(Step,ClassPersons);
		-bids_processed(Step);

		// Then, form the bids
		for(.member(flow(Flow,OClass),AllNewFlows)) {
			?util(OClass,Util);
			Bid = Util - NextProfit + Eps;
			?oclass_name(OClass,OCAgent);
			+bid(Bid,OCAgent,Step);				// to count bids

			//.send(OCAgent,untell,bid(_,_,MyClass,_));
			//!send(OCAgent,tell,bid(Bid,Flow,MyClass,Step));
			
			!send(OCAgent,achieve,update_bid(Bid,Flow,Step));
			if(debug) {
							!print(o(step(Step),
								util(Util),
								next(NextProfit),
								oclass(OClass),
								flow(Flow),
								bid(Bid)));
							+bid_history(step(Step),
								util(Util),
								next(NextProfit),
								oclass(OClass),
								flow(Flow),
								bid(Bid));
			}
		}

		!check(bids_processed(Step));
	}
	!iterate_step;
	!run(Id);
.


+!run(Id) <- 
	!print(sleep(Id));
	!sleep;
	!iterate_step;
	if(debug) {
		+finished(Id,system.time);
	}
.


@fsdkjhkjs[atomic]
+bid_processed(Bid,Step)[source(Source)]
	<-
	if(not debug) {
		-bid_processed(Bid,Step)[source(Source)]; 	// clean up
	}
	-bid(Bid,Source,Step);								 // mark as response recieved
.


@fwerwsdkjhkjs[atomic]
-bid(_,_,Step) : bid(_,_,Step).			// if there's still any bid
-bid(_,_,Step) <-  +bids_processed(Step).	// if there're no bids of current step


+rejected[source(OClass)] <- 
	-rejected[source(OClass)];
	!put_into_queue(OClass);
.


@sdfdsf[atomic]
+!iterate_step 
	<-
	?step(Step);
	-+step(Step+1);
	?localstep(LocStep);
	?localmaxstep(MaxStep);
	if(LocStep < MaxStep) {
		-+localstep(LocStep+1);
	} else {
		.concat("Current iteration steps exceeded max value: ",MaxStep,Message);
		!stop(Message); 
	}
.	

+?results(tuple(flows(Flows,MyClass),totals(TotUtil,TotCost,Steps))) 
	<- 
	.my_name(MyName);
	?myclass(MyClass);
	
	.findall(Util * Flow,
		price(price(_,Flow,MyName,OClass))
		& util(OClass,Util), 
		Utils);

	.findall(Cost * Flow,
		price(price(_,Flow,MyName,OClass))
		& cost(OClass,Cost), 
		Costs);
	
	
	.findall(flow(Flow,OClass),
		price(price(_,Flow,MyName,OClass))
		& util(OClass,Util), 
		Flows);
		
	TotUtil = math.sum(Utils);
	TotCost = math.sum(Costs);
	?step(Steps);
.
	
+!check(A) 
	<-
	?check_timeout(ChTO);
	!check(A,ChTO);
.	

+!check(A,_) : A <- -timing(A,_).
+!check(A,ChTO) <- 
	if(timing(A,StartTime)) {
		?check_timeout(ChTO);
		(system.time - StartTime) < ChTO;
	} else {
		+timing(A,system.time);
	}
	.wait(10); 
	!check(A).

-!check(A,ChTO) <-
	.concat("Check of ",A," has reached timeout ",ChTO,"ms. ",
			Message);
	!stop(Message).
	
+!stop(A) <-
	.print(A);
	.print("WILL STOP IN 100 sec");
	.wait(100000);
	.stopMAS;
.	

+!print(A) : opdebug <- .print(A).
+!print(A).


+!wait(A) <- 
		!check(A);
		-A;
.

