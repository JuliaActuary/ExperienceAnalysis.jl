using ExperienceAnalysis
using Dates
using Test

pycy = ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1))
pmcm = ExperienceAnalysis.AnniversaryCalendar(Month(1), Month(1))

@testset "AnniversaryCalendar, left_partial and start_date" begin
    @testset "study_start > from, study_start not on anniv, left partials do exist" begin
        @test exposure(
            pycy,
            Date(2020, 1, 2),
            Date(2022, 1, 2);
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = true,
        ) == [
            (from = Date(2020, 1, 10), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 1, 1), policy_timestep = 1),
            (from = Date(2021, 1, 2), to = Date(2021, 12, 10), policy_timestep = 2),
        ]
        # with continued exposure
        @test exposure(
            pycy,
            Date(2020, 1, 2),
            Date(2021, 1, 2),
            true;
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = true,
        ) == [
            (from = Date(2020, 1, 10), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 1, 1), policy_timestep = 1),
            (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 2),
        ]

        @test exposure(
            pycy,
            Date(2020, 1, 2),
            Date(2022, 1, 2);
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = false,
        ) == [(from = Date(2021, 1, 2), to = Date(2021, 12, 10), policy_timestep = 2)]
        # with continued exposure, goes beyond study end
        @test exposure(
            pycy,
            Date(2020, 1, 2),
            Date(2021, 1, 2),
            true;
            study_start = Date(2020, 1, 10),
            study_end = Date(2021, 12, 10),
            right_partials = true,
            left_partials = false,
        ) == [
            (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 2),
        ]

    end

    @testset "study_start > from, study_start on anniv, left partials do not exist" begin
        @test exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2022, 1, 2);
                  study_start = Date(2021, 1, 2),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2022, 1, 2);
                  study_start = Date(2021, 1, 2),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [(from = Date(2021, 1, 2), to = Date(2021, 12, 10), policy_timestep = 2)]
    end
    # with continued exposure, goes beyond study end
    @test exposure(
              pycy,
              Date(2020, 1, 2),
              Date(2021, 1, 2),
              true;
              study_start = Date(2021, 1, 2),
              study_end = Date(2021, 12, 10),
              right_partials = true,
              left_partials = true,
          ) ==
          exposure(
              pycy,
              Date(2020, 1, 2),
              Date(2021, 1, 2),
              true;
              study_start = Date(2021, 1, 2),
              study_end = Date(2021, 12, 10),
              right_partials = true,
              left_partials = false,
          ) ==
          [
              (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 2),
              (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 2),
          ]

    @testset "study_start < from, left partials do not exist" begin
        @test exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2022, 1, 2);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2022, 1, 2);
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 2), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 1, 1), policy_timestep = 1),
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 10), policy_timestep = 2),
              ]
        # with continued exposure, goes beyond study end
        @test exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2021, 1, 2),
                  true;
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2021, 1, 2),
                  true;
                  study_start = Date(1900, 1, 1),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 2), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 1, 1), policy_timestep = 1),
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 2),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 2),
              ]

    end

    @testset "study_start == from, left partials do not exist" begin
        @test exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2022, 1, 2);
                  study_start = Date(2020, 1, 2),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2022, 1, 2);
                  study_start = Date(2020, 1, 2),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 2), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 1, 1), policy_timestep = 1),
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 10), policy_timestep = 2),
              ]
        # with continued exposure, goes beyond study end
        @test exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2021, 1, 2),
                  true;
                  study_start = Date(2020, 1, 2),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2020, 1, 2),
                  Date(2021, 1, 2),
                  true;
                  study_start = Date(2020, 1, 2),
                  study_end = Date(2021, 12, 10),
                  right_partials = true,
                  left_partials = false,
              ) ==
              [
                  (from = Date(2020, 1, 2), to = Date(2020, 12, 31), policy_timestep = 1),
                  (from = Date(2021, 1, 1), to = Date(2021, 1, 1), policy_timestep = 1),
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 2),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 2),
              ]
    end

end

