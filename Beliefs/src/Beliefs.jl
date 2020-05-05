module Beliefs

export Trusted, TrustedF, discounted, update, average, BeliefPars, receive_belief, exchange_beliefs


struct Trusted{T}
	value :: T
	trust :: Float64

	function Trusted{T}(v :: T, t :: Float64) where {T}
		#@assert 0.0 < t < 1.0 "$v, $t: $t out of bounds!"
		new(v, t)
	end
end

function Trusted{T}(v :: T) where {T}
	Trusted{T}(v, eps(0.0))
end


const TrustedF = Trusted{Float64}


discounted(t :: Trusted{T}) where {T} = t.value * t.trust


update(t :: TrustedF, val, speed) = average(t, TrustedF(val, 1.0-eps(1.0)), speed)


average(val :: TrustedF, target :: TrustedF, weight = 0.5) =
	TrustedF(val.value * (1.0-weight) + target.value * weight, 
		val.trust * (1.0-weight) + target.trust * weight)


struct BeliefPars
	convince :: Float64
	convert :: Float64
	confuse :: Float64
end


receive_belief(self::TrustedF, other::TrustedF, par) = 
	TrustedF(
		receive_belief(
			self.trust, self.value, 
			other.trust, other.value, 
			par.convince, par.convert, par.confuse)...)


function receive_belief(t, v, t_pcv, v_pcv, ci, ce, cu)
	d = 1.0 - t		# doubt
	d_pcv = 1.0 - t_pcv

	dist_pcv = abs(v-v_pcv) / (v + v_pcv + 0.00001)

	# sum up values according to area of overlap between 1 and 2
	# from point of view of 1:
	# doubt x doubt -> doubt
	# trust x doubt -> trust
	# doubt x trust -> doubt / convince
	# trust x trust -> trust / convert / confuse (doubt)

	#					doubt x doubt		doubt x trust
	d_ = 					d * d_pcv + 	d * t_pcv * (1.0 - ci) + 
	#	trust x trust
		t * t_pcv * cu * dist_pcv
	#	trust x doubt
	v_ = t * d_pcv * v + 					d * t_pcv * ci * v_pcv + 
		t * t_pcv * (1.0 - cu * dist_pcv) * ((1.0 - ce) * v + ce * v_pcv)

	t_ = 1.0 - max(0.000001, min(d_, 0.99999))

	v_ / t_, t_
end


function exchange_beliefs(val1::TrustedF, val2::TrustedF, err_f, par1, par2)
	if val1.trust == 0.0 && val2.trust == 0.0
		return val1, val2
	end

	receive_belief(val1, err_f(val2), par1), receive_belief(val2, err_f(val1), par2)
end


end	# module
