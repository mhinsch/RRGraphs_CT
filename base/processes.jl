

@processes RRGraph sim model::Model begin
	@poisson(rate_dep(time_now(scheduler(sim)), sim.par))	~
		true				=>		
			begin 
				resch = add_migrant!(model, sim.par)
				[model; resch]
			end
end


@processes RRGraph sim agent::Agent begin
	@poisson(sim.par.rate_costs_stay)		~ 
		! in_transit(agent)					=>		
			costs_stay!(agent, sim.par)

	@poisson(rate_plan(agent, sim.par))		~
		! in_transit(agent)					=>
			plan_costs!(agent, sim.par)

	@poisson(sim.par.rate_explore_stay)		~
		! in_transit(agent)					=>		
			explore_stay!(agent, sim.model.world, sim.par)
	
	@poisson(rate_contacts(agent, sim.par))	~
		! in_transit(agent) && ! maxed(agent, sim.par)	=> 
			meet_locally!(agent, sim.model.world, sim.par)
	
	@poisson(rate_drop_contacts(agent, sim.par)) 	~
		true								=> 		
			drop_contact!(agent, sim.par)

	@poisson(rate_talk(agent, sim.par)) 	~
		true								=> 		
			talk_once!(agent, sim.model.world, sim.par)

	@poisson(rate_move(agent, sim.par))		~
		! in_transit(agent) && ! isempty(agent.plan)	=> 		
			begin
				#agent.loc.move_count += 1
				start_move!(agent, sim.model.world, sim.par)
			end
	
	@poisson(rate_transit(agent, sim.par))	~
		in_transit(agent)					=> 		
			begin
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

	
