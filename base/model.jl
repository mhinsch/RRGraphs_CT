using Util
using Distributions
using Random

include("entities.jl")
include("setup.jl")

mutable struct Model
	world :: World
	prior_cities :: Vector{Location}
	prior_links :: Vector{Link}
	people :: Vector{Agent}
	migrants :: Vector{Agent}
end

function setup_model(par)
	Random.seed!(par.rand_seed_world)
	world = create_world(par)

	m = Model(world, Location[], Link[], Agent[], Agent[])

	for c in world.cities
		if rand() < par.p_unknown_city
			continue
		end
		push!(m.prior_cities, c)
	end

	for l in world.links
		if rand() < par.p_unknown_link
			continue
		end
		push!(m.prior_links, l)
	end

	# TODO: this is ugly
	Random.seed!(par.rand_seed_sim)

	m
end


n_arrived(model) = length(model.people) - length(model.migrants)

rate_dep(t, par) = min(t / par.dep_warmup, 1.0) * par.rate_dep + 1.0

# TODO this could be way more sophisticated
#function step_city!(c, step, par)
#	c.traffic = c.traffic * par.ret_traffic + c.cur_count * (1.0 - par.ret_traffic)
#	c.cur_count = 0
#end


# *** entry/exit


function add_migrant!(model::Model, par)
	x = 1
	entry = rand(model.world.entries)
	# starts as in transit => will explore in first step
	agent = Agent(entry, par.ini_capital)
	agent.info_loc = fill(Unknown, length(model.world.cities))
	agent.info_link = fill(UnknownLink, length(model.world.links))
	# explore once
	explore_stay!(agent, model.world, par)

	# add initial contacts
	# (might have duplicates)
	nc = min(length(model.people) ÷ 10, par.n_ini_contacts)
	for c in 1:nc
		push!(agent.contacts, model.people[rand(1:length(model.people))])
	end

	# some exits are known
	for c in model.world.exits
		if rand() < par.p_know_target
			explore_at!(agent, model.world, c, par.speed_expl_ini, false, par)
		end
	end

	for c in model.prior_cities
		if rand() < par.p_know_city
			explore_at!(agent, model.world, c, par.speed_expl_ini, false, par)
		end
	end

	for l in model.prior_links
		if (knows(agent, l.l1) || knows(agent, l.l2)) && rand() < par.p_know_link
			explore_at!(agent, model.world, l, (knows(agent, l.l1) ? l.l1 : l.l2), 
				par.speed_expl_ini, par)
		end
	end


	add_agent!(entry, agent)
	push!(model.people, agent)
	push!(model.migrants, agent)

	agent
end


# all agents at target get removed from world (but remain in network)
function handle_arrivals!(model::Model)
	for i in length(model.migrants):-1:1
		if arrived(model.migrants[i])
			agent = model.migrants[i]
			drop_at!(model.migrants, i)
			remove_agent!(model.world, agent)
		end
	end

	model
end


include("model_agents.jl")
include("processes.jl")
