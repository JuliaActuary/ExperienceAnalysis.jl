module ExperienceAnalysis

using Dates

export exposure

abstract type ExposurePeriod end

struct Anniversary{T<:DatePeriod} <: ExposurePeriod
    pol_period::T
end

struct AnniversaryCalendar{T<:DatePeriod,U<:DatePeriod} <: ExposurePeriod
    pol_period::T
    cal_period::U
end

struct Calendar{U<:DatePeriod} <: ExposurePeriod
    cal_period::U
end

# make ExposurePeriod broadcastable so that you can broadcast 
Base.Broadcast.broadcastable(ic::ExposurePeriod) = Ref(ic)

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
function exposure(p::Anniversary, from::Date, to::Date, continued_exposure::Bool = false)
    to < from &&
        throw(DomainError("from=$from argument is a later date than the to=$to argument."))
    period = p.pol_period
    t = 1
    cur = from
    nxt = from + period
    result = []
    while cur <= to #more rows to fill
        push!(result, (from = cur, to = nxt - Day(1), policy_timestep = t))
        t += 1
        cur, nxt = nxt, from + t * period
    end

    if !continued_exposure
        result[end] = (
            from = result[end].from,
            to = to,
            policy_timestep = result[end].policy_timestep,
        )
    end

    return result
end

function exposure(
    p::AnniversaryCalendar,
    from::Date,
    to::Date,
    continued_exposure::Bool = false,
)
    to < from &&
        throw(DomainError("from=$from argument is a later date than the to=$to argument."))

    cur = from
    pol_t = 1
    next_pol_per = from + p.pol_period
    next_cal_per = floor(from, p.cal_period) + p.cal_period

    result = []
    while cur <= to
        if next_pol_per < next_cal_per
            push!(result, (from = cur, to = next_pol_per - Day(1), policy_timestep = pol_t))
            cur = next_pol_per
            pol_t += 1
            next_pol_per = from + pol_t * p.pol_period
        elseif next_pol_per > next_cal_per
            push!(result, (from = cur, to = next_cal_per - Day(1), policy_timestep = pol_t))
            cur = next_cal_per
            next_cal_per += p.cal_period
        else # next_pol_per == next_cal_per
            cur = next_pol_per
            pol_t += 1
            next_pol_per = from + pol_t * p.pol_period
            next_cal_per += p.cal_period
        end
    end

    if !continued_exposure
        result[end] = (
            from = result[end].from,
            to = to,
            policy_timestep = result[end].policy_timestep,
        )
    end

    return result
end

function exposure(p::Calendar, from::Date, to::Date, continued_exposure::Bool = false)
    to < from &&
        throw(DomainError("from=$from argument is a later date than the to=$to argument."))
    period = p.cal_period

    cur = from
    nxt = floor(from, period) + period
    result = []

    while cur <= to
        push!(result, (from = cur, to = nxt - Day(1)))
        cur, nxt = nxt, nxt + period
    end

    if !continued_exposure
        result[end] = (from = result[end].from, to = to)
    end

    return result
end

end
