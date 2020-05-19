using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

push!(LOAD_PATH, replace(pwd(), "/gui" => ""))
#import SimpleDirectMediaLayer.LoadBMP
using SSDL


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

update!(p :: Panel, c :: Canvas) = update!(p, c.pixels)

function render(p :: Panel)
	SDL2.RenderCopy(p.renderer, p.texture, C_NULL, pointer_from_objref(p.rect))
end


struct Gui
	tl :: Panel
	tr :: Panel
	bl :: Panel
	br :: Panel
	canvas :: Canvas
	canvas_bg :: Canvas
end

function setup_Gui(panel_size = 1024)
	win_size = 2 * panel_size

	renderer = setup_window(win_size, win_size)

	top_left = Panel(renderer, panel_size, 0, 0)
	top_right = Panel(renderer, panel_size, panel_size, 0)
	bot_left = Panel(renderer, panel_size, 0, panel_size)
	bot_right = Panel(renderer, panel_size, panel_size, panel_size)

	canvas = Canvas(panel_size, panel_size)
	canvas_bg = Canvas(panel_size, panel_size)

	Gui(top_left, top_right, bot_left, bot_right, canvas, canvas_bg)
end


function render!(gui)
	SDL2.RenderClear(gui.tl.renderer)
	render(gui.tl)
	render(gui.tr)
	render(gui.bl)
	render(gui.br)
    SDL2.RenderPresent(gui.tl.renderer)
end


function draw(model, gui, focus_agent, scales, clear=false)
	copyto!(gui.canvas, gui.canvas_bg)
	draw_people!(gui.canvas, model)
	update!(gui.tl, gui.canvas)

	if clear
		clear!(gui.canvas)
		draw_visitors!(gui.canvas, model)
		update!(gui.tr, gui.canvas)
		count = 0
	end

	clear!(gui.canvas)
	agent = draw_rand_knowledge!(gui.canvas, model, scales, focus_agent)
	update!(gui.bl, gui.canvas)

	clear!(gui.canvas)
	draw_rand_social!(gui.canvas, model, 3, agent)
	update!(gui.br, gui.canvas)
end


function run(sim, gui, t_stop, scales)
	t = 0.0
	step = 1.0
	start(sim)

	focus_agent = nothing

	count = 1
	while true
		t1 = time()
		upto!(sim.scheduler, t + 1.0)
		t += step
		dt = time() - t1

		if dt > 0.1
			step /= 1.1
		elseif dt < 0.03
			step *= 1.1
		end

		if t_stop > 0 && t >= t_stop
			break
		end
		
		ev = SDL2.event()
		
		if typeof(ev) <: SDL2.KeyboardEvent #|| typeof(ev) <: SDL2.QuitEvent
			break;
		end

		println(t, " #migrants: ", length(sim.model.migrants), 
			" #arrived: ", length(sim.model.people) - length(sim.model.migrants))

		if (focus_agent == nothing || arrived(focus_agent)) &&
			length(sim.model.migrants) > 0
			focus_agent = sim.model.people[end]
		end

		t1 = time()
		draw(sim.model, gui, focus_agent, scales, count==1)
		count = count % 10 + 1
		#println("dt: ", time() - t1)
		render!(gui)
		#println("dt2: ", time() - t1)
	end
end


include("../analysis.jl")
include("../base/simulation.jl")
include("../base/draw.jl")
include("../base/args.jl")

include("../" * get_parfile())
	

const arg_settings = ArgParseSettings("run simulation", autofix_names=true)

@add_arg_table! arg_settings begin
	"--stop-time", "-t"
		help = "at which time to stop the simulation" 
		arg_type = Float64 
		default = 0.0
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
const parameters = create_from_args(args, Params)
const t_stop = args[:stop_time] 

const sim = Simulation(setup_model(parameters), parameters)

const gui = setup_Gui(1024)

const logf = open(args[:log_file], "w")
const cityf = open(args[:city_file], "w")
const linkf = open(args[:link_file], "w")

clear!(gui.canvas_bg)
scales = draw_bg!(gui.canvas_bg, sim.model, parameters)

run(sim, gui, t_stop, scales)

analyse_world(sim.model, cityf, linkf)

close(logf)
close(cityf)
close(linkf)

SDL2.Quit()
