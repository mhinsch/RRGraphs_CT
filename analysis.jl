using Util.Observation
using Util.StatsAccumulator


const MV = MVAcc{Float64}
const MM = MaxMinAcc{Float64}


import Util.Observation.prefixes
prefixes(::Type{<:MV}) = ["mean", "var"]
prefixes(::Type{<:MM}) = ["max", "min"]


import Base.print
print(out::IO, acc :: MM, sep) = print(out, acc.max, sep, acc.min)
function print(out::IO, acc :: MV, sep)
	res = result(acc)
	print(out, res[1], sep, res[2])
end


@observe log model begin
	@for a in model.migrants begin
		@stat("cap", 		MV, MM) <| a.capital
		@stat("n_loc", 		MV, MM) <| Float64(a.n_locs)
		@stat("n_link", 	MV, MM) <| Float64(a.n_links)
		@stat("n_plan", 	MV, MM) <| Float64(length(a.plan))
		@stat("n_contacts", MV, MM) <| Float64(length(a.contacts))
		@stat("n_steps", 	MV, MM) <| Float64(a.steps)
		@stat("freq_plan", 	MV, MM) <| Float64(a.planned / (a.steps + 0.00001))
	end

	@for ex in model.world.exits begin
		@stat("count", 		MV, MM) <| Float64(ex.count)
		@stat("traffic", 	MV, MM) <| Float64(ex.traffic)
	end

	@show "n_migrants"	length(model.migrants)
	@show "n_arrived" 	(length(model.people) - length(model.migrants))
end


@observe final_city c begin
	@show "id" 		c.id
	@show "x"		c.pos.x
	@show "y"		c.pos.y
	@show "type"	c.typ
	@show "qual"	c.quality
	@show "N"		length(c.people)
	@show "n_links"	length(c.links)
	@show "count"	c.count
end


@observe final_link l begin
	@show "id" 			l.id
	@show "type"		l.typ
	@show "l1"			l.l1.id
	@show "l2"			l.l2.id
	@show "friction"	l.friction
	@show "count"		l.count
end


function prepare_outfiles(logf, cityf, linkf)
	print_header_log(logf)
	print_header_final_city(cityf)
	print_header_final_link(linkf)
end

function analyse_log(model, logf)
	print_stats_log(logf, model)
end

function analyse_world(model, cityf, linkf)
	for c in model.world.cities
		print_stats_final_city(cityf, c)
	end

	for l in model.world.links
		print_stats_final_link(linkf, l)
	end
end

