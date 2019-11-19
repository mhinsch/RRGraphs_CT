

@processes sim model::Model begin
	@poisson(sim.par.rate_dep)				~
		true				=>		begin 
				resch = add_migrant!(model, sim.par)
				[model; resch]
			end
end


@processes sim agent::Agent begin
	@poisson(sim.par.rate_costs_stay)		~ 
		! agent.in_transit	=>		costs_stay!(agent, sim.par)

	@poisson(sim.par.rate_explore_loc)		~
		! agent.in_transit	=>		explore_stay!(agent, sim.model.world, sim.par)
	
	@poisson(rate_contacts(agent.loc, sim.par))	~
		! agent.in_transit && ! maxed(agent, sim.par)	=> meet_locally!(agent, sim.model.world, sim.par)
	
	@poisson(rate_talk(agent, sim.par)) 	~
		! agent.in_transit	=> 		talk_once!(agent, sim.model.world, sim.par)

	@poisson(move_rate(agent, sim.par))		~
		! agent.in_transit 	=> 		begin
				agent.loc.move_count += 1
				start_move!(agent, sim.model.world, sim.par)
			end
	
	@poisson(transit_rate(agent, sim.par))	~
		agent.in_transit	=> 		begin
				resch = finish_move!(agent, sim.model.world, sim.par)
				# would be nicer to check for isempty(resch) here,
				# but removing the agent requires going through the entire
				# vector anyway, so let's stick to in-model logic
				if arrived(agent)
					handle_arrivals!(sim.model)
				end

				resch
			end
end

	
