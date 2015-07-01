//debug.
//opdebug.

freesend.
freeadd.
inf(1000000).

step(0).
localstep(0).
localmaxstep(10).

weight(0).

init.

bids_processed(0).
bids_received(0).


dimension(Dim) :- nperson_classes(Dim).

get_multi_head(_,[],[],[]) :- true.	

get_multi_head(Quantity,[H|A],[H|B],RefusalList) :- 
	H = [_,Flow,_] 
	& Flow <= Quantity
	& get_multi_head(Quantity - Flow,A,B,RefusalList).

get_multi_head(Quantity,[[Bid,Flow,PClass] | Tail],
	[[Bid,Quantity,PClass] | NullTail], 
	[PClass | RefusalList]) 
	:-	
	Flow > Quantity
	& nullate(Tail, NullTail, RefusalList).

nullate([], [], []) :- true.	
nullate([[_,_,PClass] | Tail], 
	[[0,0,PClass] | NullTail], 
	[PClass | RefusalTail]) 
	:- 	
	nullate(Tail, NullTail, RefusalTail).



@aefwedf[atomic]
+!halt[source(Sender)] <-
	.drop_all_desires;
	.drop_all_events;
	.send(Sender,tell,oclass_halted);
.

	
+init <- 
		!check(main(Main)); 
		.send(Main,tell,object_class_end);
.

+!set_person_classes(PClasses) 
	<-
	-+person_classes(PClasses);
	?myclassCapacity(Capacity);
	?myclass(OClass);
	.send(PClasses,achieve, 
		update_prices([[0,Capacity,null]],OClass));
	if(debug) {
		+history_tell_prices([[0,Capacity,null]],system.time);
	}
	?main(Main);
	.send(Main,tell,object_class_end);
.

@svdjvkr[atomic]
+!sleep <-
		?weight(Weight);
		-+weight(0);
		?main(Main);
		.send(Main,achieve,addweight(Weight));
		!print(sleep);
.	

@svkbverhbv[atomic]
+!addweight(Share)[source(Source)] <-
	?weight(Weight);
	-+weight(Weight+Share);
	if(Source \== self) {
		.send(Source,tell,added);
	}
	!print(weight(Weight+Share));
.	



+!send([],_,_).

+!send(Recip,Mode,Message) : .list(Recip)
	<-
	!check(freesend);
	.abolish(freesend);
	.length(Recip,N);
	!sent_handle(N,Recip);		
	for(.member(Agent,Recip)) {
		!check(added[source(Agent)]);
	}
	.abolish(added[source(Agent)] & .member(Agent,Recip));
	.send(Recip,Mode,Message);
	+freesend;
.

+!finish[source(Sender)] <-
	!check(freesend);
	.send(Sender,tell,object_finished_work);
.


+!send(Recip,Mode,Message) : not .list(Recip)
		<-
		!check(freesend);
		.abolish(freesend);
		!sent_handle(1,Recip);	
		!wait(added[source(Recip)]);
		.send(Recip,Mode,Message);
		+freesend;
.

		
@esdfdsswnefs90[atomic]
+!sent_handle(N,Recip) <- 
		?weight(Weight);
		?dimension(Dim);
		Share = Weight / (N+Dim);
		.send(Recip,achieve,addweight(Share));	// share the weight with recipients
		!addweight(-N*Share);
.

	
@adsfjclks[atomic]	
+!get_next_token(BR+1) <-
	?bids_processed(BP);
	?bids_received(BR);
	-+bids_received(BR+1);
	if(debug) {
		+token_his(processed(BP),received(BR));
	}
.

+bid(ABid,AFlow,APersonClassAgent,APersonStep)
	<-
	//.print(bid(ABid,AFlow,APersonClassAgent,APersonStep));
	!get_next_token(TokRec);
	if(not bids_processed(TokRec-1)) {
		if(debug) {
			+token_fail_history(rec(TokRec),source(APersonClassAgent));
		}
		!check(bids_processed(TokRec-1));
	}
	if(debug) {
		?bids_processed(TokProc);
		if(debug) {
			+token_history(proc(TokProc),rec(TokRec),source(APersonClassAgent));
		}
	}
	
	!check(not lock);				// check that no weight change is in progress
	if(debug) {
		+bid_old(ABid,AFlow,APersonClassAgent,APersonStep);
	}
	+lockbids;
	.findall([Bid,Flow,PClass], bid(Bid,Flow,PClass,_), BidsList);
	.findall(Flow,.member([_,Flow,_],BidsList),FlowsList);
	TotalBidFlow = math.sum(FlowsList);
	// acc. to p.89
	?myclassCapacity(Capacity);
	if(Capacity >= TotalBidFlow) {	// that is, we can satisfy all the bids!
		BidsAccepted = [[0,Capacity - TotalBidFlow, null] | BidsList];
		RefusalList = [];
		// add null flow
	} else {						// that is, we can't satisfy all the bids
		.sort(BidsList,BidsSortedAscending);
		.reverse(BidsSortedAscending,BidsSorted);
		?get_multi_head(Capacity,BidsSorted,BidsAccepted,RefusalList);
		// attention: by inputs Capacity, BidsSorted 
		// 			  we get outputs BidsAccepted, RefusalList 
	}
	
	?weight(Weight);
	!print(bids(weight(Weight),aperson(APerson,ABid,APersonClassAgent),
		BidsAccepted));
	
	// Now we update prices and flows according to new bids
	?person_classes(PersonClasses);
	?myclass(OClass);
	.send(PersonClasses,achieve, update_prices(BidsAccepted,OClass));
	if(debug) {
		+history_tell_prices(BidsAccepted,system.time);
	}
	!send(RefusalList, tell, rejected);		
		// we send weight to refusal PClasses
		
	// now its time to respond to bids
	.send(APersonClassAgent,tell,bid_processed(ABid,APersonStep));
	if(debug) {
		+history_bid_processed(APersonClassAgent,ABid,APersonStep);
	}
	!print(send(APersonClassAgent,bid_processed(ABid,APersonStep))); 

	-+bids_processed(TokRec);			// release
	-lockbids;
.


@aasdmnllf[atomic]
+bids_processed(A) : bids_received(A)  & A > 0  
	<-
		!sleep;
		+sleep(system.time);
		//!wait(added[source(Main)]); 
.	



@sdfdsf[atomic]
+!iterate_step 
	<-
	?step(Step);
	-+step(Step+1);
	?localstep(LStep);
	-+localstep(LStep+1);
.	


+?price(Price) <- !check(price(Price)).


+!update_bid(Bid,Flow,Step)[source(PClassAgent)] <-
	!check(not lockbids);
	.abolish(bid(_,_,PClassAgent,_));
	+bid(Bid,Flow,PClassAgent,Step);
.	


+!check(A) : A.
+!check(A) <- .wait(100); !check(A).


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
		.abolish(A);
.

