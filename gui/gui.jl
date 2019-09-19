using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

import SimpleDirectMediaLayer.LoadBMP


function setup_window(wx, wy)
	SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
	SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)

	SDL2.init()

	win = SDL2.CreateWindow("Routes & Rumours", Int32(0), Int32(0), Int32(wx), Int32(wy), 
		UInt32(SDL2.WINDOW_SHOWN))
	SDL2.SetWindowResizable(win,false)

	surface = SDL2.GetWindowSurface(win)

	SDL2.CreateRenderer(win, Int32(-1), UInt32(SDL2.RENDERER_ACCELERATED))
end


struct Panel
	rect :: SDL2.Rect
	texture
	renderer
end

function Panel(renderer, size, offs_x, offs_y)
	Panel(
		SDL2.Rect(offs_x, offs_y, size, size),
		SDL2.CreateTexture(renderer, SDL2.PIXELFORMAT_ARGB8888, 
			Int32(SDL2.TEXTUREACCESS_STREAMING), Int32(size), Int32(size)),
		renderer
	)
end


function update!(p :: Panel, buf)
	SDL2.UpdateTexture(p.texture, C_NULL, buf, Int32(p.rect.w * 4))
end


function render(p :: Panel)
	SDL2.RenderCopy(p.renderer, p.texture, C_NULL, pointer_from_objref(p.rect))
end


const panel_size = 512

const win_size = 2 * panel_size

const renderer = setup_window(win_size, win_size)

const top_left = Panel(renderer, panel_size, 0, 0)
const top_right = Panel(renderer, panel_size, panel_size, 0)
const bot_left = Panel(renderer, panel_size, 0, panel_size)
const bot_right = Panel(renderer, panel_size, panel_size, panel_size)

const pixels_bg = Vector{UInt32}(undef, panel_size*panel_size)
const pixels = Vector{UInt32}(undef, panel_size*panel_size)

push!(LOAD_PATH, replace(pwd(), "/gui" => ""))
include("../base/simulation.jl")
include("../base/draw.jl")
include("../base/args.jl")

include("../" * get_parfile())
	

const arg_settings = ArgParseSettings("run simulation", autofix_names=true)

@add_arg_table arg_settings begin
	"--stop-time", "-t"
		help = "at which time to stop the simulation" 
		arg_type = Float64 
		default = 0.0
end

add_arg_group(arg_settings, "simulation parameters")
fields_as_args!(arg_settings, Params)

const args = parse_args(arg_settings, as_symbols=true)
const parameters = create_from_args(args, Params)
const t_stop = args[:stop_time] 


using Random

Random.seed!(parameters.rand_seed_world)
const world = create_world(parameters)

Random.seed!(parameters.rand_seed_sim)
const model = Model(world, Agent[], Agent[])


const canvas = Canvas(pixels, panel_size)
const canvas_bg = Canvas(pixels_bg, panel_size)

clear!(canvas_bg)
draw_bg!(canvas_bg, model)

const sim = Simulation(model, parameters)

t = 0.0
start(sim)

count = 0
while true
	global t, count
	
	upto!(sim.scheduler, t + 1.0)
	
	t += 1.0

	if t_stop > 0 && t >= t_stop
		break
	end
	
	ev = SDL2.event()
	
	if typeof(ev) <: SDL2.KeyboardEvent #|| typeof(ev) <: SDL2.QuitEvent
		break;
	end


	println(count, " #migrants: ", length(model.migrants), 
		" #arrived: ", length(model.people) - length(model.migrants))

	copyto!(canvas, canvas_bg)
	draw_people!(canvas, model)
	update!(top_left, canvas.pixels)

	if count > 10
		clear!(canvas)
		draw_visitors!(canvas, model)
		update!(top_right, canvas.pixels)
		count = 0
	end
	count += 1

	clear!(canvas)
	agent = draw_rand_knowledge!(canvas, model)
	update!(bot_left, canvas.pixels)

	clear!(canvas)
	draw_rand_social!(canvas, model, 3, agent)
	update!(bot_right, canvas.pixels)

	SDL2.RenderClear(renderer)
	render(top_left)
	render(top_right)
	render(bot_left)
	render(bot_right)
    SDL2.RenderPresent(renderer)
    sleep(0.001)
end
SDL2.Quit()
