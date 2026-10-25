# ExperienceAnalysis
![](https://github.com/JuliaActuary/LifeContingencies.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActuary/ExperienceAnalysis.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActuary/ExperienceAnalysis.jl)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.juliaactuary.org/ExperienceAnalysis/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://docs.juliaactuary.org/ExperienceAnalysis/dev/)


Calculate exposures.

## Quickstart

```julia
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

df.exposure_fraction =
        map(e -> yearfrac(e.from, e.to + Day(1), DayCounts.Thirty360()), df.policy_year) 
# + Day(1) above because DayCounts has Date(2020, 1, 1) to Date(2021, 1, 1) as an exposure of 1.0
# here we end the interval at Date(2020, 12, 31), so we need to add a day to get the correct exposure fraction.
```

| **policy\_id**<br>`Int64` | **issue\_date**<br>`Date` | **end\_date**<br>`Date` | **status**<br>`String` | **policy\_year**<br>`@NamedTuple{from::Date, to::Date, policy\_timestep::Int64}` | **exposure\_fraction**<br>`Float64` |
|--------------------------:|--------------------------:|------------------------:|-----------------------:|---------------------------------------------------------------------------------:|------------------------------------:|
| 1                         | 2020-05-10                | 2022-06-10              | claim                  | (from = Date("2020-05-10"), to = Date("2021-05-09"), policy\_timestep = 1)       | 1.0                                 |
| 1                         | 2020-05-10                | 2022-06-10              | claim                  | (from = Date("2021-05-10"), to = Date("2022-05-09"), policy\_timestep = 2)       | 1.0                                 |
| 1                         | 2020-05-10                | 2022-06-10              | claim                  | (from = Date("2022-05-10"), to = Date("2023-05-09"), policy\_timestep = 3)       | 1.0                                 |
| 2                         | 2020-04-05                | 2022-08-10              | lapse                  | (from = Date("2020-04-05"), to = Date("2021-04-04"), policy\_timestep = 1)       | 1.0                                 |
| 2                         | 2020-04-05                | 2022-08-10              | lapse                  | (from = Date("2021-04-05"), to = Date("2022-04-04"), policy\_timestep = 2)       | 1.0                                 |
| 2                         | 2020-04-05                | 2022-08-10              | lapse                  | (from = Date("2022-04-05"), to = Date("2022-08-10"), policy\_timestep = 3)       | 0.35                                |
| 3                         | 2019-03-10                | 2022-12-31              | inforce                | (from = Date("2020-01-01"), to = Date("2020-03-09"), policy\_timestep = 1)       | 0.191667                            |
| 3                         | 2019-03-10                | 2022-12-31              | inforce                | (from = Date("2020-03-10"), to = Date("2021-03-09"), policy\_timestep = 2)       | 1.0                                 |
| 3                         | 2019-03-10                | 2022-12-31              | inforce                | (from = Date("2021-03-10"), to = Date("2022-03-09"), policy\_timestep = 3)       | 1.0                                 |
| 3                         | 2019-03-10                | 2022-12-31              | inforce                | (from = Date("2022-03-10"), to = Date("2022-12-31"), policy\_timestep = 4)       | 0.808333                            |


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
    p::AnniversaryCalendar,
    from::Date,
    to::Date,
    continued_exposure=false;
    study_start::Date=typemin(from),
    study_end::Date=typemax(from),
    left_partials::Bool=true,
    right_partials::Bool=true,
)
```

## p, Exposure Basis

In summary, there's three options for calculating the basis:

- `ExperienceAnalysis.Anniversary(period)` will give exposures periods based on the first date
- `ExperienceAnalysis.Calendar(period)` will follow calendar periods (e.g. month or year)
- `ExperienceAnalysis.AnniversaryCalendar(period,period)` will split into the smaller of the calendar or policy period.

Where `period` is a [Period Type from the Dates standard library](https://docs.julialang.org/en/v1/stdlib/Dates/#Period-Types).

### Anniversary

`ExperienceAnalysis.Anniversary(DatePeriod)` will give exposures periods based on the first date. Exposure intervals will fall on anniversaries, `start_date + t * dateperiod`.
`DatePeriod` is a [DatePeriod Type from the Dates standard library](https://github.com/JuliaLang/julia/blob/master/stdlib/Dates/src/types.jl#L35).

```julia-repl
julia> exposure(
           ExperienceAnalysis.Anniversary(Year(1)), # basis
           Date(2020,5,10),                         # from
           Date(2022, 6, 10);                       # to
           study_start = Date(2020, 1, 1),
           study_end = Date(2022, 12, 31)
       )
