using ExperienceAnalysis
using Test
using Dates

@testset "Anniversary" begin
    issue = Date(2016, 7, 4)
    termination = Date(2020, 1, 17)

    @testset "Year" begin
        exp = exposure(ExperienceAnalysis.Anniversary(Year(1)), issue, termination)

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2017, 7, 3), policy_timestep = 1)
        @test exp[end] == (from = Date(2019, 7, 4), to = Date(2020, 1, 17), policy_timestep = 4)
    end

    @testset "Year with full exp" begin
        exp = exposure(ExperienceAnalysis.Anniversary(Year(1)), issue, termination, true)

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2017, 7, 3), policy_timestep = 1)
        @test exp[end] == (from = Date(2019, 7, 4), to = Date(2020, 7, 3), policy_timestep = 4)
    end

    @testset "Month" begin
        exp = exposure(ExperienceAnalysis.Anniversary(Month(1)), issue, termination)

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 8, 3), policy_timestep = 1)
        @test exp[end] == (from = Date(2020, 1, 4), to = Date(2020, 1, 17), policy_timestep = 43)
    end
end

@testset "Calendar" begin
    issue = Date(2016, 7, 4)
    termination = Date(2020, 1, 17)

    @testset "Year" begin
        exp = exposure(ExperienceAnalysis.Calendar(Year(1)), issue, termination)

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 12, 31))
        @test exp[2] == (from = Date(2017, 1, 1), to = Date(2017, 12, 31))
        @test exp[end] == (from = Date(2020, 1, 1), to = Date(2020, 1, 17))
    end

    @testset "Year with full exp" begin
        exp = exposure(ExperienceAnalysis.Calendar(Year(1)), issue, termination, true)

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 12, 31))
        @test exp[2] == (from = Date(2017, 1, 1), to = Date(2017, 12, 31))
        @test exp[end] == (from = Date(2020, 1, 1), to = Date(2020, 12, 31))
    end

    @testset "Month" begin
        exp = exposure(ExperienceAnalysis.Calendar(Month(1)), issue, termination)

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 7, 31))
        @test exp[2] == (from = Date(2016, 8, 1), to = Date(2016, 8, 31))
        @test exp[end] == (from = Date(2020, 1, 1), to = Date(2020, 1, 17))
    end
end


@testset "AnniversaryCalendar" begin
    issue = Date(2016, 7, 4)
    termination = Date(2020, 1, 17)

    @testset "Year/Year" begin
        exp = exposure(
            ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)),
            issue,
            termination,
        )

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 12, 31), policy_timestep = 1)
        @test exp[2] == (from = Date(2017, 1, 1), to = Date(2017, 7, 3), policy_timestep = 1)
        @test exp[end] == (from = Date(2020, 1, 1), to = Date(2020, 1, 17), policy_timestep = 4)
    end

    @testset "Year/Year with full exp" begin
        exp = exposure(
            ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)),
            issue,
            termination,
            true,
        )

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 12, 31), policy_timestep = 1)
        @test exp[2] == (from = Date(2017, 1, 1), to = Date(2017, 7, 3), policy_timestep = 1)
        @test exp[end] == (from = Date(2020, 1, 1), to = Date(2020, 7, 3), policy_timestep = 4)
    end


    @testset "Month/Year" begin
        exp = exposure(
            ExperienceAnalysis.AnniversaryCalendar(Month(1), Year(1)),
            issue,
            termination,
        )

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 8, 3), policy_timestep = 1)
        @test exp[6] == (from = Date(2016, 12, 4), to = Date(2016, 12, 31), policy_timestep = 6)
        @test exp[7] == (from = Date(2017, 1, 1), to = Date(2017, 1, 3), policy_timestep = 6)
        @test exp[end] == (from = Date(2020, 1, 4), to = Date(2020, 1, 17), policy_timestep = 43)
    end

    @testset "Month/Month" begin
        exp = exposure(
            ExperienceAnalysis.AnniversaryCalendar(Month(1), Month(1)),
            issue,
            termination,
        )

        @test exp[1] == (from = Date(2016, 7, 4), to = Date(2016, 7, 31), policy_timestep = 1)
        @test exp[2] == (from = Date(2016, 8, 1), to = Date(2016, 8, 3), policy_timestep = 1)
        @test exp[end] == (from = Date(2020, 1, 4), to = Date(2020, 1, 17), policy_timestep = 43)
    end
end

@testset "from > to throws error" begin
    @test_throws DomainError exposure(
        ExperienceAnalysis.Anniversary(Year(1)),
        Date(2020, 1, 17),
        Date(2016, 7, 4),
    )
    @test_throws DomainError exposure(
        ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)),
        Date(2020, 1, 17),
        Date(2016, 7, 4),
    )
    @test_throws DomainError exposure(
        ExperienceAnalysis.Calendar(Year(1)),
        Date(2020, 1, 17),
        Date(2016, 7, 4),
    )
end


@testset "Experience Study Calculations" begin
    # https://www.soa.org/globalassets/assets/files/research/experience-study-calculations.pdf

    @testset "Section 4.3.1" begin
        lives = [
            (start = Date(2010, 5, 10), termination = nothing, status = "Inforce"),
            (start = Date(2010, 9, 27), termination = Date(2012, 2, 16), status = "Claim"),
            (start = Date(2010, 7, 3), termination = Date(2012, 10, 21), status = "Lapse"),
            (start = Date(2009, 2, 12), termination = nothing, status = "Inforce"),
            (
                start = Date(2009, 10, 30),
                termination = Date(2013, 12, 27),
                status = "Claim",
            ),
            (start = Date(2009, 7, 5), termination = Date(2010, 3, 17), status = "Claim"),
        ]

        study_start = Date(2010, 1, 1)
        study_end = Date(2013, 12, 31) # inclusive end date [study_start, study_end]

        exp = Dict(
            i => exposure(
                ExperienceAnalysis.Anniversary(Year(1)),
                l.start,
                isnothing(l.termination) ? study_end : min(study_end, l.termination),
                l.status == "Claim",
            ) for (i, l) in enumerate(lives)
        )

        days = [e.to - e.from + Day(1) for e in exp[1]]
        @test days == Day.([365, 366, 365, 236])

        days = [e.to - e.from + Day(1) for e in exp[2]]
        @test days == Day.([365, 366])

        # this fails because SOA document uses non-inclusive right endpoint for lapse date, [study_start, lapse_date)
        days = [e.to - e.from + Day(1) for e in exp[3]]
        @test_broken days == Day.([365, 366, 110])


        # these fail because the study start doesn't truncate the starting date
        # and the `from` argument needs to be the anniv for the right date iteration
        days = [e.to - e.from + Day(1) for e in exp[4]]
        @test_broken days == Day.([42, 365, 365, 366, 323])

        days = [e.to - e.from + Day(1) for e in exp[5]]
        @test_broken days == Day.([302, 365, 365, 366, 365])

        days = [e.to - e.from + Day(1) for e in exp[6]]
        @test_broken days == Day.([185])


    end

end
