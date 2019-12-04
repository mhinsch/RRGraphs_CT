using SimpleAgentEvents
using SimpleAgentEvents.Scheduler

include("model.jl")


struct Simulation{PAR}
	scheduler :: PQScheduler{Float64}
	model :: Model
	par :: PAR
end

scheduler(sim :: Simulation{PAR}) where {PAR} = sim.scheduler

Simulation(model, par) = Simulation(PQScheduler{Float64}(), model, par)

start(sim::Simulation) = spawn_RRGraph(sim.model, sim)