@testset "AnniversaryCalendar, right_partials and study_end" begin
    @testset "study_end >> to, right_partials has no impact" begin
        @test exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2);
                  study_end = Date(2023, 1, 1),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2);
                  study_end = Date(2023, 1, 1),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
                  (from = Date(2022, 1, 2), to = Date(2022, 1, 2), policy_timestep = 2),
              ]
        # with continued exposure, goes exactly to study end
        @test exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2),
                  true;
                  study_end = Date(2023, 1, 1),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2),
                  true;
                  study_end = Date(2023, 1, 1),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
                  (from = Date(2022, 1, 2), to = Date(2022, 12, 31), policy_timestep = 2),
                  (from = Date(2023, 1, 1), to = Date(2023, 1, 1), policy_timestep = 2),
              ]

    end

    @testset "study_end > to, right_partials removes intervals if `from + period > study_end`" begin
        @test exposure(
            pycy,
            Date(2021, 1, 2),
            Date(2022, 1, 2);
            study_end = Date(2022, 12, 31),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
            (from = Date(2022, 1, 2), to = Date(2022, 1, 2), policy_timestep = 2),
        ]
        # with continued exposure, goes beyond study end
        @test exposure(
            pycy,
            Date(2021, 1, 2),
            Date(2022, 1, 2),
            true;
            study_end = Date(2022, 12, 31),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
            (from = Date(2022, 1, 2), to = Date(2022, 12, 31), policy_timestep = 2),
            (from = Date(2023, 1, 1), to = Date(2023, 1, 1), policy_timestep = 2),
        ]

        @test exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2);
                  study_end = Date(2022, 12, 31),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2),
                  true;
                  study_end = Date(2022, 12, 31),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
              ]
    end

    @testset "study_end == to and right_partials are removed" begin
        @test exposure(
            pycy,
            Date(2021, 1, 2),
            Date(2022, 1, 2);
            study_end = Date(2022, 1, 2),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
            (from = Date(2022, 1, 2), to = Date(2022, 1, 2), policy_timestep = 2),
        ]
        # with continued exposure, goes beyond study end
        @test exposure(
            pycy,
            Date(2021, 1, 2),
            Date(2022, 1, 2),
            true;
            study_end = Date(2022, 12, 31),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
            (from = Date(2022, 1, 2), to = Date(2022, 12, 31), policy_timestep = 2),
            (from = Date(2023, 1, 1), to = Date(2023, 1, 1), policy_timestep = 2),
        ]

        @test exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2);
                  study_end = Date(2022, 1, 2),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2),
                  true;
                  study_end = Date(2022, 1, 2),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
              ]
    end

    @testset "study_end on day prior anniv, no right_partials exist" begin
        @test exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2);
                  study_end = Date(2022, 1, 1),
                  left_partials = true,
                  right_partials = true,
              ) ==
              exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2);
                  study_end = Date(2022, 1, 1),
                  left_partials = true,
                  right_partials = false,
              ) ==
              exposure(
                  pycy,
                  Date(2021, 1, 2),
                  Date(2022, 1, 2),
                  true;
                  study_end = Date(2022, 1, 1),
                  left_partials = true,
                  right_partials = false,
              ) ==
              [
                  (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
                  (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
              ]
    end

end

@testset "AnniversaryCalendar, no right_partials with no left_partials" begin
    # empty if all exposures are partial
    @test exposure(
              pycy,
              Date(2021, 1, 2),
              Date(2022, 1, 2);
              study_start = Date(2021, 1, 3),
              study_end = Date(2022, 1, 1),
              left_partials = false,
              right_partials = false,
          ) ==
          exposure(
              pycy,
              Date(2021, 1, 2),
              Date(2022, 1, 2),
              true;
              study_start = Date(2021, 1, 3),
              study_end = Date(2022, 1, 1),
              left_partials = false,
              right_partials = false,
          ) ==
          []

    # no impact if no exposures are partial
    @test exposure(
              pycy,
              Date(2021, 1, 2),
              Date(2022, 1, 2),
              true;
              study_start = Date(2021, 1, 1),
              study_end = Date(2023, 5, 5),
              left_partials = false,
              right_partials = false,
          ) ==
          exposure(
              pycy,
              Date(2021, 1, 2),
              Date(2022, 1, 2),
              true;
              study_start = Date(2021, 1, 1),
              study_end = Date(2023, 5, 5),
              left_partials = true,
              right_partials = true,
          ) ==
          [
              (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
              (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
              (from = Date(2022, 1, 2), to = Date(2022, 12, 31), policy_timestep = 2),
              (from = Date(2023, 1, 1), to = Date(2023, 1, 1), policy_timestep = 2),
          ]

    @test exposure(
              pycy,
              Date(2021, 1, 2),
              Date(2022, 1, 2);
              study_start = Date(2021, 1, 1),
              study_end = Date(2023, 5, 5),
              left_partials = false,
              right_partials = false,
          ) ==
          exposure(
              pycy,
              Date(2021, 1, 2),
              Date(2022, 1, 2);
              study_start = Date(2021, 1, 1),
              study_end = Date(2023, 5, 5),
              left_partials = true,
              right_partials = true,
          ) ==
          [
              (from = Date(2021, 1, 2), to = Date(2021, 12, 31), policy_timestep = 1),
              (from = Date(2022, 1, 1), to = Date(2022, 1, 1), policy_timestep = 1),
              (from = Date(2022, 1, 2), to = Date(2022, 1, 2), policy_timestep = 2),
          ]
end

@testset "AnniversaryCalendar, edge cases" begin
    @testset "works when anniversary is on new year" begin
        @test exposure(
            pycy,
            Date(2020, 1, 1),
            Date(2022, 1, 2),
            false;
            study_start = Date(2020, 6, 1),
            study_end = Date(2023, 1, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 6, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 1, 2), policy_timestep = 3),
        ]
        @test exposure(
            pycy,
            Date(2020, 1, 1),
            Date(2022, 1, 2),
            true;
            study_start = Date(2020, 6, 1),
            study_end = Date(2023, 1, 1),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 6, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 12, 31), policy_timestep = 2),
            (from = Date(2022, 1, 1), to = Date(2022, 12, 31), policy_timestep = 3),
        ]
    end

    @testset "works when anniversary is on first day of month, pmcm" begin
        @test exposure(
            pmcm,
            Date(2020, 12, 1),
            Date(2021, 2, 2);
            study_start = Date(2020, 6, 1),
            study_end = Date(2021, 2, 5),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 12, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 1, 31), policy_timestep = 2),
            (from = Date(2021, 2, 1), to = Date(2021, 2, 2), policy_timestep = 3),
        ]
        @test exposure(
            pmcm,
            Date(2020, 12, 1),
            Date(2021, 2, 2),
            true;
            study_start = Date(2020, 6, 1),
            study_end = Date(2021, 2, 5),
            left_partials = true,
            right_partials = true,
        ) == [
            (from = Date(2020, 12, 1), to = Date(2020, 12, 31), policy_timestep = 1),
            (from = Date(2021, 1, 1), to = Date(2021, 1, 31), policy_timestep = 2),
            (from = Date(2021, 2, 1), to = Date(2021, 2, 28), policy_timestep = 3),
        ]
    end
end

@testset "AnniversaryCalendar validations" begin
    # from > to
    @test_throws DomainError exposure(
        pycy,
        Date(2010, 5, 10),
        Date(2010, 4, 10);
        study_end = Date(2010, 6, 10),
    )

    # study_start > study_end
    @test_throws DomainError exposure(
        pycy,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start = Date(2010, 6, 10),
        study_end = Date(2010, 5, 10),
    )

    # policy not intersect study, too early
    @test exposure(
        pycy,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start = Date(2010, 6, 11),
        study_end = Date(2010, 7, 10),
    ) == []

    # policy not intersect study, too late
    @test exposure(
        pycy,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start = Date(2010, 4, 11),
        study_end = Date(2010, 5, 9),
    ) == []
end
