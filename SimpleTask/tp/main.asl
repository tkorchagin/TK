
source(id(t1),exceed(10)). sink(id(r1),need(100)). 
source(id(t2),exceed(20)). sink(id(r2),need(100)).
source(id(t3),exceed(2)). 

crosscost(source(t1),sink(r1),cost(10)).
crosscost(source(t1),sink(r2),cost(40)).
crosscost(source(t2),sink(r1),cost(20)).
crosscost(source(t2),sink(r2),cost(0)).
crosscost(source(t3),sink(r1),cost(10)).
crosscost(source(t3),sink(r2),cost(3)).



!start.


+!start <-
	.my_name(MyName);
	+start_time(system.time);
	.create_agent(tp,"tp/transportation.asl");
	.findall(source(id(Id),exceed(Cap)),
			source(id(Id),exceed(Cap)),Sources);
	.findall(sink(id(Id),need(Cap)),
			sink(id(Id),need(Cap)),Sinks);
	.findall(crosscost(source(Id1),sink(Id2),cost(Cost)),
			crosscost(source(Id1),sink(Id2),cost(Cost)),	
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

+transportation_streams(Streams)
	<-
	for(.member(stream(source(Source),sink(Sink),quantity(Quantity)),
		Streams)) {
		.puts("Assign from source #{Source} to sink #{Sink} total of #{Quantity} resources");
	}
	?start_time(ST);
	.print("calculation time: ",(system.time-ST)/1000," s");
.