3-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)
 (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)
 (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)
```

### Calendar

`ExperienceAnalysis.Calendar(DatePeriod)` will follow calendar periods (e.g. month or year). Quarterly exposures can be created with `Month(3)`, the number of months should divide 12.

```julia-repl
julia> exposure(
           ExperienceAnalysis.Calendar(Year(1)), # basis
           Date(2020,5,10),                      # from
           Date(2022, 6, 10);                    # to
           study_start = Date(2020, 1, 1),
           study_end = Date(2022, 12, 31)
       )
3-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Nothing}}:
 (from = Date("2020-05-10"), to = Date("2020-12-31"), policy_timestep = nothing)
 (from = Date("2021-01-01"), to = Date("2021-12-31"), policy_timestep = nothing)
 (from = Date("2022-01-01"), to = Date("2022-06-10"), policy_timestep = nothing)
```

### AnniversaryCalendar

`ExperienceAnalysis.AnniversaryCalendar(DatePeriod,DatePeriod)` will split into the smaller of the calendar or policy anniversary period. We can ensure that each exposure interval entirely falls within a single calendar year.

```julia
julia> exposure(
           ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), # basis
           Date(2020,5,10),                                          # from
           Date(2022, 6, 10);                                        # to
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

## `from`, `to`, `study_start`, `study_end`

* `from` is the date the policy was issued
* `to` is the date the policy was terminated, the last observed date of the policy if still in-force
* `study_start` is the start of the study period
* `study_end` is the end of the study period

`from` and `study_end` are required to be `Date` types. `to` and `study_start` can be `Date` or `nothing`.

## `continued_exposure`

When doing a decrement study, policies will be given a full exposure period in the period of the decrement. This is accomplished by setting `continued_exposure = true`. `continued_exposure` is not a keyword argument so that it can support broadcasting.

The continued exposure may extend beyond the end of the study.

```julia-repl
julia> exposure(
           ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), # basis
           Date(2020,5,10),                                          # from
           Date(2022, 6, 10),                                        # to
           true;                                                     # continued_exposure
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

## `left_partials` and `right_partials`

Assumptions like lapse rates can have uneven distributions within policy years, so we may only want to look at full policy years. This can be accomplished by setting `left_partials = false` and `right_partials = false`.

See that by default there are partial exposures at the beginning and end of the study period.

```julia-repl
julia> exposure(
           ExperienceAnalysis.Anniversary(Year(1)), # basis
           Date(2019,5,10),                         # from
           Date(2022, 6, 10);                       # to
           study_start = Date(2020, 1, 1),
           study_end = Date(2021, 12, 31)
       )
3-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-01-01"), to = Date("2020-05-09"), policy_timestep = 1)
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 2)
 (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 3)
```

But we can remove these partial exposures by setting `left_partials = false` and `right_partials = false`.

```julia-repl
julia> exposure(
           ExperienceAnalysis.Anniversary(Year(1)), # basis
           Date(2019,5,10),                         # from
           Date(2022, 6, 10);                       # to
           study_start = Date(2020, 1, 1),
           study_end = Date(2021, 12, 31),
           left_partials = false,
           right_partials = false
       )
2-element Vector{@NamedTuple{from::Date, to::Date, policy_timestep::Int64}}:
 (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 2)
 (from = Date("2021-05-10"), to = Date("2021-12-31"), policy_timestep = 3)
```

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

## Example of Actual to Expected Analysis

```julia
# generate samples over a full leap cycle and 
# show that we recover a ~100% A/E using a given
# assumption

println("------------------")
println("generating simulated experience")

using ExperienceAnalysis
using Dates
using DayCounts
using Distributions
using DataFramesMeta
using StableRNGs

rng = StableRNG(123)
q = 1 - (0.6)^(1 / (365.25 * 4)) #  a daily rate for a risk that occurs ~0.1/year on average over a leap cycle 

# simulate n policies and when they die using the above q
# set the end date for the study four years in, covering a whole leap cycle
# and presume we don't know data beyond that date
n = 1 * 10^6
years = 4
d_start = Date(2011, 1, 1)
d_end = d_start + Year(years) - Day(1)
census = map(1:n) do id
    issue = rand(rng, d_start:Day(1):Dates.lastdayofyear(d_start))
    death = issue + Day(rand(rng, Geometric(q)))
    (; id, issue, death)

