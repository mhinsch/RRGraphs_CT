


@processes sim world::World begin
	@poisson(sim.par.rate_dep)				~
		true				=>		begin spawn(add_migrant!(world, sim.par), sim); sim end
end


@processes sim agent::Agent begin
	@poisson(sim.par.rate_costs_stay)		~ 
		! agent.in_transit	=>		costs_stay!(agent, sim.par)

	@poisson(sim.par.rate_explore_loc)		~
		! agent.in_transit	=>		explore_stay!(agent, sim.model.world, sim.par)
	
	@poisson(rate_contacts(agent, sim.par))	~
		! agent.in_transit && ! maxed(agent, sim.par)	=> meet_locally!(agent, sim.par)
	
	@poisson(rate_talk(agent, sim.par)) 	~
		! agent.in_transit	=> 		talk_once!(agent, sim.par)

	@poisson(move_rate(agent, sim.par))		~
		! agent.in_transit	=> 		start_move!(agent, sim.model.world, sim.par)
	
	@poisson(transit_rate(agent, sim.par))	~
		agent.in_transit	=> 		finish_move!(agent, sim.model.world, sim.par)
end

	
