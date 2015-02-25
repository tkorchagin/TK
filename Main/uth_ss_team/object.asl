//debug.
//opdebug.

freesend.
freeadd.
inf(1000000).

epsilon(0.03).

step(0).
localstep(0).
localmaxstep(10).

weight(0).

bids_processed(0).
bids_received(0).


//@wsrlbfjw[atomic]
+util(Person,Util) : npersons(N) & .count(util(_,_),N)
		<-
		!check(main(Main));
		.send(Main,tell,object_end);
.


+!set_util(Person,Util) <-
	+util(Person,Util);
.

+!set_persons(Persons) <-
	-+persons(Persons);
	!check(main(Main));
	.send(Main,tell,object_end);
	!update_price(0);
.

+!update_price(NewPrice) <-
	?persons(Persons);
	.my_name(Me);.print(hey);
	.wait(100000);
	?myclass(MyClass);
	if(price(Price)) {
		.send(Persons,untell,price(Price,Me,MyClass));
		if(debug) {
			+untell_price(Price,Persons);
		}
	}
	-+price(NewPrice);
	.send(Persons,tell,price(NewPrice,Me,MyClass));
	if(debug) {
		+tell_price(NewPrice,Me,Persons);
	}
.


@sdfklnvdfls[atomic]
+!sleep <-
		?weight(Weight);
		-+weight(0);
		?main(Main);
		.send(Main,achieve,addweight(Weight));
		!wait(added[source(Main)]); 
		!print(sleep);
.	


@ljnbdgfd[atomic]
+!addweight(Share)[source(Source)] <-
	?weight(Weight);
	-+weight(Weight+Share);
	if(Source \== self) {
		.send(Source,tell,added);
	}
	!print(weight(Weight+Share));
.	



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


+!send(Recip,Mode,Message) 
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
		?npersons(Dim);
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

+bid(ABid,APerson)
	<-
	!get_next_token(TokRec);
	if(not bids_processed(TokRec-1)) {
		if(debug) {
			+token_fail_history(rec(TokRec),source(APerson));
		}
		!check(bids_processed(TokRec-1));
	}
	if(debug) {
		?bids_processed(TokProc);
		if(debug) {
			+token_history(proc(TokProc),rec(TokRec),source(APerson));
		}
	}
	
	!check(not lock);				// check that no weight change is in progress
	if(debug) {
		+bid_old(ABid,APerson);
	}
	+lockbids;
	.findall([Bid,Person], bid(Bid,Person), Mbidslist);
	?weight(Weight);
	!print(bids(weight(Weight),aperson(APerson,ABid),Mbidslist));
	if(Mbidslist \== []) {
		.max(Mbidslist,[Maxbid,MaxPerson]);
		.delete([Mmaxbid,MaxPerson],Mbidslist,RestBids);
		if(not assigned(MaxPerson)) {
			?bid(MaxBid,MaxPerson);
			if(assigned(PrevPerson))  {
				!send(PrevPerson,untell,assigned);
				?step(Step);
				if(debug) {
					+untell(Step,prev(PrevPerson),new(MaxPerson));
				}
				!print(send(PrevPerson,untell,assigned(Weight)));
			}
			!update_price(MaxBid);
			-+assigned(MaxPerson);
			?step(Step);
			if(debug) {
				+assigned_person(Step,MaxPerson);
			}
			.send(MaxPerson,tell,assigned);
			!print(assigned(MaxPerson,MaxBid));

		}
		.send(APerson,tell,bid_processed(ABid));
		!print(send(APerson,bid_processed(ABid))); 
	} else {
		.print("no bids: skipping turn");
	}
	-+bids_processed(TokRec);			// release
	-lockbids;
.

@aasdmnllf[atomic]
+bids_processed(A) : bids_received(A)  & A > 0  
	<-
		!sleep;
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


+!update_bid(Bid,Person) <-
	!check(not lockbids);
	.abolish(bid(_,Person));
	+bid(Bid,Person);
.	


+!output <-
	if(assigned(Person)) {
		?main(Main);
		.send(Person,askOne,myclass(PClass),myclass(PClass));
		?myclass(OClass);
		.send(Main,tell,assigned(PClass,OClass));
	}	
.


+!check(A) : A.
+!check(A) <- .wait(10); !check(A).


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

