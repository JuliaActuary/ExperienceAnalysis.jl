@testset "Calendar exposure intervals" begin
    cm = ExperienceAnalysis.Calendar(Month(1))
    cy = ExperienceAnalysis.Calendar(Year(1))

    # because of three-value logic with nothing, need to compare egality at element level and confirm all are the same
    @testset "yearly" begin
        # policy spans study
        @test exposure(
            cy,
            Date(2010, 6, 10),
            Date(2013, 7, 1);
            study_start=Date(2011, 1, 1),
            study_end=Date(2012, 12, 31),
        ) == [
            (from=Date(2011, 1, 1), to=Date(2011, 12, 31), policy_timestep=nothing),
            (from=Date(2012, 1, 1), to=Date(2012, 12, 31), policy_timestep=nothing),
        ]

        # study spans policy
        @test exposure(
            cy,
            Date(2010, 6, 10),
            Date(2013, 7, 1);
            study_start=Date(2009, 1, 1),
            study_end=Date(2014, 12, 31),
        ) == [
            (from=Date(2010, 6, 10), to=Date(2010, 12, 31), policy_timestep=nothing),
            (from=Date(2011, 1, 1), to=Date(2011, 12, 31), policy_timestep=nothing),
            (from=Date(2012, 1, 1), to=Date(2012, 12, 31), policy_timestep=nothing),
            (from=Date(2013, 1, 1), to=Date(2013, 7, 1), policy_timestep=nothing),
        ]
    end

    @testset "monthly" begin
        # policy spans study
        @test exposure(
            cm,
            Date(2010, 2, 10),
            Date(2012, 5, 15);
            study_start=Date(2010, 3, 2),
            study_end=Date(2010, 5, 4),
        ) == [
            (from=Date(2010, 3, 2), to=Date(2010, 3, 31), policy_timestep=nothing),
            (from=Date(2010, 4, 1), to=Date(2010, 4, 30), policy_timestep=nothing),
            (from=Date(2010, 5, 1), to=Date(2010, 5, 4), policy_timestep=nothing),
        ]

        # study spans policy
        @test exposure(
            cm,
            Date(2010, 2, 10),
            Date(2010, 3, 15);
            study_start=Date(2010, 1, 1),
            study_end=Date(2010, 12, 31),
        ) == [
            (from=Date(2010, 2, 10), to=Date(2010, 2, 28), policy_timestep=nothing),
            (from=Date(2010, 3, 1), to=Date(2010, 3, 15), policy_timestep=nothing),
        ]
    end

    # weeks begin on Monday, the Julian calendar (this is a pun and I'm sorry)
    @testset "weekly" begin
        # policy spans study
        @test exposure(
            ExperienceAnalysis.Calendar(Week(1)),
            Date(2010, 2, 10),
            Date(2010, 2, 15);
            study_start=Date(2010, 2, 11),
            study_end=Date(2010, 2, 14),
        ) == [(from=Date(2010, 2, 11), to=Date(2010, 2, 14), policy_timestep=nothing)]

        # study spans policy
        @test exposure(
            ExperienceAnalysis.Calendar(Week(1)),
            Date(2010, 2, 10),
            Date(2010, 2, 24);
            study_start=Date(2010, 2, 9),
            study_end=Date(2010, 2, 27),
        ) == [
            (from=Date(2010, 2, 10), to=Date(2010, 2, 14), policy_timestep=nothing),
            (from=Date(2010, 2, 15), to=Date(2010, 2, 21), policy_timestep=nothing),
            (from=Date(2010, 2, 22), to=Date(2010, 2, 24), policy_timestep=nothing),
        ]
    end

    @testset "daily" begin
        # policy spans study
        @test exposure(
            ExperienceAnalysis.Calendar(Day(1)),
            Date(2010, 2, 10),
            Date(2010, 2, 15);
            study_start=Date(2010, 2, 11),
            study_end=Date(2010, 2, 14),
        ) == [
            (from=Date(2010, 2, 11), to=Date(2010, 2, 11), policy_timestep=nothing),
            (from=Date(2010, 2, 12), to=Date(2010, 2, 12), policy_timestep=nothing),
            (from=Date(2010, 2, 13), to=Date(2010, 2, 13), policy_timestep=nothing),
            (from=Date(2010, 2, 14), to=Date(2010, 2, 14), policy_timestep=nothing),
        ]

        # study spans policy
        @test exposure(
            ExperienceAnalysis.Calendar(Day(1)),
            Date(2010, 2, 20),
            Date(2010, 2, 24);
            study_start=Date(2010, 2, 9),
            study_end=Date(2010, 2, 27),
        ) == [
            (from=Date(2010, 2, 20), to=Date(2010, 2, 20), policy_timestep=nothing),
            (from=Date(2010, 2, 21), to=Date(2010, 2, 21), policy_timestep=nothing),
            (from=Date(2010, 2, 22), to=Date(2010, 2, 22), policy_timestep=nothing),
            (from=Date(2010, 2, 23), to=Date(2010, 2, 23), policy_timestep=nothing),
            (from=Date(2010, 2, 24), to=Date(2010, 2, 24), policy_timestep=nothing),
        ]
    end

    @testset "study_start not defined" begin
        # study_start not defined, policy entirely before study_end
        @test exposure(
            cy,
            Date(2009, 5, 10),
            Date(2010, 6, 10);
            study_end=Date(2011, 12, 31),
        ) == [
            (from=Date(2009, 5, 10), to=Date(2009, 12, 31), policy_timestep=nothing),
            (from=Date(2010, 1, 1), to=Date(2010, 6, 10), policy_timestep=nothing),
        ]

        # study_start not defined, policy partially before study_end
        @test exposure(
            cy,
            Date(2011, 5, 10),
            Date(2012, 6, 10);
            study_end=Date(2011, 12, 31),
        ) == [(from=Date(2011, 5, 10), to=Date(2011, 12, 31), policy_timestep=nothing)]
    end

    @testset "continued_exposure=true" begin
        # continued_exposure does not extend beyond study end
        @test exposure(
            cy,
            Date(2009, 5, 10),
            Date(2010, 6, 10),
            true;
            study_end=Date(2011, 12, 31),
        ) == [
            (from=Date(2009, 5, 10), to=Date(2009, 12, 31), policy_timestep=nothing),
            (from=Date(2010, 1, 1), to=Date(2010, 12, 31), policy_timestep=nothing),
        ]

        # continued_exposure does extend beyond study end
        @test exposure(
            cy,
            Date(2009, 5, 10),
            Date(2010, 6, 10),
            true;
            study_end=Date(2010, 11, 30),
        ) == [
            (from=Date(2009, 5, 10), to=Date(2009, 12, 31), policy_timestep=nothing),
            (from=Date(2010, 1, 1), to=Date(2010, 12, 31), policy_timestep=nothing),
        ]
    end
end

@testset "Calendar validations" begin
    cy = ExperienceAnalysis.Calendar(Year(1))
    # from > to
    @test_throws DomainError exposure(
        cy,
        Date(2010, 5, 10),
        Date(2010, 4, 10);
        study_end=Date(2010, 6, 10),
    )

    # study_start > study_end
    @test_throws DomainError exposure(
        cy,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start=Date(2010, 6, 10),
        study_end=Date(2010, 5, 10),
    )

    # policy not intersect study, too early
    @test exposure(
        cy,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start=Date(2010, 6, 11),
        study_end=Date(2010, 7, 10),
    ) == []

    # policy not intersect study, too late
    @test exposure(
        cy,
        Date(2010, 5, 10),
        Date(2010, 6, 10);
        study_start=Date(2010, 4, 11),
        study_end=Date(2010, 5, 9),
    ) == []
end
