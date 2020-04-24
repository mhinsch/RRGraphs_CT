module SSDL

export Canvas, xsize, ysize, clear!, put, line, fillRectC, linePat,
	alpha, red, green, blue, rgb, argb, WHITE,
	bresenham

uint(f) = floor(UInt32, f)

struct Canvas
	pixels :: Vector{UInt32}
	xsize :: Int
	ysize :: Int
end

Canvas(xs :: Int, ys :: Int) = Canvas(Vector{UInt32}(undef, xs*ys), xs, ys)

function put(canvas::Canvas, x, y, colour::UInt32)
	canvas.pixels[(x-1)*canvas.ysize + y] = colour
end

function fillRectC(canvas::Canvas, x, y, w, h, colour::UInt32)
	xs, ys = size(canvas)

	xmi = max(1, x)
	xma = min(xs, x+w-1)
	ymi = max(1, y)
	yma = min(ys, y+h-1)

	for xx in xmi:xma
		for yy in ymi:yma
			put(canvas, xx, yy, colour)
		end
	end
end

function line(canvas::Canvas, x1, y1, x2, y2, col::UInt32)
	bresenham(x1, y1, x2, y2) do x, y
		put(canvas, x, y, col)
	end
end

function linePat(canvas::Canvas, x1, y1, x2, y2, on, off, col::UInt32)
	count = 1
	bresenham(x1, y1, x2, y2) do x, y
		if count <= on
			put(canvas, x, y, col)
		else
			count = count % (on+off) 
		end
		count += 1
	end
end


xsize(canvas::Canvas) = canvas.xsize
ysize(canvas::Canvas) = canvas.ysize
Base.size(canvas::Canvas) = xsize(canvas), ysize(canvas)


clear!(canvas::Canvas) = fill!(canvas.pixels, 0)


Base.copyto!(c1::Canvas, c2::Canvas) = copyto!(c1.pixels, c2.pixels)


alpha(x) = UInt32(x<<24)
alpha(x::F) where {F<:AbstractFloat} = alpha(floor(UInt32, x))

red(x) = UInt32(x<<16)
red(x::F) where {F<:AbstractFloat} = red(floor(UInt32, x))

green(x) = Int32(x<<8)
green(x::F) where {F<:AbstractFloat}  = green(floor(UInt32, x))

blue(x) = UInt32(x)
blue(x::F) where {F<:AbstractFloat}  = blue(floor(UInt32, x))

rgb(r, g, b) = red(r) | green(g) | blue(b)
argb(a, r, g, b) = alpha(a) | red(r) | green(g) | blue(b)


const WHITE = 0xFFFFFFFF

# based on this code:
# https://stackoverflow.com/questions/40273880/draw-a-line-between-two-pixels-on-a-grayscale-image-in-julia
function bresenham(f :: Function, x1::Int, y1::Int, x2::Int, y2::Int)
	#println("b: ", x1, ", ", y1)
	#println("b: ", x2, ", ", y2)
	# Calculate distances
	dx = x2 - x1
	dy = y2 - y1

	# Determine how steep the line is
	is_steep = abs(dy) > abs(dx)

	# Rotate line
	if is_steep == true
		x1, y1 = y1, x1
		x2, y2 = y2, x2
	end

	# Swap start and end points if necessary 
	if x1 > x2
		x1, x2 = x2, x1
		y1, y2 = y2, y1
	end
	# Recalculate differentials
	dx = x2 - x1
	dy = y2 - y1

	# Calculate error
	error = round(Int, dx/2.0)

	if y1 < y2
		ystep = 1
	else
		ystep = -1
	end

	# Iterate over bounding box generating points between start and end
	y = y1
	for x in x1:x2
		if is_steep == true
			coord = (y, x)
		else
			coord = (x, y)
		end

		f(coord[1], coord[2])

		error -= abs(dy)

		if error < 0
			y += ystep
			error += dx
		end
	end

end


end	# module
