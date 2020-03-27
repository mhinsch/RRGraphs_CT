import SSDL


function draw_agent!(canvas, agent, col, scatter)
	xs = xsize(canvas)
	ys = ysize(canvas)
	if ! in_transit(agent)
		x = scale(agent.loc.pos.x, xs) + rand(-scatter:scatter)
		x = limit(1, x, xs)
		y = scale(agent.loc.pos.y, ys) + rand(-scatter:scatter)
		y = limit(1, y, ys)
	else
		next = agent.plan[end]
		x = scale((agent.loc.pos.x + next.pos.x)/2, xs) + rand(-scatter:scatter)
		x = limit(1, x, xs)
		y = scale((agent.loc.pos.y + next.pos.y)/2, ys) + rand(-scatter:scatter)
		y = limit(1, y, ys)
	end

	put(canvas, x, y, col)
end

function draw_people!(canvas, model)
	for p in model.migrants
		draw_agent!(canvas, p, WHITE, 5)
	end
end

scale(x, xs) = floor(Int, x*xs) + 1

scale(p :: Pos, c :: Canvas) = scale(p.x, xsize(c)), scale(p.y, ysize(c))

function draw_link!(canvas, link, value)
	xs, ys = size(canvas)
	x1, y1 = scale(link.l1.pos.x, xs), scale(link.l1.pos.y, ys)
	x2, y2 = scale(link.l2.pos.x, xs), scale(link.l2.pos.y, ys)
	col :: UInt32 = rgb(value * 255, (1.0-value) * 255, 0)
	line(canvas, x1, y1, x2, y2, col)
end
		

function draw_city!(canvas, city, col = nothing)
	xs, ys = size(canvas)

	x = scale(city.pos.x, xs)
	y = scale(city.pos.y, ys)

	xmi = max(1, x-1)
	xma = min(xs, x+1)
	ymi = max(1, y-1)
	yma = min(ys, y+1)

	for x in xmi:xma, y in ymi:yma
		put(canvas, x, y, col == nothing ? blue(255) : col)
	end
end


function draw_bg!(canvas, model)
	w = model.world

	# draw in reverse so that "by foot" links will be drawn first
	for i in length(model.world.links):-1:1
		link = model.world.links[i]
		frict = link.friction / link.distance / 15
		draw_link!(canvas, link, frict)
	end

	for city in model.world.cities
		draw_city!(canvas, city)
	end
end


function draw_visitors!(canvas, model)
	w = model.world

	sum = 0
	ma = 0
	for link in model.world.links
		sum += link.count
		ma = max(ma, link.count)
	end

	if ma == 0
		ma = 1
	end

	for link in model.world.links
		val = link.count / ma
		draw_link!(canvas, link, 0.5 - val/2)
	end

	sum = 0
	ma = 0
	for city in model.world.cities
		sum += city.traffic
		ma = max(ma, city.traffic)
	end

	if ma == 0
		ma = 1
	end

	for city in model.world.cities
		col :: UInt32 = rgb(min(255.0, city.traffic*50), 0, 0)
		draw_city!(canvas, city, col)
	end
end


function draw_rand_knowledge!(canvas, model, agent=nothing)
	if length(model.migrants) < 1
		return nothing
	end

	if agent == nothing
		agent = rand(model.migrants)
	end

	for l in agent.info_link
		if known(l) && known(l.l1) && known(l.l2)
			draw_link!(canvas, l, 0.0)
		end
	end

	for c in agent.info_loc
		if known(c)
			draw_city!(canvas, c)
		end
	end

	prev = Unknown
	for c in agent.plan
		draw_city!(canvas, c, red(255))
		if known(prev)
			draw_link!(canvas, find_link(prev, c), 1.0)
		end
		prev = c
	end

	draw_agent!(canvas, agent, WHITE, 1)

	agent
end


function draw_rand_social!(canvas, model, depth=1, agent=nothing)
	if length(model.migrants) < 1
		return nothing
	end

	if agent == nothing
		agent = rand(model.migrants)
	end

	todo = Vector{typeof(agent)}()
	next = Vector{typeof(agent)}()
	done = Set{typeof(agent)}()

	push!(next, agent)


	for d in 1:depth
		todo, next = next, todo
		resize!(next, 0)

		v = floor(Int, d / depth * 255)

		for a in todo
			x, y = scale(a.loc.pos, canvas)

			for o in a.contacts
				if o in done
					continue
				end
				xo, yo = scale(o.loc.pos, canvas)
				line(canvas, x, y, xo, yo, rgb(v, 255-v, 0))
				push!(done, o)

				if d < depth
					for o2 in o.contacts
						if ! (o2 in done)
							push!(next, o2)
						end
					end
				end
			end
		end
	end

	agent
end
