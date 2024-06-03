using ExperienceAnalysis
using Dates
using Test

py = ExperienceAnalysis.Anniversary(Year(1))
pycy = ExperienceAnalysis.AnniversaryCalendar(Year(1), Year(1))
cy = ExperienceAnalysis.Calendar(Year(1))

@testset "broadcasting works" begin
    # Anniversary
    @test exposure.(
        py,
        [Date(2020, 1, 1), Date(2021, 1, 1)],
        [Date(2022, 1, 1), Date(2023, 1, 1)],
        [true, true];
        study_start=Date(2022, 6, 10),
        study_end=Date(2025, 12, 10),
        right_partials=true,
        left_partials=true,
    ) == [
        [],
        [
            (from=Date(2022, 06, 10), to=Date(2022, 12, 31), policy_timestep=2),
            (from=Date(2023, 01, 01), to=Date(2023, 12, 31), policy_timestep=3)
        ]
    ]
    # AnniversaryCalendar
    @test exposure.(
        pycy,
        [Date(2020, 1, 1), Date(2021, 5, 1)],
        [Date(2022, 1, 1), Date(2022, 12, 31)],
        [true, true];
        study_start=Date(2022, 6, 10),
        study_end=Date(2025, 12, 10),
        right_partials=true,
        left_partials=true,
    ) == [
        [],
        [
            (from=Date(2022, 06, 10), to=Date(2022, 12, 31), policy_timestep=2),
        ]
    ]
    # Calendar
    @test exposure.(
        cy,
        [Date(2020, 1, 1), Date(2021, 5, 1)],
        [Date(2022, 1, 1), Date(2022, 10, 31)],
        [true, false];
        study_start=Date(2022, 1, 1),
        study_end=Date(2025, 12, 10)
    ) == [
        [
            (from=Date(2022, 01, 01), to=Date(2022, 12, 31), policy_timestep=nothing)
        ],
        [
            (from=Date(2022, 01, 01), to=Date(2022, 10, 31), policy_timestep=nothing),
        ]
    ]
end