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
    )::Vector{NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Union{Int,Nothing}}}}

Calcualte the exposure periods and returns an array of named tuples with fields:
- `from` (a `Date`) is the start date of the exposure interval
- `to` (a `Date`) is the end of the exposure interval
- `policy_step` will either be an `Int` if an Anniversary or AnniversaryCalendar basis is used, otherwise will be `nothing`

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
    from::Date,
    to::Date,
    continued_exposure=false;
    study_start::Date=typemin(from),
    study_end::Date=typemax(from),
    left_partials::Bool=true,
    right_partials::Bool=true,
)
    validate(from, to, study_start, study_end)

    # always start from `from` to simplify the logic, and deal with
    # study_start and left partials at the end
    policy_timestep = 1
    next_pol_per, policy_timestep = if isnothing(p.pol_period)
        typemax(from), nothing
    else
        pp = from + p.pol_period - Day(1)

        # is_leap_day = month(from) == 2 && day(from) == 29

        # # if is_leap_day
        # #     # pp += Day(1)
        # # end

        pp, 1
    end
    next_cal_per = if isnothing(p.cal_period)
        typemax(from)
    else
        c = ceil(from, p.cal_period)
        if c == from # date is already the "ceiling" for the next calendar increment, so adjust by one to get next date
            ceil(from + Day(1), p.cal_period) - Day(1)
        else
            ceil(from, p.cal_period) - Day(1)
        end
    end
    next_terminus = min(next_pol_per, next_cal_per)

    result = [(from=from, to=next_terminus, policy_timestep=policy_timestep)]

    # do this after instantiating result to keep type stability
    if to < study_start || study_end < from
        return empty!(result)
    end

    while true
        result[end].to >= min(to, study_end) && break
        if result[end].to >= next_pol_per
            # increment the prior by one and subtract the result 
            # in order to get end-of-month policies to flow as intended
            next_pol_per = (next_pol_per + Day(1)) + (p.pol_period - Day(1))

            # special case for if issue date is a leap day
            if monthday(from) == (2, 29) && Dates.isleapyear(next_pol_per) && monthday(next_pol_per) == (2, 27)
                next_pol_per += Day(1)
            end

            policy_timestep += 1
        end
        if result[end].to >= next_cal_per
            next_cal_per = ceil(next_cal_per + Day(1) + p.cal_period, p.cal_period) - Day(1)
        end
        next_terminus = min(next_pol_per, next_cal_per)

        # check if terminus needs adjusted because of the study or termination
        # when there is no continuation
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
        # modify first exposure to start at study start
        # only do this if we are wanting to keep partials though
        if left_partials && first(result).from < study_start
            result[begin] = (
                from=study_start,
                to=result[begin].to,
                policy_timestep=result[begin].policy_timestep
            )
        end
        if !left_partials
            # a partial is an exposure that is less than an otherwise full exposure
            # next_pol_per = isnothing(p.pol_period) ? typemax(from) : from + p.pol_period - Day(1)
            # next_cal_per = isnothing(p.cal_period) ? typemax(from) : ceil(from, p.cal_period) - Day(1)
            if first(result).from < study_start #&& first(result).to < min(next_cal_per, next_cal_per)
                popfirst!(result)
            end
        end
    end

    if !right_partials
        while last(result).to > study_end
            pop!(result)
        end
    end

    return result
end
end