end |> DataFrame

# calculate (1, 2) grouped over pol/cal years and  (3) total actual to expected

basis = [
    ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)),
    ExperienceAnalysis.Calendar(Year(1)),
    ExperienceAnalysis.Anniversary(Year(1))
]

for b in basis
    @show b
    cp = let cp = deepcopy(census) # copy to avoid messing with generated data

        cp.exposures = exposure.(
            b,
            census.issue,
            min.(d_end, census.death),
            census.death .<= d_end;
            study_end=d_end
        )

        cp = flatten(cp, :exposures)

        # did claim happen before cutoff
        cp.claim = map(cp.exposures, cp.death) do e, d
            e.from <= d <= e.to
        end

        cp.exp_days = map(cp.exposures) do e
            length(e.from:Day(1):e.to)
        end
        cp.expected = @. 1 - (1 - q)^cp.exp_days

        cp.cal_year = map(cp.exposures) do e
            year(e.from)
        end

        cp.pol_year = map(cp.exposures, cp.issue) do e, i
            y = year(e.from)
            if monthday(e.from) < monthday(i)
                y -= 1
            end
            y
        end

        cp.exp_amt = map(cp.exposures) do e
            yearfrac(e.from, e.to + Day(1), DayCounts.ActualActualISDA())
        end
        cp

    end

    # not needed for test, but demonstrates how to do cal/pol year grouping
    summary = map([:pol_year, :cal_year]) do grouping
        combine(groupby(cp, (grouping))) do gdf
            exposures = sum(gdf.exp_amt)
            claims = sum(gdf.claim)
            expected = sum(gdf.expected)

            q̂ = claims / exposures
            ae = claims / expected

            (; claims, expected, exposures, q̂, ae)
        end
    end


    @show summary
    @show sum(cp.claim) / sum(cp.expected), sum(cp.claim), sum(cp.expected), sum(cp.exp_days), sum(cp.exp_amt)
    @test sum(cp.claim) / sum(cp.expected) ≈ 1.0 rtol = 5e-3
    println("---------")
```

This produces the following output, showing an actual-to-expected result for three different exposure basis as well as being on a calendar and policy-year basis:

```
------------------
generating simulated experience
b = ExperienceAnalysis.AnniversaryCalendar{Year, Year}(Year(1), Year(1))
summary = DataFrame[4×6 DataFrame
 Row │ pol_year  claims  expected       exposures  q̂         ae
     │ Int64     Int64   Float64        Float64    Float64   Float64
─────┼────────────────────────────────────────────────────────────────
   1 │     2011  120715      1.20055e5  9.80143e5  0.123161  1.00549
   2 │     2012  104919      1.05409e5  8.60476e5  0.121931  0.995354
   3 │     2013   92578  92780.8        7.58434e5  0.122065  0.997814
   4 │     2014   41861  41870.8        3.42226e5  0.12232   0.999766, 4×6 DataFrame
 Row │ cal_year  claims  expected       exposures  q̂         ae
     │ Int64     Int64   Float64        Float64    Float64   Float64
─────┼────────────────────────────────────────────────────────────────
   1 │     2011   61471  61363.9        5.01539e5  0.122565  1.00174
   2 │     2012  112712      1.12714e5  9.18968e5  0.122651  0.999981
   3 │     2013   98760  98928.2        8.0869e5   0.122123  0.9983
   4 │     2014   87130  87109.4        7.12082e5  0.122359  1.00024]
(sum(cp.claim) / sum(cp.expected), sum(cp.claim), sum(cp.expected), sum(cp.exp_days), sum(cp.exp_amt)) = (0.9998814228722663, 360073, 360115.70148553397, 1074485834, 2.941279085822292e6)
---------
b = ExperienceAnalysis.AnniversaryCalendar{Nothing, Year}(nothing, Year(1))
summary = DataFrame[4×6 DataFrame
 Row │ pol_year  claims  expected       exposures      q̂         ae
     │ Int64     Int64   Float64        Float64        Float64   Float64
─────┼────────────────────────────────────────────────────────────────────
   1 │     2011  173896      1.73803e5       1.4376e6  0.120963  1.00054
   2 │     2012   98793  98977.4        826104.0       0.119589  0.998137
   3 │     2013   87161  87140.1        727311.0       0.11984   1.00024
   4 │     2014     223    230.637        1925.0       0.115844  0.966888, 4×6 DataFrame
 Row │ cal_year  claims  expected       exposures       q̂         ae
     │ Int64     Int64   Float64        Float64         Float64   Float64
─────┼─────────────────────────────────────────────────────────────────────
   1 │     2011   61471  61363.9             5.01539e5  0.122565  1.00174
   2 │     2012  112712      1.12735e5  938529.0        0.120094  0.999794
   3 │     2013   98760  98942.2        825817.0        0.119591  0.998158
   4 │     2014   87130  87109.7        727057.0        0.119839  1.00023]
