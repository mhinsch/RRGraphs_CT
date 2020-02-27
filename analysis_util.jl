
function acc_cities_per_agent(agent, world)
	n_cities = length(world.cities)
	
	acc_c = 0.0
	n_c = 0
	for i in 1:n_cities
		if agent.info_loc[i] != Unknown
			acc_c += accuracy(agent.info_loc[i], world.cities[i])
			n_c += 1
		end
	end

	if n_c > 0
		acc_c /= n_c
	end

	acc_c
end

function acc_links_per_agent(agent, world)
	n_links = length(world.links)
	n_l = 0
	acc_l = 0.0
	for i in 1:n_links
		if agent.info_link[i] != UnknownLink
			acc_l += accuracy(agent.info_link[i], world.links[i])
			n_l += 1
		end
	end

	if n_l > 0
		acc_l /= n_l
	end

	acc_l
end


function accuracy(agents, world)
	n_cities = length(world.cities)

	n_c = 0
	acc_c = 0.0
	for i in 1:n_cities
		n = 0
		acc = 0.0
		for agent in agents
			if agent.info_loc[i] != Unknown
				acc += accuracy(agent.info_loc[i], world.cities[i])
				n += 1
			end
		end
		if n > 0
			acc_c += acc / n
		end

		n_c += n
	end

	acc_c /= n_cities

	n_links = length(world.links)

	n_l = 0
	acc_l = 0.0
	for i in 1:n_links
		n = 0
		acc = 0.0
		for agent in agents
			if agent.info_link[i] != UnknownLink
				acc += accuracy(agent.info_link[i], world.links[i])
				n += 1
			end
		end
		if n > 0
			acc_l += acc / n
		end

		n_l += n
	end

	acc_l /= n_links

	acc_c, n_c, acc_l, n_l
end
