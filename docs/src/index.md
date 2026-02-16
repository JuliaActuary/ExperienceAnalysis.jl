# ExperienceAnalysis.jl

Calculate actuarial exposure periods for experience studies.

## Quickstart

```julia
using ExperienceAnalysis, Dates

df = DataFrame(
    policy_id = 1:3,
    issue_date = [Date(2020,5,10), Date(2020,4,5), Date(2019, 3, 10)],
    end_date = [Date(2022, 6, 10), Date(2022, 8, 10), Date(2022,12,31)],
    status = ["claim", "lapse", "inforce"]
)

df.policy_year = exposure.(
    ExperienceAnalysis.Anniversary(Year(1)),
    df.issue_date,
    df.end_date,
    df.status .== "claim"; # continued exposure
    study_start = Date(2020, 1, 1),
    study_end = Date(2022, 12, 31)
)

df = flatten(df, :policy_year)
```

## Exposure Basis

There are three options for calculating the exposure basis:

- [`ExperienceAnalysis.Anniversary(period)`](@ref Anniversary) — exposure periods based on the policy issue date
- [`ExperienceAnalysis.Calendar(period)`](@ref Calendar) — exposure periods aligned to calendar periods (e.g. month or year)
- [`ExperienceAnalysis.AnniversaryCalendar(pol_period, cal_period)`](@ref AnniversaryCalendar) — splits into the smaller of the calendar or policy anniversary period

Where `period` is a [Period Type from the Dates standard library](https://docs.julialang.org/en/v1/stdlib/Dates/#Period-Types).

### Anniversary

`ExperienceAnalysis.Anniversary(DatePeriod)` gives exposure periods based on the issue date. Exposure intervals fall on anniversaries: `start_date + t * dateperiod`.

```julia-repl
julia> exposure(
           ExperienceAnalysis.Anniversary(Year(1)),
           Date(2020,5,10),
           Date(2022, 6, 10);
           study_start = Date(2020, 1, 1),
           study_end = Date(2022, 12, 31)
       )
3-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)
 (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)
 (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)
```

### Calendar

`ExperienceAnalysis.Calendar(DatePeriod)` follows calendar periods (e.g. month or year). Quarterly exposures can be created with `Month(3)` — the number of months should divide 12.

```julia-repl
julia> exposure(
           ExperienceAnalysis.Calendar(Year(1)),
           Date(2020,5,10),
           Date(2022, 6, 10);
           study_start = Date(2020, 1, 1),
           study_end = Date(2022, 12, 31)
       )
3-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Nothing}}:
 (from = Date("2020-05-10"), to = Date("2020-12-31"), policy_timestep = nothing)
 (from = Date("2021-01-01"), to = Date("2021-12-31"), policy_timestep = nothing)
 (from = Date("2022-01-01"), to = Date("2022-06-10"), policy_timestep = nothing)
```

### AnniversaryCalendar

`ExperienceAnalysis.AnniversaryCalendar(DatePeriod, DatePeriod)` splits into the smaller of the calendar or policy anniversary period, ensuring each exposure interval falls entirely within a single calendar year.

```julia-repl
julia> exposure(
           ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)),
           Date(2020,5,10),
           Date(2022, 6, 10);
           study_start = Date(2020, 1, 1),
           study_end = Date(2022, 12, 31)
       )
5-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-05-10"), to = Date("2020-12-31"), policy_timestep = 1)
 (from = Date("2021-01-01"), to = Date("2021-05-09"), policy_timestep = 1)
 (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 2)
 (from = Date("2022-01-01"), to = Date("2022-05-09"), policy_timestep = 2)
 (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)
```

## Parameters

### `from`, `to`, `study_start`, `study_end`

- `from` — the date the policy was issued
- `to` — the date the policy was terminated, or the last observed date if still in-force
- `study_start` — the start of the study period
- `study_end` — the end of the study period

### `continued_exposure`

When doing a decrement study, policies are given a full exposure period in the period of the decrement. Set `continued_exposure = true` for this behavior. Note that `continued_exposure` is a positional argument (not keyword) so it supports broadcasting.

```julia-repl
julia> exposure(
           ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)),
           Date(2020,5,10),
           Date(2022, 6, 10),
           true;
           study_start = Date(2020, 1, 1),
           study_end = Date(2022, 9, 30)
       )
5-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-05-10"), to = Date("2020-12-31"), policy_timestep = 1)
 (from = Date("2021-01-01"), to = Date("2021-05-09"), policy_timestep = 1)
 (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 2)
 (from = Date("2022-01-01"), to = Date("2022-05-09"), policy_timestep = 2)
 (from = Date("2022-05-10"), to = Date("2022-12-31"), policy_timestep = 3)
```

### `left_partials` and `right_partials`

Assumptions like lapse rates can have uneven distributions within policy years, so you may want to exclude partial exposure periods. Set `left_partials = false` and/or `right_partials = false` to remove partial exposures at the study boundaries.

```julia-repl
julia> exposure(
           ExperienceAnalysis.Anniversary(Year(1)),
           Date(2019,5,10),
           Date(2022, 6, 10);
           study_start = Date(2020, 1, 1),
           study_end = Date(2021, 12, 31),
           left_partials = false,
           right_partials = false
       )
2-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 2)
 (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 3)
```

## References

- [Experience Study Calculations](https://www.soa.org/globalassets/assets/files/research/experience-study-calculations.pdf) by the Society of Actuaries

## Related Packages

- [actxps](https://github.com/mattheaphy/actxps/), an R package
