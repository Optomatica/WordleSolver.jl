function update_constraints_by_comparison!(secret_word,candidate_word, let_in_pos, let_not_in_pos, let_not_in_word)
    for i in eachindex(candidate_word)
        if secret_word[i] == candidate_word[i]
            let_in_pos[i]=candidate_word[i]
        end
    end
    for i in eachindex(candidate_word)
        if candidate_word[i] ∉ values(let_in_pos) && occursin(candidate_word[i], secret_word)
            let_not_in_pos[candidate_word[i]] = push!(get(let_not_in_pos,candidate_word[i],Int[]),i)
        end
    end
    for i in eachindex(candidate_word)
        if !occursin(candidate_word[i],secret_word)
          push!(let_not_in_word,candidate_word[i]) 
        end
    end
end

function firstwordscore_simple(words,trials)
    score=Dict(zip(words,[(0,0,0) for i in eachindex(words)]))
    p = Progress(trials)
    for  i=1:trials
        selected_word = rand(words)
        Threads.@threads for w in words
            w == selected_word && continue #No point attempting with same word
            i = steps_to_solve(words,selected_word,w)
            if i < 6 
                score[w] = score[w] .+ (i,1,0)
            else
                score[w] = score[w] .+ (0,0,1) 
            end    
        end
        next!(p)
    end
    score
end

function firstwordscore_prob(words,freqs,trials)
    score=Dict(zip(words,[(0,0,0) for i in eachindex(words)]))
    p = Progress(trials)
    weights = FrequencyWeights(freqs)
    w_f_dict = Dict(zip(words,freqs))
    for  i=1:trials
        selected_word = sample(words,weights)
        Threads.@threads for w in words
            w == selected_word && continue #No point attempting with same word
            i = steps_to_solve_prob(words, w_f_dict ,selected_word,w)
            if i < 6 
                score[w] = score[w] .+ (i,1,0)
            else
                score[w] = score[w] .+ (0,0,1) 
            end    
        end
        next!(p)
    end
    score
end

"""
    gen_word_reducer_by_target(target_word, guess_word)

Returns a closure that captures the constraints arounds and updates 
the `word_set` given and word attempt. This propagation is done automatically 
for a given `target_word` which the word that the puzzle solver is trying to guess. 

The colsure function has the following signature 

    reduce_wordset_by_word_target!(word_set, word_attempt)

where the `word_attempt` is a guess at the `target_word`. 
"""
function gen_word_reducer_by_target(target_word, guess_word)
    let_in_pos = Dict{Int,Char}()
    let_not_in_pos = Dict{Char,Vector{Int}}()
    let_not_in_word = Set{Char}()
    w = guess_word
    function reduce_wordset_by_word_target!(word_set, word_attempt)
        update_constraints_by_comparison!(target_word,word_attempt,let_in_pos,let_not_in_pos,let_not_in_word)
        filter!(w->all(w[r[1]]==r[2] for r in let_in_pos), word_set)
        filter!(w->all(occursin(s[1],w) && all(w[p]!=s[1] for p in s[2]) for s in let_not_in_pos), word_set)
        filter!(w->all(!occursin(c,w) for c in let_not_in_word), word_set)
    end
end

function steps_to_solve_prob(word_set, w_f_dict, target_word, guess_word)
    word_set_reducer! = gen_word_reducer_by_target(target_word, guess_word)
    word_attempt = guess_word
    word_set = copy(word_set)
    for i=1:6
        word_attempt == target_word && return i
        i==6  && return i 
        word_set = word_set_reducer!(word_set,word_attempt)
        freqs =  [w_f_dict[w] for w in word_set]
        word_attempt = sample(word_set,FrequencyWeights(freqs)) 
    end
end

function steps_to_solve(word_set, target_word, guess_word)
    word_set_reducer! = gen_word_reducer_by_target(target_word, guess_word)
    word_attempt = guess_word
    word_set = copy(word_set)
    for i=1:6
        word_attempt == target_word && return i
        i==6  && return i 
        word_set = word_set_reducer!(word_set,word_attempt)
        word_attempt = rand(word_set) 
    end
end

"""
    calc_score_probs(words,scores)
Calcualtes the depth and safety scores for any array or and their assocaited dictionary 
of that contains the expermental accumelation of success and failures. 
"""
function calc_score_probs(words,scores)
    depth_score = zeros(length(words))
    safety_score = zeros(length(words))
    for i in eachindex(words)
        depth_score[i] = scores[words[i]][1]/scores[words[i]][2]
        safety_score[i] = scores[words[i]][3]/(scores[words[i]][2]+scores[words[i]][3])
    end
    depth_score, safety_score
end