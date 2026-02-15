using Documenter, ExperienceAnalysis

makedocs(;
    modules=[ExperienceAnalysis],
    format=Documenter.HTML(),
    pages=[
        "Overview" => "index.md",
        "API Reference" => "api.md",
    ],
    repo="https://github.com/JuliaActuary/ExperienceAnalysis.jl/blob/{commit}{path}#L{line}",
    sitename="ExperienceAnalysis.jl",
    authors="Alec Loudenback"
)

deploydocs(;
    repo="github.com/JuliaActuary/ExperienceAnalysis.jl"
)
