
data = CSV.read(abspath(joinpath(@__DIR__, "..", "data", "word_freq_probs.csv")),DataFrame)
words, freqs, depth_score, safety_score  = data.word, data.frequency, data.depth_score, data.safety_score
word_freq_dict = Dict(zip(words,freqs))