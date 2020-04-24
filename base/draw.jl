import SSDL


function pos_agent(canvas, agent, scatter)
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

	x, y
end

draw_agent!(canvas, agent, col, scatter) = put(canvas, pos_agent(canvas, agent, scatter)..., col)

function draw_people!(canvas, model)
	for p in model.migrants
		draw_agent!(canvas, p, WHITE, 5)
	end
end

scale(x, xs) = floor(Int, x*xs) + 1

scale(p :: Pos, c :: Canvas) = scale(p.x, xsize(c)), scale(p.y, ysize(c))

function draw_link!(canvas, link, col)
	xs, ys = size(canvas)
	x1, y1 = scale(link.l1.pos.x, xs), scale(link.l1.pos.y, ys)
	x2, y2 = scale(link.l2.pos.x, xs), scale(link.l2.pos.y, ys)
	line(canvas, x1, y1, x2, y2, col)
end

function draw_link_v!(canvas, link, value)
	col :: UInt32 = rgb(value * 255, (1.0-value) * 255, 0)
	draw_link!(canvas, link, col)
end
		

function draw_city!(canvas, city, sz = 1, col = nothing)
	xs, ys = size(canvas)

	x = scale(city.pos.x, xs)
	y = scale(city.pos.y, ys)

	fillRectC(canvas, x-sz, y-sz, 2*sz+1, 2*sz+1, col == nothing ? blue(255) : col)
end


struct prop_scales
	max_f :: Float64
	min_f :: Float64
	max_q :: Float64
	min_q :: Float64
end

function draw_bg!(canvas, model, par)
	w = model.world

	maf = maximum(l -> l.friction/l.distance, model.world.links)
	println("max frict: ", maf)
	mif = minimum(l -> l.friction/l.distance, model.world.links)
	println("min frict: ", mif)

	# draw in reverse so that "by foot" links will be drawn first
	for i in length(model.world.links):-1:1
		link = model.world.links[i]
		frict = (link.friction/link.distance - mif) / (maf - mif)
		draw_link_v!(canvas, link, 1.0 - frict)
	end

	maq = maximum(l -> costs_quality(l, par), model.world.cities)
	println("max qual: ", maq)
	miq = minimum(l -> costs_quality(l, par), model.world.cities)
	println("min qual: ", miq)

	for city in model.world.cities
		val = (costs_quality(city, par) - miq) / (maq - miq)
		col :: UInt32 = rgb(255, (1.0-val) * 255, val * 255)
		draw_city!(canvas, city, 2, col)
	end

	prop_scales(maf, mif, maq, miq)
end


function draw_visitors!(canvas, model)
	w = model.world

	ma = maximum(l -> l.count, model.world.links)
	if ma == 0
		ma = 1
	end

	for link in model.world.links
		val = link.count / ma
		draw_link_v!(canvas, link, 1.0 - val)
	end

	ma = maximum(c -> c.count, model.world.cities)
	if ma == 0
		ma = 1
	end

	for city in model.world.cities
		val :: UInt32 = floor(UInt32, city.count / ma * 200 + 55)
		col :: UInt32 = rgb(val, val, val)
		draw_city!(canvas, city, 2, col)
	end
end


function draw_rand_knowledge!(canvas, model, scales, agent=nothing)
	if length(model.migrants) < 1
		return nothing
	end

	if agent == nothing
		agent = rand(model.migrants)
	end

	for l in agent.info_link
		if known(l) && known(l.l1) && known(l.l2)
#			frict = (discounted(l.friction)/model.world.links[l.id].distance - scales.min_f) / 
#				(scales.max_f - scales.min_f)
			draw_link_v!(canvas, l, limit(0.0, 1.0 - accuracy(l, model.world.links[l.id]), 1.0)) 
		end
	end

	for c in agent.info_loc
		if known(c)
			val = limit(0.0, accuracy(c, model.world.cities[c.id]), 1.0)
			col :: UInt32 = rgb(255, (1.0-val) * 255, val * 255)
			draw_city!(canvas, c, 2, col)
		end
	end

	prev = Unknown
	for c in agent.plan
		draw_city!(canvas, c, 2, WHITE)
		if known(prev)
			draw_link!(canvas, find_link(prev, c), WHITE)
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
				if d == 1
					line(canvas, x, y, xo, yo, rgb(v, 255-v, 0))
				else
					linePat(canvas, x, y, xo, yo, 2, 10, rgb(v, 255-v, 0))
				end
				
				fillRectC(canvas, xo-1, yo-1, 3, 3, rgb(v, 255-v, 0))

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
