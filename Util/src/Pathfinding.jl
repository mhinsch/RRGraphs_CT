module Pathfinding

export path_Astar, path_costs, path_costs_estimate, each_neighbour


using DataStructures


# match either object == object or object in container depending on type
@generated matches(current, target) = current == target ? :(current == target) : :(current in target)


"Find the least-cost path from `start` to `target` using cost function
`path_costs` and cost heuristic function `path_costs_estimate`. An iterator
function to find a nodes' neighbours has to be provided in `each_neighbour`.
Returns a vector `start`, node, ..., `target` and the number of iterations used
to find the path in a tuple."
function path_Astar(start, target, path_costs, path_costs_estimate, each_neighbour)
	done = Set{typeof(start)}()

	known = PriorityQueue{typeof(start), Float64}()
	known[start] = path_costs_estimate(start, target)

	previous = Dict{typeof(start), typeof(start)}()

	costs_sofar = Dict(start => 0.0)

	count = 0

	current = start
	found = false

	while length(known) > 0
		# get the next node with the least (estimated) cost
		current = dequeue!(known)

		# we are already there
		if matches(current, target)
			found = true
			break
		end

		# no need to check the current one again
		push!(done, current)

		# check all connected nodes
		for c in each_neighbour(current)
			# checked this one already
			if c in done
				continue
			end

			count += 1

			costs_thisway = costs_sofar[current] + path_costs(current, c)

			# we might already know a shortcut to c
			if haskey(costs_sofar, c) && costs_thisway > costs_sofar[c]
				# no need to explore further since this path is obviously worse
				continue
			end

			costs_sofar[c] = costs_thisway

			# our best estimate for this path
			known[c] = costs_thisway + path_costs_estimate(c, target)

			previous[c] = current
		end
	end

	path = Vector{typeof(start)}()

	if ! found
		return path, count
	end

	n = current # == found target

	while true
		push!(path, n)
		if haskey(previous, n)
			n = previous[n]
		else
			break
		end
	end

	path, count
end	


end
