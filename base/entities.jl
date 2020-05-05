using Util
using Beliefs

include("world_util.jl")


# a piece of knowledge an agent has about a location
mutable struct InfoLocationT{L}
	pos :: Pos
	id :: Int
	# property values the agent expects
	resources :: TrustedF
	quality :: TrustedF

	links :: Vector{L}
end

mutable struct InfoLink
	id :: Int
	l1 :: InfoLocationT{InfoLink}
	l2 :: InfoLocationT{InfoLink}
	friction :: TrustedF
end

const InfoLocation = InfoLocationT{InfoLink}

const Unknown = InfoLocation(Nowhere, 0, TrustedF(0.0), TrustedF(0.0), [])
const UnknownLink = InfoLink(0, Unknown, Unknown, TrustedF(0.0))


#resources(l :: InfoLocation) = l.resources.value
#quality(l :: InfoLocation) = l.quality.value
friction(l :: InfoLink) = l.friction.value


otherside(link, loc) = loc == link.l1 ? link.l2 : link.l1

# no check for validity etc.
add_link!(loc, link) = push!(loc.links, link)


# migrants
mutable struct AgentT{LOC, LINK}
	# current real position
	loc :: LOC
	link :: LINK
	# what it thinks it knows about the world
	n_locs :: Int
	info_loc :: Vector{InfoLocation}
	info_target :: Vector{InfoLocation}
	n_links :: Int
	info_link :: Vector{InfoLink}
	plan :: Vector{InfoLocation}
	path :: Vector{LOC}
	out_of_date :: Float64
	# abstract capital, includes time & money
	capital :: Float64
	# people at home & in target country, other migrants
	contacts :: Vector{AgentT{LOC, LINK}}
	planned :: Int
end

knows_target(agent) = length(agent.info_target) > 0 
target(agent) = knows_target(agent) ? agent.info_target[1] : Unknown

arrived(agent) = agent.loc.typ == EXIT


function add_info!(agent, info :: InfoLocation, typ = STD) 
	@assert agent.info_loc[info.id] == Unknown
	agent.n_locs += 1
	agent.info_loc[info.id] = info
	if typ == EXIT
		push!(agent.info_target, info)
	end
end

function add_info!(agent, info :: InfoLink) 
	@assert agent.info_link[info.id] == UnknownLink
	agent.n_links += 1
	agent.info_link[info.id] = info
end

function add_contact!(agent, a)
	if a in agent.contacts
		return
	end

	push!(agent.contacts, a)
end


@enum LOC_TYPE STD=1 ENTRY EXIT

mutable struct LocationT{L}
	id :: Int
	typ :: LOC_TYPE
	resources :: Float64
	quality :: Float64
	people :: Vector{AgentT{LocationT{L}}}

	links :: Vector{L}

	pos :: Pos

	count :: Int
	cur_count :: Int
	traffic :: Float64
end


distance(l1, l2) = distance(l1.pos, l2.pos)

@enum LINK_TYPE FAST=1 SLOW

mutable struct Link
	id :: Int
	typ :: LINK_TYPE
	l1 :: LocationT{Link}
	l2 :: LocationT{Link}
	friction :: Float64
	distance :: Float64
	count :: Int
end


Link(id, t, l1, l2) = Link(id, t, l1, l2, 0, 0, 0)

const Location = LocationT{Link}
Location(p :: Pos, t, i) = Location(i, t, 0.0, 0.0, [], Link[], p, 0, 0, 0.0)
const NoLoc = Location(Nowhere, STD, 0)

const NoLink = Link(0, FAST, NoLoc, NoLoc)

const Agent = AgentT{Location, Link}

Agent(loc::Location, c :: Float64) = Agent(loc, NoLink, 0, [], [], 0, [], [], [loc], 1.0, c, [], 0)

in_transit(a :: Agent) = a.link != NoLink
set_transit!(a :: Agent, l :: Link) = a.link = l
function end_transit!(a :: Agent, l :: Location)
	a.link = NoLink
	a.loc = l
	push!(a.path, a.loc)
end


# get the agent's info on a location
info(agent, l::Location) = agent.info_loc[l.id]
# get the agent's info on its current location
info_current(agent) = info(agent, agent.loc)
# get the agent's info on a link
info(agent, l::Link) = agent.info_link[l.id]

known(l::InfoLocation) = l != Unknown
known(l::InfoLink) = l != UnknownLink

# get the agent's info on a location
knows(agent, l::Location) = known(info(agent, l))
# get the agent's info on a link
knows(agent, l::Link) = known(info(agent, l))

function find_link(from, to)
	for l in from.links
		if otherside(l, from) == to
			return l
		end
	end

	nothing
end


mutable struct World
	cities :: Vector{Location}
	links :: Vector{Link}
	entries :: Vector{Location}
	exits :: Vector{Location}
end

World() = World([], [], [], [])



remove_agent!(loc::Location, agent::Agent) = drop!(loc.people, agent)


function add_agent!(loc::Location, agent::Agent) 
	push!(loc.people, agent)
	loc.count += 1
	loc.cur_count += 1
end


remove_agent!(world, agent) = remove_agent!(agent.loc, agent)


function move!(world, agent, loc)
	remove_agent!(world, agent)
	agent.loc = loc
	add_agent!(loc, agent)
end


info2real(l::InfoLocation, world) = world.cities[l.id]
info2real(l::InfoLink, world) = world.links[l.id]

dist_eucl(x1, y1, x2, y2) = sqrt((x2-x1)^2 + (y2-y1)^2)

# TODO: should accuracy be discounted by trust value?

accuracy(li::InfoLocation, lr::Location) = 
	1.0 - dist_eucl(li.quality.value, li.resources.value, lr.quality, lr.resources)

accuracy(li::InfoLink, lr::Link) = 1.0 - abs(li.friction.value - lr.friction)/lr.distance
