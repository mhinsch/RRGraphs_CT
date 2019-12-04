using Random

push!(LOAD_PATH, pwd())

include("base/simulation.jl")
include("base/args.jl")


function str_to_argv(str)
	str = replace(str, "\"" => "")
	split(str)
end


function basic_setup(argv = [])
	if length(argv) > 0
		arg_settings = ArgParseSettings("run simulation", autofix_names=true)

		add_arg_group(arg_settings, "simulation parameters")
		fields_as_args!(arg_settings, Params)

		args = parse_args(argv, arg_settings, as_symbols=true)
		p::Params = create_from_args(args, Params)
	else
		p = Params()
	end

	Random.seed!(p.rand_seed_world)
	w = create_world(p);

	Random.seed!(p.rand_seed_sim)
	m = Model(w, Agent[], Agent[]);

	sim = Simulation(m, p)
	
	p, sim
end
