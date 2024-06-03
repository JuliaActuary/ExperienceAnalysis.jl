@testset "Generated Experience" begin
    # generate samples over a fully leap cycle and 
    # ensure that we can recover a ~100% A/E using a given
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
    q = 1 - (0.6)^(1 / (365.25 * 4)) #  a daily rate for a risk that occurs ~0.05/year on average over a leap cycle 

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
    end



end