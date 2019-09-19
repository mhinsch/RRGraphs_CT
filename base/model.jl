using Util
using Distributions

include("entities.jl")
include("setup.jl")

mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
end

n_arrived(model) = length(model.people) - length(model.migrants)



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
	# the only bit of initial global info so far
	for l in model.world.exits
		if rand() < par.p_know_target
			explore_at!(agent, model.world, l, 0.5, false, par)
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
include("scheduling.jl")
