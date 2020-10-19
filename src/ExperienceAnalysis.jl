module ExperienceAnalysis

using Dates

export exposure

abstract type ExposurePeriod end

struct Policy{T} <: ExposurePeriod 
    pol_period::T
end

struct PolicyCalendar{T,U} <: ExposurePeriod 
    pol_period::T
    cal_period::U
end

struct Calendar{U} <: ExposurePeriod 
    cal_period::U
end

function next_exposure(i, t, period)
	
	return (from = i, to = min(i + period, t))
		
	
end


function exposure(i, t, p::Policy{T}) where {T}
    period = p.pol_period
	result = [next_exposure(i, t, period)]
	while result[end].to < t
		push!(
            result,
            next_exposure(result[end].to, t, period)
            )
	end
	return result
end
    
function exposure(i, t, p::PolicyCalendar{T,U}) where {T,U}

    period = min(p.cal_period, p.pol_period)
    
    next_pol_per = i + p.pol_period
    next_cal_per = ceil(i, p.cal_period)

    next_terminus = min(min(next_pol_per, next_cal_per), t)

    result = [next_exposure(i, next_terminus, period)]
    while result[end].to < t
        while result[end].to < next_terminus
            push!(
                result,
                next_exposure(result[end].to, next_terminus, period)
                )
        end
        if result[end].to >= next_pol_per
            next_pol_per = next_pol_per + p.pol_period
        end
        if result[end].to >= next_cal_per
            next_cal_per = ceil(next_cal_per + p.cal_period, p.cal_period)
        end

        next_terminus = min(min(next_pol_per, next_cal_per), t)
	end
	return result
end

function exposure(i, t, p::Calendar{U}) where {U}
    period = p.cal_period
    
    next_cal_per = ceil(i, p.cal_period)

    next_terminus = min(next_cal_per, t)

    result = [next_exposure(i, next_terminus, period)]
    while result[end].to < t
        while result[end].to < next_terminus
            push!(
                result,
                next_exposure(result[end].to, next_terminus, period)
                )
        end
        if result[end].to >= next_cal_per
            next_cal_per = ceil(next_cal_per + p.cal_period, p.cal_period)
        end

        next_terminus = min(next_cal_per, t)
	end
	return result
end

end
