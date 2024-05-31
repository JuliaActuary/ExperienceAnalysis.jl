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
get smallest `t` such that `from + t*step > max(from, left_trunc)`
"""
function get_timestep_past(from::Date, left_trunc::Date, step::DatePeriod)
    if from >= left_trunc
        return 1
    end
    t = 1
    while from + t * step <= left_trunc
        t += 1
    end
    return t
end

"""
We create intervals with two pointers. This function helps us find the starting points of the first and second intervals, `cur` and `nxt`. We also return the timestep of the interval starting with `nxt`.
"""
function preprocess_left(
    from::Date,
    step::DatePeriod,
    study_start::Union{Date,Nothing},
    left_partials::Bool,
)
    # deal with nothing case
    left_trunc = isnothing(study_start) ? from : max(from, study_start)
    # find first endpoint
    t = get_timestep_past(from, left_trunc, step)
    # if left_partials == false:
    # from + (t-1) * step == left_trunc means that the first interval is good and need not be skipped.
    if left_partials || (from + (t - 1) * step == left_trunc)
        cur = left_trunc
        nxt = from + t * step
        return cur, nxt, t
    else
        cur = from + t * step
        nxt = from + (t + 1) * step
        return cur, nxt, t + 1
    end
end

"""
If data has problems like `from > to` or `study_start > study_end` throw an error. 
If the policy doesn't overlap with the study period, return false. If there is overlap, return true.
"""
function validate(
    from::Date,
    to::Union{Date,Nothing},
    study_start::Union{Date,Nothing},
    study_end::Date,
)
    # throw errors if inputs are not good
    !isnothing(to) && from > to &&
        throw(DomainError("from=$from argument is a later date than the to=$to argument."))

    !isnothing(study_start) &&
        study_start > study_end &&
        throw(
            DomainError(
                "study_start=$study_start argument is a later date than the study_end=$study_end argument.",
            ),
        )

    # if no overlap return false, if overlap return true
    return (isnothing(study_start) || isnothing(to) || study_start <= to) && (from <= study_end)
end

"""
    exposure(
        p::Anniversary,
        from::Date,
        to::Union{Date,Nothing},
        continued_exposure::Bool = false;
        study_start::Union{Date,Nothing} = nothing,
        study_end::Date,
        left_partials::Bool = true,
        right_partials::Bool = true,
    )::Vector{NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Int}}}

Return an array of name tuples `(from=Date,to=Date,policy_timestep=Int)` of the exposure periods for the given `ExposurePeriod`s. 

If `continued_exposure` is `true`, then the final `to` date will continue through the end of the final ExposurePeriod. This is useful if you want the decrement of interest is the cause of termination, because then you want a full exposure.


# Example

```julia
julia> using ExperienceAnalysis,Dates
julia> exposure(
    ExperienceAnalysis.Anniversary(Year(1)), # basis
    Date(2020,5,10),                         # issue
    Date(2022, 6, 10);                       # termination
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)
3-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)
 (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)
 (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)


"""
function exposure(
    p::Anniversary,
    from::Date,
    to::Union{Date,Nothing},
    continued_exposure::Bool = false;
    study_start::Union{Date,Nothing} = nothing,
    study_end::Date,
    left_partials::Bool = true,
    right_partials::Bool = true,
)::Vector{NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Int}}}

    continued_exposure = continued_exposure && to <= study_end
    result = NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Int}}[]
    # no overlap
    if !validate(from, to, study_start, study_end)
        return result
    end
    period = p.pol_period
    right_trunc = isnothing(to) ? study_end : min(study_end, to)
    # cur is current interval start, nxt is next interval start, t is timestep for nxt
    cur, nxt, t = preprocess_left(from, period, study_start, left_partials)
    while cur <= right_trunc && (right_partials || (nxt <= study_end + Day(1))) #more rows to fill 
        push!(result, (from = cur, to = nxt - Day(1), policy_timestep = t))
        t += 1
        cur, nxt = nxt, from + t * period
    end

    # If exposure is not continued, it should go at most to right_trunc
    if !continued_exposure && !isempty(result)
        result[end] = (
            from = result[end].from,
            to = min(result[end].to, right_trunc),
            policy_timestep = result[end].policy_timestep,
        )
    end

    return result
end

function exposure(
    p::AnniversaryCalendar,
    from::Date,
    to::Date,
    continued_exposure::Bool = false;
    study_start::Union{Date,Nothing} = nothing,
    study_end::Date,
    left_partials::Bool = true,
    right_partials::Bool = true,
)
    continued_exposure = continued_exposure && to <= study_end
    result = NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Int}}[]
    # no overlap
    if !validate(from, to, study_start, study_end)
        return result
    end
    cur, next_pol_per, pol_t =
        preprocess_left(from, p.pol_period, study_start, left_partials)
    next_cal_per = floor(cur, p.cal_period) + p.cal_period
    right_trunc = isnothing(to) ? study_end : min(study_end, to)
    while (
        (continued_exposure && next_pol_per - p.pol_period <= right_trunc) ||
        (!continued_exposure && cur <= right_trunc)
    ) && (right_partials || (next_pol_per <= study_end + Day(1)))
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
            push!(result, (from = cur, to = next_pol_per - Day(1), policy_timestep = pol_t))
            cur = next_pol_per
            pol_t += 1
            next_pol_per = from + pol_t * p.pol_period
            next_cal_per += p.cal_period
        end
    end

    if !continued_exposure && !isempty(result)
        result[end] = (
            from = result[end].from,
            to = min(result[end].to, right_trunc),
            policy_timestep = result[end].policy_timestep,
        )
    end

    return result
end

function exposure(
    p::Calendar,
    from::Date,
    to::Union{Date,Nothing},
    continued_exposure::Bool = false;
    study_start::Union{Date,Nothing} = nothing,
    study_end::Date,
)::Vector{NamedTuple{(:from, :to),Tuple{Date,Date}}}
    continued_exposure = continued_exposure && to <= study_end
    result = NamedTuple{(:from, :to),Tuple{Date,Date}}[]
    # no overlap
    if !validate(from, to, study_start, study_end)
        return result
    end
    period = p.cal_period
    right_trunc = isnothing(to) ? study_end : min(study_end, to)
    cur = isnothing(study_start) ? from : max(from, study_start)
    nxt = floor(cur, period) + period
    while cur <= right_trunc
        push!(result, (from = cur, to = nxt - Day(1)))
        cur, nxt = nxt, nxt + period
    end

    if !continued_exposure
        result[end] = (from = result[end].from, to = min(to, right_trunc))
    end

    return result
end

end
