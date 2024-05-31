using ExperienceAnalysis
using Dates
using Test

py = ExperienceAnalysis.Anniversary(Year(1))
pm = ExperienceAnalysis.Anniversary(Month(1))

@testset "Anniversary, left_partial and start_date" begin
    @testset "study_start > from, study_start not on anniv, left partials do exist" begin
        # Year(1), with left partials
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1);
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = true,
        ) == [
            (from = Date(2020, 1, 10), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
        # Year(1), without left partials
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1);
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = false,
        ) == [(from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2)]
        # Year(1), without left partials, check continued_exposure
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2021, 1, 1),
            true;
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = false,
        ) == [(from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2)]

        # Month(1), with left partials
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1);
            study_start = Date(2020, 1, 10),
            study_end = Date(2020, 3, 30),
            right_partials = true,
            left_partials = true,
        ) == [
            (from = Date(2020, 1, 10), to = Date(2020, 1, 31), policy_timestep = 1),
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
        ]
        # Month(1), without left partials
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1);
            study_start = Date(2020, 1, 10),
            study_end = Date(2020, 3, 30),
            right_partials = true,
            left_partials = false,
        ) == [
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
        ]
        # Month(1), without left partials, check continued_exposure
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1),
            true;
            study_start = Date(2020, 1, 10),
            study_end = Date(2020, 3, 30),
            right_partials = true,
            left_partials = false,
        ) == [
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 31), policy_timestep = 3),
        ]

    end

    @testset "study_start > from, study_start on anniv, left partials do not exist" begin
        # Year(1), same results for left partials or not
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_start = Date(2021, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_start = Date(2021, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [(from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2)]

        # Month(1), same results for left partials or not
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(2020, 2, 1),
                  study_end = Date(2020, 3, 30),
                  right_partials = true,
                  left_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(2020, 2, 1),
                  study_end = Date(2020, 3, 30),
                  right_partials = true,
                  left_partials = true,
              ) ==
              [
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
                  (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
              ]
    end

    @testset "study_start < from, left partials do not exist" begin
        # Year(1), same results for left partials or not
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
              ]

        # Month(1), same results for left partials or not
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 30),
                  right_partials = true,
                  left_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 30),
                  right_partials = true,
                  left_partials = true,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
                  (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
              ]
    end

    @testset "study_start == from, left partials do not exist" begin
        # Year(1), same results for left partials or not
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_start = Date(2020, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_start = Date(2020, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 12, 10), policy_timestep = 2),
              ]

        # Month(1), same results for left partials or not
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(2020, 1, 1),
                  study_end = Date(2020, 3, 30),
                  right_partials = true,
                  left_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(2020, 1, 1),
                  study_end = Date(2020, 3, 30),
                  right_partials = true,
                  left_partials = true,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
                  (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
              ]
    end
end

