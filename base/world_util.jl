
struct Pos
	x :: Float64
	y :: Float64
end

const Nowhere = Pos(-1.0, -1.0)


distance(p1 :: Pos, p2 :: Pos) = Util.distance(p1.x, p1.y, p2.x, p2.y)




