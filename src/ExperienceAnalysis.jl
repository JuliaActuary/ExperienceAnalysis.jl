module ExperienceAnalysis

using Dates

export exposure

abstract type ExposurePeriod end

struct Anniversary{T} <: ExposurePeriod
    pol_period::T
end

struct AnniversaryCalendar{T,U} <: ExposurePeriod
    pol_period::T
    cal_period::U
end

struct Calendar{U} <: ExposurePeriod
    cal_period::U
end

# make ExposurePeriod broadcastable so that you can broadcast 
Base.Broadcast.broadcastable(ic::ExposurePeriod) = Ref(ic)

function next_exposure(from, to, period)
    return (from=from, to=min(from + period, to))
end

"""
    exposure(ExposurePeriod,from,to,continued_exposure=false)

Return an array of name tuples `(from=Date,to=Date)` of the exposure periods for the given `ExposurePeriod`s. 

If `continued_exposure` is `true`, then the final `to` date will continue through the end of the final ExposurePeriod. This is useful if you want the decrement of interest is the cause of termination, because then you want a full exposure.


# Example

```julia
julia> using ExperienceAnalysis,Dates

julia> issue = Date(2016, 7, 4)
julia> termination = Date(2020, 1, 17)
julia> basis = ExperienceAnalysis.Anniversary(Year(1))

julia> exposure(basis, issue, termination)
4-element Array{NamedTuple{(:from, :to),Tuple{Date,Date}},1}:
 (from = Date("2016-07-04"), to = Date("2017-07-04"))
 (from = Date("2017-07-04"), to = Date("2018-07-04"))
 (from = Date("2018-07-04"), to = Date("2019-07-04"))
 (from = Date("2019-07-04"), to = Date("2020-01-17"))


"""
function exposure(p::Anniversary{T}, from, to, continued_exposure=false) where {T}
    period = p.pol_period
    result = [next_exposure(from, to, period)]
    while result[end].to < to
        push!(
            result,
            next_exposure(result[end].to, to, period)
        )
    end

    if continued_exposure && (result[end].to == to)
        result[end] = (from=result[end].from, to=result[end].from + period)
    end

    return result
end

function exposure(p::AnniversaryCalendar{T,U}, from, to, continued_exposure=false) where {T,U}

    period = min(p.cal_period, p.pol_period)

    next_pol_per = from + p.pol_period
    next_cal_per = ceil(from, p.cal_period)

    next_terminus = min(min(next_pol_per, next_cal_per), to)

    result = [next_exposure(from, next_terminus, period)]
    while result[end].to < to
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

        next_terminus = min(min(next_pol_per, next_cal_per), to)
    end

    if continued_exposure && (result[end].to == to)
        result[end] = (from=result[end].from, to=min(next_pol_per, next_cal_per))
    end

    return result
end

function exposure(p::Calendar{U}, from, to, continued_exposure=false) where {U}
    period = p.cal_period

    next_cal_per = ceil(from, p.cal_period)

    next_terminus = min(next_cal_per, to)

    result = [next_exposure(from, next_terminus, period)]
    while result[end].to < to
        while result[end].to < next_terminus
            push!(
                result,
                next_exposure(result[end].to, next_terminus, period)
            )
        end
        if result[end].to >= next_cal_per
            next_cal_per = ceil(next_cal_per + p.cal_period, p.cal_period)
        end

        next_terminus = min(next_cal_per, to)
    end

    if continued_exposure && (result[end].to == to)
        result[end] = (from=result[end].from, to=result[end].from + period)
    end

    return result
end

end
