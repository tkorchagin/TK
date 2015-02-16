//opdebug.
adebug.

freesend.
freeadd.
inf(1000000).

check_timeout(5000).

prices_processed(0).
prices_received(0).



step(0).
localmaxstep(10).

weight(0).


//@wsrlbfjw[atomic]
+util(Object,Util) : nobjects(N) & .count(util(_,_),N)
		<- 
		.findall(U,util(P,U),Utils);
		.max(Utils,Profit);
		?util(MaxObject,Profit);
		+profit(Profit);
		+profitObject(MaxObject);
		!check(main(Main));
		.send(Main,tell,person_end);
.



+!set_util(Object,Util) <-
	+util(Object,Util).

+!set_objects(Objects) <-
	-+objects(Objects);
	!check(main(Main));
	.send(Main,tell,person_end);
.
	




@sdfklnvdfls[atomic]
+!sleep <-
	?weight(Weight);
	-+weight(0);
	?main(Main);
	.send(Main,achieve,addweight(Weight));
	!wait(added[source(Main)]); 
.	





@ljnbdgfd[atomic]
+!addweight(Share)[source(Source)] <-
	?weight(Weight);
	-+weight(Weight+Share);
	.send(Source,tell,added);
	if(adebug) {
		+sent_add(system.time,Source);
	}
	!print(weight(Weight+Share));
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



		
@esdfdsswnefs90[atomic]
+!sent_handle(N,Recip) <- 
		?weight(Weight);
		?nobjects(Dim);
		Share = Weight / (N+Dim);
		.send(Recip,achieve,addweight(Share));	// share the weight with recipients
		!addweight(-N*Share);
.




+!start <- 
	!check(main(Main));
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
	!check(prices_processed(TokRec-1)); 
	!run(TokRec);
	-+prices_processed(TokRec);			// release
.
	
+!getshare <-
	?main(Main);
	.send(Main,askOne,share_weight(Share),share_weight(Share));
	.abolish(share_added);
	!addweight(Share);
	!wait(added[source(self)]);
.

+!run(Id): not assigned  <-
	.my_name(Name);
	?main(Main);
	!check(price(_,_,_));
	?step(Step);
	if(debug) {
		.findall(price(Price,Object,Class),price(Price,Object,Class),Prices);
		!print(p(step(Step),prices(Prices)));
	}
	.findall(profit(Util-Price,Object,Class),price(Price,Object,Class)
				& util(Object,Util),Profits);
	if(Profits == []) {
		!stop("something's wrong: no prices");
	} else {
		if(debug) {
			+profits(step(Step),profits(Profits));
		}
		.max(Profits,profit(Profit,BidObject,BidClass));
		.findall(profit(AProfit,AObject,AClass),
			.member(profit(AProfit,AObject,AClass),Profits) 
			& AClass \== BidClass, Rest);
		//.difference(Profits,OwnClassProfits,Rest);
		if(debug) {
			+profits_rest(step(Step),profits_rest(Rest));
		}
		?epsilon(Eps);
		if(Rest == []) {
			?inf(Inf);
			NextProfit = - Inf;
		} else {
			.max(Rest,profit(NextProfit,_,_));
		}
		?util(BidObject,BidUtil);
		Bid = BidUtil - NextProfit + Eps;
		if(debug) {
						//!check(price(BidPrice,BidObject,_));
						!print(o(step(Step),
							profit(Profit),
							util(BidUtil),
							next(NextProfit),
							object(BidObject),
							//price(BidPrice),
							bid(Bid)));
						+bids(step(Step),
							profit(Profit),
							util(BidUtil),
							next(NextProfit),
							object(BidObject),
							//price(BidPrice),
							bid(Bid));
		}
		!send(BidObject,achieve,update_bid(Bid,Name));
		if(debug) {
			+send_bid(step(Step),BidObject,Bid);
		}
		!wait(bid_processed(Bid)[source(BidObject)]);
		if(not debug) {
			-bid_processed(Bid)[source(BidObject)];
		}
		-+profit(Profit);
		-+profitObject(BidObject);
	};
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

-assigned[source(Object)]<- 
		!put_into_queue(Object);
.



@sdfdsf[atomic]
+!iterate_step 
	<-
	?step(Step);
	-+step(Step+1);
.	


+?actual_utility(Util,Cost,Steps) : assigned[source(Object)]
	<-	
		?util(Object,Util);
		?cost(Object,Cost);
		?step(Steps).
	
+?actual_utility(0,0,Steps) <- ?step(Steps).

+!check(A) : A <- -timing(A,_).
+!check(A) <- 
	if(timing(A,StartTime)) {
		?check_timeout(ChTO);
		(system.time - StartTime) < ChTO;
	} else {
		+timing(A,system.time);
	}
	.wait(10); 
	!check(A).

-!check(A) <-
	.concat("Check of ",A," has failed",Message);
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

