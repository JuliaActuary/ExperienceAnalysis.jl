using ExperienceAnalysis
using Dates
using Test

@testset "`validate` throws errors on malformed data" begin
    # from > to
    @test_throws DomainError ExperienceAnalysis.validate(
        Date(2016, 7, 4),
        Date(2016, 7, 3),
        Date(2016, 6, 1),
        Date(2016, 8, 3),
    )
    # study_start > study_end
    @test_throws DomainError ExperienceAnalysis.validate(
        Date(2016, 7, 4),
        Date(2016, 7, 31),
        Date(2016, 8, 5),
        Date(2016, 8, 3),
    )
end

# TODO: add tests for nothing cases
@testset "`validate` determines if policy overlaps with study period" begin
    @testset "no overlap" begin
        # study starts after policy ends
        @test !ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            Date(2016, 8, 1),
            Date(2016, 8, 3),
        )

        # study ends before policy starts
        @test !ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            Date(2016, 6, 1),
            Date(2016, 6, 3),
        )

        # study_start is nothing and there is no overlap
        @test !ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            nothing,
            Date(2016, 6, 3),
        )

        # study_start and `to` are both nothing, there is overlap
        @test ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            nothing,
            nothing,
            Date(2016, 7, 4),
        )

        # study_start and `to` are both nothing, there is no overlap
        @test !ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            nothing,
            nothing,
            Date(2016, 7, 3),
        )
    end

    @testset "overlap" begin
        # study_start is nothing and there is overlap
        @test ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            nothing,
            Date(2016, 8, 3),
        )

        # study_start is not nothing and there is overlap
        @test ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            Date(2016, 6, 1),
            Date(2016, 8, 3),
        )
        @test ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            Date(2016, 7, 17),
            Date(2016, 7, 17),
        )
        @test ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            Date(2016, 7, 6),
            Date(2016, 8, 3),
        )
        @test ExperienceAnalysis.validate(
            Date(2016, 7, 4),
            Date(2016, 7, 31),
            Date(2016, 6, 1),
            Date(2016, 7, 5),
        )
    end
