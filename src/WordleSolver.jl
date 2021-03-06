module WordleSolver

using CSV, DataFrames
using StatsBase
using ProgressMeter

export  wordle

wordle() = solve_wordle(words, freqs, depth_score) 

include("data_setup.jl")
include("interactive_solver.jl")
include("analysis.jl")

end