# more thorough on continued_exposure testing here in case it may interact with right_partials
@testset "Anniversary, right_partials and study_end" begin
    @testset "study_end >> to, right_partials has no impact" begin
        # Year(1), same results for right partials or not
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_end = Date(2023, 1, 2),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_end = Date(2023, 1, 2),
                  left_partials = true,
                  right_partials = false,
              ) == [
                  (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 3),
              ]
        # Year(1), same results for right partials or not, with continued_exposure
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1),
                  true;
                  study_end = Date(2023, 1, 2),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1),
                  true;
                  study_end = Date(2023, 1, 2),
                  left_partials = true,
                  right_partials = false,
              ) == [
                  (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
                  (from = Date(2022, 1, 1), to = Date(2022, 12, 31), policy_timestep = 3),
              ]
        # Month(1), same results for right partials or not
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 31),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 31),
                  right_partials = true,
                  left_partials = true,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
                  (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
              ]
        # Month(1), same results for right partials or not, with continued_exposure
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1),
                  true;
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 31),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1),
                  true;
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 31),
                  right_partials = true,
                  left_partials = true,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
                  (from = Date(2020, 3, 1), to = Date(2020, 3, 31), policy_timestep = 3),
              ]
    end

    @testset "study_end > to, right_partials removes intervals if `from + period > study_end` regardless of `to`" begin
        # Year(1), right partials
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1);
            study_end = Date(2022, 1, 2),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 3),
        ]

        # Year(1), right partials, with continued_exposure
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1),
            true;
            study_end = Date(2022, 1, 2),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 12, 31), policy_timestep = 3),
        ]

        # Year(1), no right partials, with/without continued_exposure
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_end = Date(2022, 1, 2),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1),
                  true;
                  study_end = Date(2022, 1, 2),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
              ]

        # Month(1), right partials
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1);
            study_start = Date(1900, 1, 1),
            study_end = Date(2020, 3, 30),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
        ]
        # Month(1), right partials, with continued_exposure
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1),
            true;
            study_start = Date(1900, 1, 1),
            study_end = Date(2020, 3, 30),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 31), policy_timestep = 3),
        ]
        # Month(1), no right partials, with/without continued_exposure
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 30),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1),
                  true;
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 30),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
              ]
    end

    @testset "study_end == to, right_partials are removed" begin
        # Year(1), with right_partials
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1);
            study_end = Date(2022, 1, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 3),
        ]
        # Year(1), with right_partials, with continued_exposure
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1),
            true;
            study_end = Date(2022, 1, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 12, 31), policy_timestep = 3),
        ]
        # Year(1), with right_partials, with/without continued_exposure
        @test exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1);
            study_end = Date(2022, 1, 1),
            left_partials = true,
            right_partials = false,
        ) == 
        exposure(
            py,
            Date(2020, 1, 1),
            Date(2022, 1, 1),
            true;
            study_end = Date(2022, 1, 1),
            left_partials = true,
            right_partials = false,
        ) == 
        [
            (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
        ]

        # Month(1), right partials
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1);
            study_start = Date(1900, 1, 1),
            study_end = Date(2020, 3, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 1), policy_timestep = 3),
        ]
        # Month(1), right partials, with continued_exposure
        @test exposure(
            pm,
            Date(2020, 1, 1),
            Date(2020, 3, 1),
            true;
            study_start = Date(1900, 1, 1),
            study_end = Date(2020, 3, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
            (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
            (from = Date(2020, 3, 1), to = Date(2020, 3, 31), policy_timestep = 3),
        ]
        # Month(1), no right partials, with/without continued_exposure
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 1),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1),
                  true;
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2020, 3, 1),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
              ]
    end

    @testset "study_end on day prior anniv, no right_partials exist" begin
        # Year(1), with/without continued_exposure/right_partials
        @test exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_end = Date(2021, 12, 31),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1);
                  study_end = Date(2021, 12, 31),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  py,
                  Date(2020, 1, 1),
                  Date(2022, 1, 1),
                  true;
                  study_end = Date(2021, 12, 31),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
              ]
        # Month(1), with/without continued_exposure/right_partials
        @test exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_end = Date(2020, 2, 29),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1);
                  study_end = Date(2020, 2, 29),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pm,
                  Date(2020, 1, 1),
                  Date(2020, 3, 1),
                  true;
                  study_end = Date(2020, 2, 29),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 1), to = Date(2020, 1, 31), policy_timestep = 1),
                  (from = Date(2020, 2, 1), to = Date(2020, 2, 29), policy_timestep = 2),
              ]
    end

end

@testset "Anniversary, edge cases" begin
    @testset "Year(1) works for years starting on leap day" begin
        @test exposure(
            py,
            Date(2016, 2, 29),
            Date(2025, 1, 2);
            study_start = Date(2020, 1, 1),
            study_end = Date(2025, 1, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 1, 1), to = Date(2020, 2, 28), policy_timestep = 4),
            (from = Date(2020, 2, 29), to = Date(2021, 2, 27), policy_timestep = 5),
            (from = Date(2021, 2, 28), to = Date(2022, 2, 27), policy_timestep = 6),
            (from = Date(2022, 2, 28), to = Date(2023, 2, 27), policy_timestep = 7),
            (from = Date(2023, 2, 28), to = Date(2024, 2, 28), policy_timestep = 8),
            (from = Date(2024, 2, 29), to = Date(2025, 1, 1), policy_timestep = 9),
        ]
    end
    @testset "Month(1) does not clip to month endings" begin
        exposure(
            pm,
            Date(2022, 1, 31),
            Date(2022, 5, 1);
            study_start = Date(2020, 1, 1),
            study_end = Date(2025, 1, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2022, 1, 31), to = Date(2022, 2, 27), policy_timestep = 1),
            (from = Date(2022, 2, 28), to = Date(2022, 3, 30), policy_timestep = 2),
            (from = Date(2022, 3, 31), to = Date(2022, 4, 29), policy_timestep = 3),
            (from = Date(2022, 4, 30), to = Date(2022, 5, 1), policy_timestep = 4),
        ]
    end
end

@testset "Anniversary validations" begin
    # from > to
    @test_throws DomainError exposure(
        py,
        Date(2010, 5, 10),
        Date(2010, 4, 10);
        study_end = Date(2010, 6, 10),
    )

    # study_start > study_end
    @test_throws DomainError exposure(
        py,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start = Date(2010, 6, 10),
        study_end = Date(2010, 5, 10),
    )

    # policy not intersect study, too early
    @test exposure(
        py,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start = Date(2010, 6, 11),
        study_end = Date(2010, 7, 10),
    ) == []

    # policy not intersect study, too late
    @test exposure(
        py,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start = Date(2010, 4, 11),
        study_end = Date(2010, 5, 9),
    ) == []
end


