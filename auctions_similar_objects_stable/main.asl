part(id(r1),need(12)).
part(id(r2),need(1)).

team(id(t1)).  
team(id(t2)). 
team(id(t3)).
team(id(t4)). 

team_part_cost(team(t1),part(r1),cost(650)).
team_part_cost(team(t1),part(r2),cost(2)).
team_part_cost(team(t2),part(r1),cost(1)).
team_part_cost(team(t2),part(r2),cost(10)).
team_part_cost(team(t3),part(r1),cost(50)).
team_part_cost(team(t3),part(r2),cost(30)).
team_part_cost(team(t4),part(r1),cost(502)).
team_part_cost(team(t4),part(r2),cost(1)).



!start.

/*
+!prepare_data <-
	
.*/

+!start <-
	.my_name(MyName);
	.create_agent(tp,"transportation.asl");
	.findall(team(id(Id)),
			team(id(Id)),Sources);
	.findall(part(id(Id),need(Cap)),
			part(id(Id),need(Cap)),Sinks);
	.findall(team_part_cost(team(Id1),part(Id2),cost(Cost)),
			team_part_cost(team(Id1),part(Id2),cost(Cost)),	
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

+parts(Parts)
	<-
	for(.member(part(id(PartID),TeamsList), Parts)) {
		.puts("To part #{PartID} assign teams: #{TeamsList}.");
	}
	.