(sum(cp.claim) / sum(cp.expected), sum(cp.claim), sum(cp.expected), sum(cp.exp_days), sum(cp.exp_amt)) = (0.9997833363330586, 360073, 360151.03164316854, 1093362393, 2.9929420931506846e6)
---------
b = ExperienceAnalysis.AnniversaryCalendar{Year, Nothing}(Year(1), nothing)
summary = DataFrame[4×6 DataFrame
 Row │ pol_year  claims  expected       exposures       q̂         ae
     │ Int64     Int64   Float64        Float64         Float64   Float64
─────┼─────────────────────────────────────────────────────────────────────
   1 │     2011  120715      1.20069e5       1.00093e6  0.120603  1.00538
   2 │     2012  104919      1.05392e5       8.78469e5  0.119434  0.99551
   3 │     2013   92578  92777.8        774366.0        0.119553  0.997846
   4 │     2014   41861  43496.8             3.5624e5   0.117508  0.962393, 4×6 DataFrame
 Row │ cal_year  claims  expected       exposures       q̂         ae
     │ Int64     Int64   Float64        Float64         Float64   Float64
─────┼─────────────────────────────────────────────────────────────────────
   1 │     2011  120715      1.20069e5       1.00093e6  0.120603  1.00538
   2 │     2012  104919      1.05392e5       8.78469e5  0.119434  0.99551
   3 │     2013   92578  92777.8        774366.0        0.119553  0.997846
   4 │     2014   41861  43496.8             3.5624e5   0.117508  0.962393]
(sum(cp.claim) / sum(cp.expected), sum(cp.claim), sum(cp.expected), sum(cp.exp_days), sum(cp.exp_amt)) = (0.9954028354972483, 360073, 361735.9597133631, 1099590758, 3.01000275415076e6)
---------
```

## Documentation

You can access the help text in the REPL (`?exposure`)  or your editor. 

`exposure` docstring:
>```  
>    exposure(
>        p::Anniversary,
>        from::Date,
>        to::Date,
>        continued_exposure::Bool = false;
>        study_start=typemin(from),
>        study_end=typemax(from),
>        left_partials::Bool=true,
>        right_partials::Bool=true,
>    )::Vector{NamedTuple{(:from, :to, :policy_timestep),Tuple{Date,Date,Union{Int,Nothing}}}}
>```
>
>Calcualte the exposure periods and returns an array of named tuples with fields:
>- `from` (a `Date`) is the start date of the exposure interval
>- `to` (a `Date`) is the end of the exposure interval
>- `policy_step` will either be an `Int` if an Anniversary or AnniversaryCalendar basis is used, otherwise will be `nothing`
>
>If `continued_exposure` is `true`, then the final `to` date will continue through the end of the final exposure period. This is useful if you want the decrement of interest is the cause of termination, because then you want a full exposure.
>
>If `left_partials` or `right_partials` is set to false, then the exposure will not return partial exposure periods that overlap with the `study_start` and `study_end` respectively.
>
># Example
>
>```julia-repl
>julia> using ExperienceAnalysis,Dates
>julia> exposure(
>    ExperienceAnalysis.Anniversary(Year(1)), # basis
>    Date(2020,5,10),                         # issue
>    Date(2022, 6, 10);                       # termination
>)
>3-element Vector{NamedTuple{(:from, :to, :policy_timestep), Tuple{Date, Date, Int64}}}:
> (from = Date("2020-05-10"), to = Date("2021-05-09"), policy_timestep = 1)
> (from = Date("2021-05-10"), to = Date("2022-05-09"), policy_timestep = 2)
> (from = Date("2022-05-10"), to = Date("2022-06-10"), policy_timestep = 3)
