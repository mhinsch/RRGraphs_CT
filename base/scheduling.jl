

@processes sim model::Model begin
	@poisson(sim.par.rate_dep)				~
		true				=>		begin spawn(add_migrant!(model, sim.par), sim); model end

	@poisson(1.0)							~
		true				=> 		handle_arrivals!(model)
end


@processes sim agent::Agent begin
	@poisson(sim.par.rate_costs_stay)		~ 
		! agent.in_transit	=>		costs_stay!(agent, sim.par)

	@poisson(sim.par.rate_explore_loc)		~
		! agent.in_transit	=>		explore_stay!(agent, sim.model.world, sim.par)
	
	@poisson(rate_contacts(agent, sim.par))	~
		! agent.in_transit && ! maxed(agent, sim.par)	=> meet_locally!(agent, sim.model.world, sim.par)
	
	@poisson(rate_talk(agent, sim.par)) 	~
		! agent.in_transit	=> 		talk_once!(agent, sim.model.world, sim.par)

	@poisson(move_rate(agent, sim.par))		~
		! agent.in_transit	=> 		start_move!(agent, sim.model.world, sim.par)
	
	@poisson(transit_rate(agent, sim.par))	~
		agent.in_transit	=> 		finish_move!(agent, sim.model.world, sim.par)
end

	
