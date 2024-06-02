module ExperienceAnalysis

using Dates

export exposure

abstract type ExposurePeriod end

function Anniversary(period::DatePeriod)
    AnniversaryCalendar(period, nothing)
end

struct AnniversaryCalendar{T<:Union{Nothing,DatePeriod},U<:Union{Nothing,DatePeriod}} <: ExposurePeriod
    pol_period::T
    cal_period::U
end

function Calendar(period::DatePeriod)
    AnniversaryCalendar(nothing, period)
end

# make ExposurePeriod broadcastable so that you can broadcast 
Base.Broadcast.broadcastable(ic::ExposurePeriod) = Ref(ic)


"""
If data has problems like `from > to` or `study_start > study_end` throw an error. 
If the policy doesn't overlap with the study period, return false. If there is overlap, return true.
"""
function validate(
    from::Date,
    to::Date,
    study_start::Date,
    study_end::Date,
)
    # throw errors if inputs are not good
    from > to && throw(DomainError("from=$from argument is a later date than the to=$to argument."))

    if study_start > study_end
        throw(
            DomainError(
                "study_start=$study_start argument is a later date than the study_end=$study_end argument.",
            ),
        )
    end

    # if no overlap return false, if overlap return true
    return (isnothing(study_start) || isnothing(to) || study_start <= to) && (from <= study_end)
end

"""
    exposure(
        p::Anniversary,
        from::Date,
        to::Date,
        continued_exposure::Bool = false;
        study_start=typemin(from),
        study_end=typemax(from),
        left_partials::Bool=true,
        right_partials::Bool=true,
    )::Vector{NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Union{Int,Missing}}}}

Calcualte the exposure periods and returns an array of named tuples with fields:
- `from` (a `Date`) is the start date of the exposure interval
- `to` (a `Date`) is the end of the exposure interval
- `policy_step` will either be an `Int` if an Anniversary or AnniversaryCalendar basis is used, otherwise will be `missing`

If `continued_exposure` is `true`, then the final `to` date will continue through the end of the final exposure period. This is useful if you want the decrement of interest is the cause of termination, because then you want a full exposure.

If `left_partials` or `right_partials` is set to false, then the exposure will not return partial exposure periods that overlap with the `study_start` and `study_end` respectively.

# Example

```julia-repl
julia> using ExperienceAnalysis,Dates
julia> exposure(
    ExperienceAnalysis.Anniversary(Year(1)), # basis
    Date(2020,5,10),                         # issue
    Date(2022, 6, 10);                       # termination
)
3-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)
 (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)
 (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)
"""
function exposure(
    p::AnniversaryCalendar,
    from,
    to,
    continued_exposure=false;
    study_start=typemin(from),
    study_end=typemax(from),
    left_partials::Bool=true,
    right_partials::Bool=true,
)
    validate(from, to, study_start, study_end)

    # always start from `from` to simplify the logic, and deal with
    # study_start and left partials at the end
    policy_timestep = 1
    next_pol_per, policy_timestep = if isnothing(p.pol_period)
        typemax(from), missing
    else
        from + p.pol_period - Day(1), 1
    end
    next_cal_per = isnothing(p.cal_period) ? typemax(from) : ceil(from, p.cal_period) - Day(1)

    next_terminus = min(next_pol_per, next_cal_per)

    result = [(from=from, to=next_terminus, policy_timestep=policy_timestep)]


    while true
        result[end].to >= min(to, study_end) && break
        if result[end].to >= next_pol_per
            next_pol_per = next_pol_per + p.pol_period - Day(1)
            policy_timestep += 1
        end
        if result[end].to >= next_cal_per
            next_cal_per = ceil(next_cal_per + p.cal_period, p.cal_period) - Day(1)
        end
        next_terminus = min(next_pol_per, next_cal_per)

        # check if terminus needs adjusted
        if !continued_exposure && (min(study_end, to) < next_terminus)
            next_terminus = min(study_end, to)
        end
        # @show last(result), next_terminus, next_pol_per, next_cal_per
        push!(
            result,
            (from=result[end].to + Day(1), to=next_terminus, policy_timestep=policy_timestep)
        )
    end

    if !isnothing(study_start)
        # remove entries which come before the study_start
        while first(result).to < study_start
            popfirst!(result)
        end
        if !left_partials && first(result).from < study_start
            popfirst!(result)
        end
    end

    if !right_partials
        while last(result.from) <= study_start
            pop!(result)
        end
    end

    return result
end
end
