using ExperienceAnalysis
using Dates
using Test

@testset "left_partial and start_date" begin
    py = ExperienceAnalysis.Anniversary(Year(1))
	pm = ExperienceAnalysis.Anniversary(Month(1))
	from = Date(2020,1,1)
	to = Date(2022, 1, 1)

    @testset "study_start > from, study_start not on anniv => left partials do exist" begin
        exp_leftpartials = exposure(py, from, to; study_start=Date(2020,1,10), study_end=Date(2021, 12, 10), right_partials=true, left_partials=true)
        exp_no_leftpartials = exposure(py, from, to; study_start=Date(2020,1,10), study_end=Date(2021, 12, 10), right_partials=true, left_partials=false)
        @test exp_leftpartials == [
            (from = Date(2020, 1, 10), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
        @test exp_no_leftpartials == [
            (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
    end

    @testset "study_start > from, study_start on anniv => left partials do not exist" begin
        exp_leftpartials = exposure(py, from, to; study_start=Date(2021,1,1), study_end=Date(2021, 12, 10), right_partials=true, left_partials=true)
        exp_no_leftpartials = exposure(py, from, to; study_start=Date(2021,1,1), study_end=Date(2021, 12, 10), right_partials=true, left_partials=false)
        @test exp_leftpartials == exp_no_leftpartials == [
            (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
    end

    @testset "study_start < from, left partials do not exist" begin
        exp_leftpartials = exposure(py, from, to; study_start=Date(1900,1,1), study_end=Date(2021, 12, 10), right_partials=true, left_partials=true)
        exp_no_leftpartials = exposure(py, from, to; study_start=Date(1900,1,1), study_end=Date(2021, 12, 10), right_partials=true, left_partials=false)
        @test exp_leftpartials == exp_no_leftpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
    end

    @testset "study_start == from, left partials do not exist" begin
        exp_leftpartials = exposure(py, from, to; study_start=Date(2020,1,1), study_end=Date(2021, 12, 10), right_partials=true, left_partials=true)
        exp_no_leftpartials = exposure(py, from, to; study_start=Date(2020,1,1), study_end=Date(2021, 12, 10), right_partials=true, left_partials=false)
        @test exp_leftpartials == exp_no_leftpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
    end

end

@testset "right_partials and study_end" begin
    py = ExperienceAnalysis.Anniversary(Year(1))
	pm = ExperienceAnalysis.Anniversary(Month(1))
	from = Date(2020,1,1)
	to = Date(2022, 1, 1)

    @testset "study_end >> to, right_partials has no impact" begin
        exp_rightpartials = exposure(py, from, to; study_end=Date(2023, 1, 2), left_partials=true, right_partials=true)
        exp_no_rightpartials = exposure(py, from, to; study_end=Date(2023, 1, 2), left_partials=true, right_partials=false)
        @test exp_rightpartials == exp_no_rightpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 3),
        ]
    end

    @testset "study_end > to, right_partials removes intervals if `from + period > study_end` regardless of `to`" begin
        exp_rightpartials = exposure(py, from, to; study_end=Date(2022, 1, 2), left_partials=true, right_partials=true)
        exp_no_rightpartials = exposure(py, from, to; study_end=Date(2022, 1, 2), left_partials=true, right_partials=false)
        @test exp_rightpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 3),
        ]
        @test exp_no_rightpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
        ]
    end

    @testset "study_end == to, right_partials are removed" begin
        exp_rightpartials = exposure(py, from, to; study_end=Date(2022, 1, 1), left_partials=true, right_partials=true)
        exp_no_rightpartials = exposure(py, from, to; study_end=Date(2022, 1, 1), left_partials=true, right_partials=false)
        @test exp_rightpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 3),
        ]
        @test exp_no_rightpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
        ]
    end

    @testset "study_end on day prior anniv, no right_partials exist" begin
        exp_rightpartials = exposure(py, from, to; study_end=Date(2021, 12, 31), left_partials=true, right_partials=true)
        exp_no_rightpartials = exposure(py, from, to; study_end=Date(2021, 12, 31), left_partials=true, right_partials=false)
        @test exp_rightpartials == exp_no_rightpartials == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
        ]
    end

end
