using ExperienceAnalysis
using Test
using Dates

@testset "PolicyCalendar" begin
    issue = Date(2016, 7, 4)
    termination = Date(2020, 1, 17)
    
    @testset "Year/Year" begin
        exp = exposure(issue, termination, ExperienceAnalysis.PolicyCalendar(Year(1), Year(1)))

        @test exp[1]   == (from = Date(2016, 7, 4), to = Date(2017, 1, 1))
        @test exp[2]   == (from = Date(2017, 1, 1), to = Date(2017, 7, 4))
        @test exp[end] == (from = Date(2020, 1, 1), to = Date(2020, 1, 17))
    end

    @testset "Year/Year" begin
        exp = exposure(issue, termination, ExperienceAnalysis.PolicyCalendar(Month(1), Year(1)))

        @test exp[1]   == (from = Date(2016, 7, 4), to = Date(2016, 8, 4))
        @test exp[6]   == (from = Date(2016, 12, 4), to = Date(2017, 1, 1))
        @test exp[7]   == (from = Date(2017, 1, 1), to = Date(2017, 1, 4))
        @test exp[end] == (from = Date(2020, 1, 4), to = Date(2020, 1, 17))
    end
end
