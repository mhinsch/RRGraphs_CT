using GeoGraph
using Util


function setup_city!(loc, par)
	loc.quality = rand()
	loc.resources = rand()
end


function setup_entry!(loc, par)
	loc.quality = par.qual_entry
	loc.resources = par.res_entry
end


function setup_exit!(loc, par)
	loc.quality = par.qual_exit
	loc.resources = par.res_exit
end


calc_friction(link, par) = link.distance * par.dist_scale[Int(link.typ)]

function setup_link!(link, par)
	link.distance = distance(link.l1, link.l2)
	link.friction = calc_friction(link, par) * (1.0 + rand() * par.frict_range)
	@assert link.friction > 0
end


function add_link!(world, c1, c2, typ, par)
	push!(world.links, Link(length(world.links)+1, typ, c1, c2))
	push!(c1.links, world.links[end])
	push!(c2.links, world.links[end])
	setup_link!(world.links[end], par)
end


function add_cities!(world, par)
	nodes, links = create_random_geo_graph(par.n_cities, par.link_thresh)

	# cities
	for n in nodes
		push!(world.cities, Location(Pos(n...), STD, length(world.cities)+1))
		setup_city!(world.cities[end], par)
	end

	for (i, j) in links
		add_link!(world, world.cities[i], world.cities[j], FAST, par)
	end
end

sq_dist(l1, l2) = (l1.x-l2.x)^2 + (l1.y-l2.y)^2

function add_entries!(world, par)
	print("entries: ")

	cities = copy(world.cities)

	for i in 1:par.n_entries
		y = rand()
		x = 0
		push!(world.entries, Location(Pos(x, y), ENTRY, length(world.cities)+1))
		n_entry = world.entries[end]
		setup_entry!(n_entry, par)
		# entries are linked to every city that's close enough (but badly)
		for c in world.cities
			if c.typ != ENTRY && c.pos.x < par.entry_dist
				add_link!(world, c, n_entry, SLOW, par)
			end
		end

		# sort by distance to entry
		sort!(cities, lt=(l1,l2)->sq_dist(n_entry.pos, l1.pos) < sq_dist(n_entry.pos, l2.pos))
		# connect the n nearest
		for j in 1:par.n_nearest_entry
			add_link!(world, cities[j], n_entry, FAST, par)
		end

		push!(world.cities, world.entries[end])
		print(length(world.cities), " ")
	end
	println()
end

		
function add_exits!(world, par)
	print("exits: ")

	cities = copy(world.cities)

	for i in 1:par.n_exits
		y = rand()
		x = 0.99 
		push!(world.exits, Location(Pos(x, y), EXIT, length(world.cities)+1))
		n_exit = world.exits[end]
		setup_exit!(n_exit, par)
		# exits are linked to every city that's close enough (but badly)
		for c in world.cities
			if c.typ != EXIT && c.pos.x > par.exit_dist
				add_link!(world, c, n_exit, SLOW, par)
			end
		end
		# sort by distance to exit
		sort!(cities, lt=(l1,l2)->sq_dist(n_exit.pos, l1.pos) < sq_dist(n_exit.pos, l2.pos))
		# connect the n nearest
		for j in 1:par.n_nearest_exit
			add_link!(world, cities[j], n_exit, FAST, par)
		end

		push!(world.cities, world.exits[end])
		print(length(world.cities), " ")
	end
	println()
end

		


function create_world(par)
	world = World()
	add_cities!(world, par)
	add_entries!(world, par)
	add_exits!(world, par)

	world
end
