using Dates
using BenchmarkTools

""" difference in months between dates """
function get_timestep_diff(timestep::Month, start_date::Date, end_date::Date)::Month
    return Month(Year(end_date) - Year(start_date)) + (Month(end_date) - Month(start_date))
end

""" difference in years between dates """
function get_timestep_diff(timestep::Year, start_date::Date, end_date::Date)::Year
    return Year(end_date) - Year(start_date)
end

"""
    first_endpoint(timestep::Union{Year, Month}, start_date::Date, left_truncation::Date)::Date
Largest non-negative integer `n` such that `start_date + n*timestep <= max(start_date, left_truncation)`
"""
function get_firstdate(timestep::Union{Month,Year}, start_date::Date, left_truncation::Date)::Date
    if start_date >= left_truncation
        return start_date
    end
    # left_truncation > start_date
    timestep_diff = get_timestep_diff(timestep, start_date, left_truncation)
    approx_timesteps = div(timestep_diff, timestep)
    approx_result = start_date + approx_timesteps * timestep
    if approx_result > left_truncation
        return approx_result - timestep
    end
    return approx_result
end

"""
    get_last_timestep(timestep::Union{Year, Month}, start_date::Date, right_truncation::Date)::Int64
Smallest non-negative integer `n` such that `start_date + n*timestep >= max(start_date, right_truncation)`

Preprocessing guarantees start_date <= right_truncation.
"""
function get_lastdate(timestep::Union{Month,Year}, start_date::Date, right_truncation::Date)::Date
    # start_date <= right_truncation
    timestep_diff = get_timestep_diff(timestep, start_date, right_truncation)
    approx_timesteps = div(timestep_diff, timestep)
    approx_result = start_date + approx_timesteps * timestep
    if approx_result < right_truncation
        return approx_result + timestep
    end
    return approx_result
end

"""Returns a sorted vector of the union of P and E."""
function endpoints_from_preprocessed(anniv_date::Date, partition_start::Date, partition_end::Date; policy_timestep::Union{Month,Year})::Vector{Date}
    # Get the next partitions
    firstdate = get_firstdate(policy_timestep, anniv_date, partition_start)
    lastdate = get_lastdate(policy_timestep, anniv_date, partition_end)
    intervals = collect(firstdate:policy_timestep:lastdate)
    intervals[begin] = partition_start
    intervals[end] = partition_end
    return intervals
end



###############################################################################

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
println("4 elements")
@btime endpoints_from_preprocessed(Date(2013, 2, 4), Date(2016, 7, 4), Date(2020, 1, 17), policy_timestep=Year(1));
@btime exposure(Anniversary(Year(1)), Date(2016, 7, 4), Date(2020, 1, 17))
println(">40 elements")
@btime endpoints_from_preprocessed(Date(2013, 2, 4), Date(2016, 7, 4), Date(2020, 1, 17), policy_timestep=Month(1));
@btime exposure(Anniversary(Month(1)), Date(2016, 7, 4), Date(2020, 1, 17))
