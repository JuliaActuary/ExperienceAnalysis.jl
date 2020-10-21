# ExperienceAnalysis
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaActuary.github.io/ExperienceAnalysis.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaActuary.github.io/ExperienceAnalysis.jl/dev)
![](https://github.com/JuliaActuary/LifeContingencies.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActuary/ExperienceAnalysis.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActuary/ExperienceAnalysis.jl)
[![lifecycle](https://img.shields.io/badge/LifeCycle-Experimental-orange)](https://www.tidyverse.org/lifecycle/)

Calculate exposures.

## Quickstart

```julia
using ExperienceAnalysis
using Dates

issue = Date(2016, 7, 4)
termination = Date(2020, 1, 17)
basis = ExperienceAnalysis.Anniversary(Year(1))
exposure(basis, issue, termination)
```
This will return an array of tuples with a `from` and `to` date:

```julia
4-element Array{NamedTuple{(:from, :to),Tuple{Date,Date}},1}:
 (from = Date("2016-07-04"), to = Date("2017-07-04"))
 (from = Date("2017-07-04"), to = Date("2018-07-04"))
 (from = Date("2018-07-04"), to = Date("2019-07-04"))
 (from = Date("2019-07-04"), to = Date("2020-01-17"))
```

## Available Exposure Basis

- `ExperienceAnalysis.Anniversary(period)` will give exposures periods based on the first date
- `ExperienceAnalysis.Calendar(period)` will follow calendar periods (e.g. month or year)
- `ExperienceAnalysis.AnniversaryCalendar(period,period)` will split into the smaller of the calendar or policy anniversary period.

Where `period` is a [Period Type from the Dates standard library](https://docs.julialang.org/en/v1/stdlib/Dates/#Period-Types).

Calculate exposures with `exposures(basis,from,to,continue_exposure)`. 

- `continue_exposures` indicates whether the exposure should be extended through the full exposure period rather than terminate at the `to` date.

## Full Example


We'll start with this as our data:
```julia
julia> df

3×4 DataFrame
│ Row │ id     │ issue      │ termination │ status  │
│     │ String │ Date       │ Date?       │ String  │
├─────┼────────┼────────────┼─────────────┼─────────┤
│ 1   │ 1      │ 2016-07-04 │ 2020-01-17  │ Claim   │
│ 2   │ 2      │ 2016-01-01 │ 2018-05-04  │ Lapse   │
│ 3   │ 3      │ 2016-01-01 │ missing     │ Inforce │
```

Define the study end:

```julia
study_end = Date(2020,12,31)
```

Next, we do two things by iterating over and creating a new array of dates:

1. Handle the `missing` case by letting the `to` reflect the `study_end`
2. Cap the ending date at the `study_end`. This doesn't come into play in this example, but it's included for demonstration purposes.

```julia
to = [ismissing(d) ? study_end : min(study_end,d) for d in df.termination]
```

Calculate the exposure by [broadcasting](https://docs.julialang.org/en/v1/manual/mathematical-operations/#man-dot-operators) the exposure function over the three arrays we are passing to it: 

```julia
df.exposure = exposure.(
    ExperienceAnalysis.Anniversary(Year(1)),   # The basis for our exposures
    df.issue,                             # The `from` date
    to                                    # the `to` date array we created above
    )
```

In our dataframe, we actually have a column that contains an array of tuples now, so to expand it so that each exposure period gets a row, we `flatten` the dataframe:

```julia
df = flatten(df,:exposure)
```

So now we have our exposures:

```julia
│ id     │ issue      │ termination │ status  │ exposure                                             │
│ String │ Date       │ Date?       │ String  │ NamedTuple{(:from, :to),Tuple{Date,Date}}            │
┼────────┼────────────┼─────────────┼─────────┼──────────────────────────────────────────────────────┼
│ 1      │ 2016-07-04 │ 2020-01-17  │ Claim   │ (from = Date("2016-07-04"), to = Date("2017-07-04")) │
│ 1      │ 2016-07-04 │ 2020-01-17  │ Claim   │ (from = Date("2017-07-04"), to = Date("2018-07-04")) │
│ 1      │ 2016-07-04 │ 2020-01-17  │ Claim   │ (from = Date("2018-07-04"), to = Date("2019-07-04")) │
│ 1      │ 2016-07-04 │ 2020-01-17  │ Claim   │ (from = Date("2019-07-04"), to = Date("2020-01-17")) │
│ 2      │ 2016-01-01 │ 2018-05-04  │ Lapse   │ (from = Date("2016-01-01"), to = Date("2017-01-01")) │
│ 2      │ 2016-01-01 │ 2018-05-04  │ Lapse   │ (from = Date("2017-01-01"), to = Date("2018-01-01")) │
│ 2      │ 2016-01-01 │ 2018-05-04  │ Lapse   │ (from = Date("2018-01-01"), to = Date("2018-05-04")) │
│ 3      │ 2016-01-01 │ missing     │ Inforce │ (from = Date("2016-01-01"), to = Date("2017-01-01")) │
│ 3      │ 2016-01-01 │ missing     │ Inforce │ (from = Date("2017-01-01"), to = Date("2018-01-01")) │
│ 3      │ 2016-01-01 │ missing     │ Inforce │ (from = Date("2018-01-01"), to = Date("2019-01-01")) │
│ 3      │ 2016-01-01 │ missing     │ Inforce │ (from = Date("2019-01-01"), to = Date("2020-01-01")) │
│ 3      │ 2016-01-01 │ missing     │ Inforce │ (from = Date("2020-01-01"), to = Date("2020-12-31")) │
```


### Exposure Fraction
This can be extended to calculate the decimal fraction of the year under different day count conventions, such as assuming 30/360 or Actual/365, etc. using the [`DayCounts.jl` package](https://github.com/JuliaFinance/DayCounts.jl).

```julia
using DayCounts

df.exposure_fraction = map(e -> yearfrac(e.from,e.to,DayCounts.Actual360()),df.exposure)
```

So now we have:

```julia
│ exposure                                             │ exposure_fraction │
│ NamedTuple{(:from, :to),Tuple{Date,Date}}            │ Float64           │
┼──────────────────────────────────────────────────────┼───────────────────┤
│ (from = Date("2016-07-04"), to = Date("2017-07-04")) │ 1.01389           │
│ (from = Date("2017-07-04"), to = Date("2018-07-04")) │ 1.01389           │
│ (from = Date("2018-07-04"), to = Date("2019-07-04")) │ 1.01389           │
│ (from = Date("2019-07-04"), to = Date("2020-07-04")) │ 0.54722           │
│ (from = Date("2016-01-01"), to = Date("2017-01-01")) │ 1.01667           │
│ (from = Date("2017-01-01"), to = Date("2018-01-01")) │ 1.01389           │
│ (from = Date("2018-01-01"), to = Date("2018-05-04")) │ 0.34167           │
│ (from = Date("2016-01-01"), to = Date("2017-01-01")) │ 1.01667           │
│ (from = Date("2017-01-01"), to = Date("2018-01-01")) │ 1.01389           │
│ (from = Date("2018-01-01"), to = Date("2019-01-01")) │ 1.01389           │
│ (from = Date("2019-01-01"), to = Date("2020-01-01")) │ 1.01389           │
│ (from = Date("2020-01-01"), to = Date("2020-12-31")) │ 1.01389           │
```

### Continued Exposure

To get the proper exposure for the termination type under consideration, `exposure` takes an optional fourth argument which will continue the exposure until the end of what would be the period notwithstanding the termination.

Extending the above analysis, we want a full exposure period for any `"Claim"` in this case:

```julia
continue_exposure = df.status .== "Claim"

df.exposure = exposure.(
    ExperienceAnalysis.Anniversary(Year(1)),   # The basis for our exposures
    df.issue,                             # The `from` date
    to,                                   # the `to` date array we created above
    continue_exposure                     # full exposure or not (true/false)
    )
```

And then the exposures look like the following. Note the difference in the fourth row:

```julia
│ exposure                                             │ exposure_fraction │
│ NamedTuple{(:from, :to),Tuple{Date,Date}}            │ Float64           │
┼──────────────────────────────────────────────────────┼───────────────────┤
│ (from = Date("2016-07-04"), to = Date("2017-07-04")) │ 1.01389           │
│ (from = Date("2017-07-04"), to = Date("2018-07-04")) │ 1.01389           │
│ (from = Date("2018-07-04"), to = Date("2019-07-04")) │ 1.01389           │
│ (from = Date("2019-07-04"), to = Date("2020-07-04")) │ 1.01667           │
│ (from = Date("2016-01-01"), to = Date("2017-01-01")) │ 1.01667           │
│ (from = Date("2017-01-01"), to = Date("2018-01-01")) │ 1.01389           │
│ (from = Date("2018-01-01"), to = Date("2018-05-04")) │ 0.341667          │
│ (from = Date("2016-01-01"), to = Date("2017-01-01")) │ 1.01667           │
│ (from = Date("2017-01-01"), to = Date("2018-01-01")) │ 1.01389           │
│ (from = Date("2018-01-01"), to = Date("2019-01-01")) │ 1.01389           │
│ (from = Date("2019-01-01"), to = Date("2020-01-01")) │ 1.01389           │
│ (from = Date("2020-01-01"), to = Date("2020-12-31")) │ 1.01389           │
```

### Study End/Start dates

The examples above already incorporated the study end date. However, the study start date must be truncated as a post-processing step. This is because the `to` argument to the `exposure(...)` function defines the anchor point for the policy anniversary iteration. If the `to` was the study start date, then the anniversaries would follow that calendar date.

To truncate the exposures, you would need to drop/update exposures. Continuing the example above:

```julia
study_start = Date(2017,1,1)

# drop rows where the whole expsoure is before the study_start
df_truncated = filter(row -> row.exposure.to >= study_start,df)

# update the `from` where remaining exposures start before the study_start
df_truncated.exposure = map(e -> (from = max(study_start,e.from),to = e.to), df_truncated.exposure)
```

And then `df_truncated` contains:

```julia
│ exposure                                             │
│ NamedTuple{(:from, :to),Tuple{Date,Date}}            │
┼──────────────────────────────────────────────────────┼
│ (from = Date("2017-01-01"), to = Date("2017-07-04")) │
│ (from = Date("2017-07-04"), to = Date("2018-07-04")) │
│ (from = Date("2018-07-04"), to = Date("2019-07-04")) │
│ (from = Date("2019-07-04"), to = Date("2020-07-04")) │
│ (from = Date("2017-01-01"), to = Date("2017-01-01")) │
│ (from = Date("2017-01-01"), to = Date("2018-01-01")) │
│ (from = Date("2018-01-01"), to = Date("2018-05-04")) │
│ (from = Date("2017-01-01"), to = Date("2017-01-01")) │
│ (from = Date("2017-01-01"), to = Date("2018-01-01")) │
│ (from = Date("2018-01-01"), to = Date("2019-01-01")) │
│ (from = Date("2019-01-01"), to = Date("2020-01-01")) │
│ (from = Date("2020-01-01"), to = Date("2020-12-31")) │
```

Last item to note is that you need to recalculate the `exposure_fraction` as it currently reflects the pre-truncated values. When actually building a process, you could truncate before calculating the fraction to begin with.


## Discussion and Questions

If you have other ideas or questions, feel free to also open an issue, or discuss on the community [Zulip](https://julialang.zulipchat.com/#narrow/stream/249536-actuary) or [Slack #actuary channel](https://slackinvite.julialang.org/). We welcome all actuarial and related disciplines!

## Endnotes

### References

- [Experience Study Calculations](https://www.soa.org/globalassets/assets/files/research/experience-study-calculations.pdf) by the Society of Actuaries

### Related Packages

- [expstudies](https://github.com/MatthewCaseres/expstudies), an R package