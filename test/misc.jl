@testset "Miscellaneous Tests based on individually checked results" begin
    e = exposure(ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), Date(2012, 6, 18), Date(2020, 3, 31); study_start=Date(2019, 4, 1))
    @test first(e) == (from=Date("2019-04-01"), to=Date("2019-06-17"), policy_timestep=7)
    @test last(e) == (from=Date("2020-01-01"), to=Date("2020-03-31"), policy_timestep=8)
    @test length(e) == 3

    e = exposure(ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), Date(2012, 6, 18), Date(2020, 3, 31); study_start=Date(2012, 6, 18))
    @test first(e) == (from=Date("2012-06-18"), to=Date("2012-12-31"), policy_timestep=1)
    @test last(e) == (from=Date("2020-01-01"), to=Date("2020-03-31"), policy_timestep=8)
    @test length(e) == 16

    e = exposure(ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), Date(2012, 6, 18), Date(2021, 3, 31); study_start=Date(2020, 4, 1))
    @test first(e) == (from=Date("2020-04-01"), to=Date("2020-06-17"), policy_timestep=8)
    @test last(e) == (from=Date("2021-01-01"), to=Date("2021-03-31"), policy_timestep=9)
    @test length(e) == 3

    e = exposure(ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), Date(2012, 6, 18), Date(2022, 3, 31); study_start=Date(2021, 4, 1))
    @test first(e) == (from=Date("2021-04-01"), to=Date("2021-06-17"), policy_timestep=9)
    @test last(e) == (from=Date("2022-01-01"), to=Date("2022-03-31"), policy_timestep=10)
    @test length(e) == 3

    e = exposure(ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1)), Date(2012, 6, 18), Date(2023, 3, 31); study_start=Date(2022, 4, 1))
    @test first(e) == (from=Date("2022-04-01"), to=Date("2022-06-17"), policy_timestep=10)
    @test last(e) == (from=Date("2023-01-01"), to=Date("2023-03-31"), policy_timestep=11)
    @test length(e) == 3


end