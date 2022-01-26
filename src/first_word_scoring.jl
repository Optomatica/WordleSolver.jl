function word_matches!(s_w,w, let_pos, let_nopos, bad_lets)
    for i in eachindex(w)
        if s_w[i] == w[i]
            let_pos[i]=w[i]
        end
    end
    for i in eachindex(w)
        if w[i] ∉ values(let_pos) && occursin(w[i], s_w)
            let_nopos[w[i]] = push!(get(let_nopos,w[i],Int[]),i)
        end
    end
    for i in eachindex(w)
        if !occursin(w[i],s_w)
          push!(bad_lets,w[i]) 
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

function steps_to_solve_prob(all_words, w_f_dict, target_word, guess_word)
    w = guess_word
    w == target_word && return 1 #No point attempting with same word
    let_pos = Dict{Int,Char}()
    let_nopos = Dict{Char,Vector{Int}}()
    bad_lets = Set{Char}()
    word_attempt = w
    word_set = all_words
    for i=1:6
        word_attempt == target_word && return i
        i==6  && return i 
        word_matches!(target_word,word_attempt,let_pos,let_nopos,bad_lets)
        word_set = filter(w->all(w[r[1]]==r[2] for r in let_pos), word_set)
        word_set  = filter(w->all(occursin(s[1],w) && all(w[p]!=s[1] for p in s[2]) for s in let_nopos), word_set)
        word_set   = filter(w->all(!occursin(c,w) for c in bad_lets), word_set)
        freqs =  [w_f_dict[w] for w in word_set]
        word_attempt = sample(word_set,FrequencyWeights(freqs)) 
    end
end

function steps_to_solve(all_words, target_word, guess_word)
    w = guess_word
    w == target_word && return 1 #No point attempting with same word
    let_pos = Dict{Int,Char}()
    let_nopos = Dict{Char,Vector{Int}}()
    bad_lets = Set{Char}()
    word_attempt = w
    word_set = all_words
    for i=1:6
        word_attempt == target_word && return i
        i==6  && return i 
        word_matches!(target_word,word_attempt,let_pos,let_nopos,bad_lets)
        word_set = filter(w->all(w[r[1]]==r[2] for r in let_pos), word_set)
        word_set  = filter(w->all(occursin(s[1],w) && all(w[p]!=s[1] for p in s[2]) for s in let_nopos), word_set)
        word_set   = filter(w->all(!occursin(c,w) for c in bad_lets), word_set)
        word_attempt = rand(word_set) 
    end
end

function calc_score_probs(words,scores)
    depth_score = zeros(length(words))
    safety_score = zeros(length(words))
    for i in eachindex(words)
        depth_score[i] = scores[words[i]][1]/scores[words[i]][2]
        safety_score[i] = scores[words[i]][3]/(scores[words[i]][2]+scores[words[i]][3])
    end
    depth_score, safety_score
end