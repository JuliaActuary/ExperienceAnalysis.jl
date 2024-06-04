# ExperienceAnalysis
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaActuary.github.io/ExperienceAnalysis.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaActuary.github.io/ExperienceAnalysis.jl/dev)
![](https://github.com/JuliaActuary/LifeContingencies.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActuary/ExperienceAnalysis.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActuary/ExperienceAnalysis.jl)
[![lifecycle](https://img.shields.io/badge/LifeCycle-Developing-blule)](https://www.tidyverse.org/lifecycle/)

Calculate exposures.

## Quickstart

```julia
using ExperienceAnalysis
using DataFrames
using Dates

df = DataFrame(
    policy_id = 1:3,
    issue_date = [Date(2020,5,10), Date(2020,4,5), Date(2019, 3, 10)],
    termination_date = [Date(2022, 6, 10), Date(2022, 8, 10), nothing],
    status = ["claim", "lapse", "inforce"]
)

df.policy_year = exposure.(
    ExperienceAnalysis.Anniversary(Year(1)),
    df.issue_date,
    df.termination_date,
    df.status .== "claim"; # continued exposure
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)

df = flatten(df, :policy_year)

df.exposure_fraction =
        map(e -> yearfrac(e.from, e.to + Day(1), DayCounts.Thirty360()), df.policy_year) 
# + Day(1) above because DayCounts has Date(2020, 1, 1) to Date(2021, 1, 1) as an exposure of 1.0
# here we end the interval at Date(2020, 12, 31), so we need to add a day to get the correct exposure fraction.
```

policy_id | issue_date | termination_date | status | policy_year | exposure_fraction
--- | --- | --- | --- | --- | ---
1 | 2020-05-10 | 2022-06-10 | claim | (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)  | 1.0
1 | 2020-05-10 | 2022-06-10 | claim | (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)  | 1.0
1 | 2020-05-10 | 2022-06-10 | claim | (from = Date("2022-05-10"), to = Date("2023-05-09"), policy_timestep = 3)  | 1.0
2 | 2020-04-05 | 2022-08-10 | lapse | (from = Date("2020-04-05"), to = Date("2021-04-04"), policy_timestep = 1)  | 1.0
2 | 2020-04-05 | 2022-08-10 | lapse | (from = Date("2021-04-05"), to = Date("2022-04-04"), policy_timestep = 2)  | 1.0
2 | 2020-04-05 | 2022-08-10 | lapse | (from = Date("2022-04-05"), to = Date("2022-08-10"), policy_timestep = 3)  | 0.35
3 | 2019-03-10 |  | inforce | (from = Date("2020-01-01"), to = Date("2020-03-09"), policy_timestep = 1)  | 0.191667
3 | 2019-03-10 |  | inforce | (from = Date("2020-03-10"), to = Date("2021-03-09"), policy_timestep = 2)  | 1.0
3 | 2019-03-10 |  | inforce | (from = Date("2021-03-10"), to = Date("2022-03-09"), policy_timestep = 3)  | 1.0
3 | 2019-03-10 |  | inforce | (from = Date("2022-03-10"), to = Date("2022-12-31"), policy_timestep = 4)  | 0.808333

## Discussion and Questions

If you have other ideas or questions, feel free to also open an issue, or discuss on the community [Zulip](https://julialang.zulipchat.com/#narrow/stream/249536-actuary) or [Slack #actuary channel](https://slackinvite.julialang.org/). We welcome all actuarial and related disciplines!

### References

- [Experience Study Calculations](https://www.soa.org/globalassets/assets/files/research/experience-study-calculations.pdf) by the Society of Actuaries

### Related Packages

- [actxps](https://github.com/mattheaphy/actxps/), an R package

# API

The exposure function has the following type signature for Anniversary exposures:

```julia
function exposure(
    p::Anniversary,
    from::Date,
    to::Union{Date,Nothing},
    continued_exposure::Bool = false;
    study_start::Union{Date,Nothing} = nothing,
    study_end::Date,
    left_partials::Bool = false,
    right_partials::Bool = true,
)::Vector{NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Int}}}
```

## p, Exposure Basis

### Anniversary

`ExperienceAnalysis.Anniversary(DatePeriod)` will give exposures periods based on the first date. Exposure intervals will fall on anniversaries, `start_date + t * dateperiod`.
`DatePeriod` is a [DatePeriod Type from the Dates standard library](https://github.com/JuliaLang/julia/blob/master/stdlib/Dates/src/types.jl#L35).

```julia
exposure(
    ExperienceAnalysis.Anniversary(Year(1)), # basis
    Date(2020,5,10),                         # from
    Date(2022, 6, 10);                       # to
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)
# returns
# 3-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
#  (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)
#  (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)
#  (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)
```

### Calendar

`ExperienceAnalysis.Calendar(DatePeriod)` will follow calendar periods (e.g. month or year). Quarterly exposures can be created with `Month(3)`, the number of months should divide 12.

```julia
exposure(
    ExperienceAnalysis.Calendar(Year(1)), # basis
    Date(2020,5,10),                      # from
    Date(2022, 6, 10);                    # to
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)
# returns
# 3-element Vector{NamedTuple{(:from, :to), Tuple{Date, Date}}}:
#  (from = Date("2020-05-10"), to = Date("2020-12-31"))
#  (from = Date("2021-01-01"), to = Date("2021-12-31"))
#  (from = Date("2022-01-01"), to = Date("2022-06-10"))
```

### AnniversaryCalendar

`ExperienceAnalysis.AnniversaryCalendar(DatePeriod,DatePeriod)` will split into the smaller of the calendar or policy anniversary period. We can ensure that each exposure interval entirely falls within a single calendar year.

```julia
exposure(
    ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), # basis
    Date(2020,5,10),                                          # from
    Date(2022, 6, 10);                                        # to
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)
# returns
# 5-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
#  (from = Date("2020-05-10"), to = Date("2020-12-31"), policy_timestep = 1)
#  (from = Date("2021-01-01"), to = Date("2021-05-09"), policy_timestep = 1)
#  (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 2)
#  (from = Date("2022-01-01"), to = Date("2022-05-09"), policy_timestep = 2)
#  (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)

```

## `from`, `to`, `study_start`, `study_end`

* `from` is the date the policy was issued
* `to` is the date the policy was terminated, or `nothing` if the policy is still in-force
* `study_start` is the start of the study period, or `nothing` if the study period is unbounded on the left
* `study_end` is the end of the study period

`from` and `study_end` are required to be `Date` types. `to` and `study_start` can be `Date` or `nothing`.

## `continued_exposure`

When doing a lapse study, lapsed policies will be given a full year of exposure in the policy year of the lapse. This is accomplished by setting `continued_exposure = true`. `continued_exposure` is not a keyword argument so that it can support broadcasting.

The continued exposure may extend beyond the end of the study.

```julia
exposure(
    ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), # basis
    Date(2020,5,10),                                          # from
    Date(2022, 6, 10),                                        # to
    true;                                                     # continued_exposure
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)
# returns
# 6-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
#  (from = Date("2020-05-10"), to = Date("2020-12-31"), policy_timestep = 1)
#  (from = Date("2021-01-01"), to = Date("2021-05-09"), policy_timestep = 1)
#  (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 2)
#  (from = Date("2022-01-01"), to = Date("2022-05-09"), policy_timestep = 2)
#  (from = Date("2022-05-10"), to = Date("2022-12-31"), policy_timestep = 3)
#  (from = Date("2023-01-01"), to = Date("2023-05-09"), policy_timestep = 3) # this is the continued exposure
```

## `left_partials` and `right_partials`

Assumptions like lapse rates can have uneven distributions within policy years, so we may only want to look at full policy years. This can be accomplished by setting `left_partials = false` and `right_partials = false`.

See that by default there are partial exposures at the beginning and end of the study period.

```julia
exposure(
    ExperienceAnalysis.Anniversary(Year(1)), # basis
    Date(2019,5,10),                         # from
    Date(2022, 6, 10);                       # to
    study_start = Date(2020, 1, 1),
    study_end = Date(2021, 12, 31)
)

# returns
# 3-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
#  (from = Date("2020-01-01"), to = Date("2020-05-09"), policy_timestep = 1)
#  (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 2)
#  (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 3)
```

But we can remove these partial exposures by setting `left_partials = false` and `right_partials = false`.

```julia
exposure(
    ExperienceAnalysis.Anniversary(Year(1)), # basis
    Date(2019,5,10),                         # from
    Date(2022, 6, 10);                       # to
    study_start = Date(2020, 1, 1),
    study_end = Date(2021, 12, 31),
    left_partials = false,
    right_partials = false
)
# returns
# 1-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
#  (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 2)
```

`Calendar` basis does not have `left_partials` and `right_partials` because the same effect can always be achieved by setting `study_start` and `study_end`.

## Principles

- An exposure means a unit exposed to a particular decrement for an interval of time and that the risk *entered into that interval* exposed to that risk.
- When the decrement of interest occurs during an exposure interval, the exposure continues to the end of the *current* interval.
- Calculating an `AnniversaryCalendar(Year(1),Year(1))` is different than splitting an `Anniversary(Year(1))` or `Calendar(Year(1))` basis due to the prior two bullet points. Two implications of this:
  - Exposures with `AnniversaryCalendar(Year(1),Year(1))` will tend to end sooner than the latter two because the former is by definition split into two periods.
    - This is illustrated by `e2` and `e3` being the same or longer exposures than `e1` in the example below.
  - If you take a `Calendar(Year(1))`/`Anniversary(Year(1))` exposure basis and split it into two pieces split by Anniversary / Calendar breakpoints, you need to take into account that in the latter pieces of exposure the expected claims needs to be reduced by the surviving exposures from the prior interval.
    - This is saying that if you were to divide the last interval in `e3` into two parts, split by the anniversary date, that the second part of that exposure needs to take into account that not all lives in force on `2012-01-01` would survive past the anniversary that splits the interval. Pretend we actually know that the decrement should be `0.01` per day. Then the expected number of claims over the `(from = Date("2012-01-01"), to = Date("2012-12-31"), policy_timestep = missing)` exposure is `1 - 0.99^366 = 0.97474`. If we split the interval and did not take into account the reduced lives entering in the second part of the split exposure, then we would have `1- 0.99 ^191 + 1 - 0.99^175 = 1.6811` expected claims. To correct for this, the second term needs to be adjusted for the amount surviving from the first.
    - It is for this reason that ExperienceAnalysis.jl does not currently provide a way to "split" a `Calendar`/`Anniversary` exposure basis.

Example: Issue: 2011-07-10, death = 2012-06-15, decrement of interest: death

```julia-repl
julia> e1 = exposure(ExperienceAnalysis.AnniversaryCalendar(Year(1),Year(1)),Date(2011,07,10),Date(2012,06,15),true)
2-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2011-07-10"), to = Date("2011-12-31"), policy_timestep = 1)
 (from = Date("2012-01-01"), to = Date("2012-07-09"), policy_timestep = 1)

julia> e2 = exposure(ExperienceAnalysis.Anniversary(Year(1)),Date(2011,07,10),Date(2012,06,15),true)
1-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2011-07-10"), to = Date("2012-07-09"), policy_timestep = 1)

julia> e3 = exposure(ExperienceAnalysis.Calendar(Year(1)),Date(2011,07,10),Date(2012,06,15),true)
2-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Missing}}:
 (from = Date("2011-07-10"), to = Date("2011-12-31"), policy_timestep = missing)
 (from = Date("2012-01-01"), to = Date("2012-12-31"), policy_timestep = missing)
 ```

## Leap Years

When a policy is issued on a leap day (February 29th), it is preferable to have the next policy year start on the 28th. This is as opposed to having the segment begin on March 1st because when the leap year does come around again, we wouldn't want the segment to end on February 29th.

### Example

Exposures are calculated like this:

```julia-repl
julia> exposure(
        py,
        Date(2016, 2, 29),
        Date(2025, 1, 2)
        )
9-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2016-02-29"), to = Date("2017-02-27"), policy_timestep = 1)
 (from = Date("2017-02-28"), to = Date("2018-02-27"), policy_timestep = 2)
 (from = Date("2018-02-28"), to = Date("2019-02-27"), policy_timestep = 3)
 (from = Date("2019-02-28"), to = Date("2020-02-28"), policy_timestep = 4)
 (from = Date("2020-02-29"), to = Date("2021-02-27"), policy_timestep = 5)
 (from = Date("2021-02-28"), to = Date("2022-02-27"), policy_timestep = 6)
 (from = Date("2022-02-28"), to = Date("2023-02-27"), policy_timestep = 7)
 (from = Date("2023-02-28"), to = Date("2024-02-28"), policy_timestep = 8)
 (from = Date("2024-02-29"), to = Date("2025-01-02"), policy_timestep = 9)
```

And **not** like this:

```julia-repl
9-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2016-02-29"), to = Date("2017-02-28"), policy_timestep = 1)
 (from = Date("2017-03-01"), to = Date("2018-02-28"), policy_timestep = 2)
 (from = Date("2018-03-01"), to = Date("2019-02-28"), policy_timestep = 3)
 (from = Date("2019-03-01"), to = Date("2020-02-28"), policy_timestep = 4)
 (from = Date("2020-03-01"), to = Date("2021-02-29"), policy_timestep = 5)
...
```