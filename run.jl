#!/usr/bin/env julia

using Random

push!(LOAD_PATH, pwd())

include("analysis.jl")
include("base/simulation.jl")
include("base/args.jl")


function run(p, stop, log_file)
	Random.seed!(p.rand_seed_world)
	w = create_world(p);

	Random.seed!(p.rand_seed_sim)
	m = Model(w, Agent[], Agent[]);

	sim = Simulation(m, p)

	t = 0.0
	start(sim)
	while t < stop
		upto!(sim.scheduler, t + 1.0)
		t += 1.0
		analyse_log(sim.model, log_file)
		println(t, " ", time_now(sim.scheduler))
		flush(stdout)
	end

	sim
end


include(get_parfile())
	

const arg_settings = ArgParseSettings("run simulation", autofix_names=true)

@add_arg_table! arg_settings begin
	"--stop-time", "-t"
		help = "at which time to stop the simulation" 
		arg_type = Float64
		default = 50.0
	"--par-file", "-p"
		help = "file name for parameter output"
		default = "params.txt"
#	"--model-file"
#		help = "file name for model data output"
#		default = "data.txt"
	"--city-file"
		help = "file name for city data output"
		default = "cities.txt"
	"--link-file"
		help = "file name for link data output"
		default = "links.txt"
	"--log-file", "-l"
		help = "file name for log"
		default = "log.txt"
end

add_arg_group!(arg_settings, "simulation parameters")
fields_as_args!(arg_settings, Params)

const args = parse_args(arg_settings, as_symbols=true)
const p = create_from_args(args, Params)


save_params(args[:par_file], p)


const t_stop = args[:stop_time] 

const logf = open(args[:log_file], "w")
#const modelf = open(args[:model_file], "w")
const cityf = open(args[:city_file], "w")
const linkf = open(args[:link_file], "w")

prepare_outfiles(logf, cityf, linkf)
const sim = run(p, t_stop, logf)

analyse_world(sim.model, cityf, linkf)

close(logf)
#close(modelf)
close(cityf)
close(linkf)
