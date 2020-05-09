using Util.Observation
using Util.StatsAccumulator

const MV = MVAcc{Float64}
const MM = MaxMinAcc{Float64}

include("analysis_util.jl")

import Util.Observation.prefixes
prefixes(::Type{<:MV}) = ["mean", "var"]
prefixes(::Type{<:MM}) = ["max", "min"]


Base.show(out::IO, acc :: MM) = print(out, acc.max, "\t", acc.min)
function Base.show(out::IO, acc :: MV)
	res = result(acc)
	print(out, res[1], "\t", res[2])
end

const I = Iterators

@observe log model begin
	# analyse 1000 latest agents to have a arrived
	@for a in I.take(I.filter(ag->arrived(ag), I.reverse(model.people)), 1000) begin
		@stat("cap", 		MV, MM) <| a.capital
		@stat("n_loc", 		MV, MM) <| Float64(a.n_locs)
		@stat("n_link", 	MV, MM) <| Float64(a.n_links)
		@stat("n_contacts", MV, MM) <| Float64(length(a.contacts))
		@stat("n_steps", 	MV, MM) <| Float64(length(a.path))
		@stat("freq_plan", 	MV, MM) <| Float64(a.planned / (length(a.path) + 0.00001))
		@stat("acc_c", 		MV, MM) <| acc_cities_per_agent(a, model.world)
		@stat("acc_l", 		MV, MM) <| acc_links_per_agent(a, model.world)
	end

	# only migrants can have a plan
	@for a in model.migrants begin
		@stat("n_plan", 	MV, MM) <| Float64(length(a.plan))
		@stat("acc_c_m", 	MV, MM) <| acc_cities_per_agent(a, model.world)
		@stat("acc_l_m", 	MV, MM) <| acc_links_per_agent(a, model.world)
		@stat("n_loc_m", 	MV, MM) <| Float64(a.n_locs)
		@stat("n_link_m", 	MV, MM) <| Float64(a.n_links)
	end

	@for ex in model.world.exits begin
		@stat("count", 		MV, MM) <| Float64(ex.count)
		@stat("traffic", 	MV, MM) <| Float64(ex.traffic)
	end

	@for c in model.world.cities begin
		@stat("N",			MV, MM) <| Float64(length(c.people))
	end

	@show "n_migrants"	length(model.migrants)
	@show "n_arrived" 	(length(model.people) - length(model.migrants))
end

# unused
#@observe final_model model begin	
#	# analyse 1000 latest agents to have a arrived
#	@for a in I.take(I.filter(ag->arrived(ag), I.reverse(model.people)), 1000) begin
#		@stat("acc_c", 		MV, MM) <| acc_cities_per_agent(a, model.world)
#		@stat("acc_l", 		MV, MM) <| acc_links_per_agent(a, model.world)
#	end
#end

@observe final_city c begin
	@show "id" 		c.id
	@show "x"		c.pos.x
	@show "y"		c.pos.y
	@show "type"	c.typ
	@show "qual"	c.quality
	@show "N"		length(c.people)
	@show "n_links"	length(c.links)
	@show "count"	c.count
	@show "acc"		acc_cities_per_city(c, args[:agents])
end


@observe final_link l begin
	@show "id" 			l.id
	@show "type"		l.typ
	@show "l1"			l.l1.id
	@show "l2"			l.l2.id
	@show "friction"	l.friction
	@show "count"		l.count
	@show "acc"			acc_links_per_link(l, args[:agents])
end


function prepare_outfiles(logf, cityf, linkf)
	print_header_log(logf)
#	print_header_final_model(modelf)
	print_header_final_city(cityf)
	print_header_final_link(linkf)
end

function analyse_log(model, logf)
	@time print_stats_log(logf, model)
end

function analyse_world(model, cityf, linkf)
#	print_stats_final_model(modelf, model)

	# lazy iterator
	test_agents = I.take(I.filter(ag->arrived(ag), I.reverse(model.people)), 1000)

	for c in model.world.cities
		print_stats_final_city(cityf, c, agents=test_agents) 
	end

	for l in model.world.links
		print_stats_final_link(linkf, l, agents=test_agents)
	end
end

