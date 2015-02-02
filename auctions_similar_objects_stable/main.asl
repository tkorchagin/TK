object(id(r1),need(7)).
object(id(r2),need(130)).

person(id(t1),exceed(6)).  
person(id(t2),exceed(5)). 
person(id(t3),exceed(10)).
person(id(t4),exceed(12)). 

crosscost(person(t1),object(r1),cost(100)).
crosscost(person(t1),object(r2),cost(2)).
crosscost(person(t2),object(r1),cost(1)).
crosscost(person(t2),object(r2),cost(10)).
crosscost(person(t3),object(r1),cost(50)).
crosscost(person(t3),object(r2),cost(30)).
crosscost(person(t4),object(r1),cost(502)).
crosscost(person(t4),object(r2),cost(1)).


!start.

/*
+!prepare_data <-
	
.*/

+!start <-
	.my_name(MyName);
	.create_agent(tp,"transportation.asl");
	.findall(person(id(Id),exceed(Cap)),
			person(id(Id),exceed(Cap)),Sources);
	.findall(object(id(Id),need(Cap)),
			object(id(Id),need(Cap)),Objects);
	.findall(crosscost(person(Id1),object(Id2),cost(Cost)),
			crosscost(person(Id1),object(Id2),cost(Cost)),	
			Costs);
	.length(Sources,Npersons);
	.length(Objects,Nobjects);
	.length(Costs,Ncosts);
	.send(tp,tell,[npersons(Npersons),
		nobjects(Nobjects),
		ncosts(Ncosts),
		parent(MyName)]);
	.send(tp,tell,Sources);
	.send(tp,tell,Objects);
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
	for(.member(stream(person(Source),object(Object),quantity(Quantity)),
		Streams)) {
		.puts("Assign from person #{Source} to object #{Object} total of #{Quantity} repersons");
	}
	.

