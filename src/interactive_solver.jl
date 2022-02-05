"""
    update_constraints_by_response!(word, response, let_in_pos, let_not_in_pos, let_not_in_word)
Given a `word` and `response` string we update the constraints the reduce the set of possbile words. 

The `response` elements are such that 0 means that the character is not in the word, 1 means the that 
character is the word but not in the right spot, and 2 means that the character is in the word at the correct spot. 

See also [`word_set_reduction!`](@ref)
"""
function update_constraints_by_response!(word, response, let_in_pos, let_not_in_pos, let_not_in_word)
    for (i,w_c) in enumerate(word)
        c = response[i]
        if c=='2'
            let_in_pos[i]=w_c
        elseif c=='1'
            let_not_in_pos[w_c] = push!(get(let_not_in_pos,w_c,Int[]),i)
        else
            push!(let_not_in_word,w_c) 
        end
    end
end

"""
    word_set_reduction!(word_set, let_in_pos, let_not_in_pos, let_not_in_word)

# Arguments
- `word_set` a Vector{String} that will be modified the by the constraints in subsequent arguments 
- `let_in_pos` a Dict{Int,Char} mapping position to letter
- `let_not_in_pos` a Dict{Char,Vector{Int}}() mapping a letter to all the positons where it is improperly placed
- `let_not_in_word` a Set{Char}() for all letters not the secret word
    
"""
function word_set_reduction!(word_set, let_in_pos, let_not_in_pos, let_not_in_word)
    filter!(w->all(w[r[1]]==r[2] for r in let_in_pos), word_set)
    filter!(w->all(occursin(s[1],w) && all(w[p]!=s[1] for p in s[2]) for s in let_not_in_pos), word_set)
    filter!(w->all(!occursin(c,w[setdiff(1:5,keys(let_in_pos))]) for c in setdiff(let_not_in_word,keys(let_not_in_pos))), word_set)
end

"""
    solve_wordle(words, freqs, first_w_score, max_steps=6)
An interactive solver for the **Wordle** game. 
# Arguments
- `words` is a vector of words in the dictionary os possible words
- `freqs` is the correspoding frequency of words
- `first_w_score` a correpoding score for selecting the first word
- `max_steps` the maximux steps that are allowed in the game
"""
function solve_wordle(words, freqs, first_w_score, max_steps=6)
    w_f_dict = Dict(zip(words,freqs))
    let_in_pos = Dict{Int,Char}()
    let_not_in_pos = Dict{Char,Vector{Int}}()
    let_not_in_word = Set{Char}()
    word_set = copy(words)
    for i=1:max_steps   
        if i==1
            println("Enter guess word (empty for auto-suggestion): ")
            w=readline()
            if length(w) < 5
                w = sample(words,Weights(tight_scale(first_w_score)))
                println("First guess word is:")
                printstyled("$w\n",color=:green)
            end
        println("For each character enter (0 - gray (mistake), 1 - yellow (wrong placement), 2 - green (correct)) ")
        else
            np = length(word_set)
            println("We now have $np possible word$(ifelse(np>1,"s","")).\nEnter next guess word (empty for auto-suggestion): ")
            w=readline()
            if length(w) < 5 # We sample
                w=="l" && println("Word Set: "*join(word_set,", ")*".")
                length(word_set) == 1 && (println("It can only be '$(word_set[1])'. Done after $i guesses."); return)
                length(word_set) == 0 && (println("Can not help you further, possible word set exhausted");break)
                w = sample(word_set,FrequencyWeights(freqs)) 
                println("Why don't you try:")
                printstyled("$w\n",color=:green)
            end
        end
        # Parsing response
        resp = readline()
        while !occursin(r"^[012]{5}$",resp)
            println("Try again:")
            resp = readline()
        end
        if resp == "22222"
            println("Congratulations, you solved after $(i) guesses")
            return
        end
        update_constraints_by_response!(w, resp, let_in_pos, let_not_in_pos, let_not_in_word)
        # Word recomendation 
        word_set_reduction!(word_set, let_in_pos, let_not_in_pos, let_not_in_word)
        freqs =  [w_f_dict[w] for w in word_set]
    end
    println("Too bad, you didn't make it this time!")
end

function tight_scale(weights)
    w_min , w_max = extrema(weights)
    exp_skew((w_max .- weights)./(w_max - w_min),10)
end

exp_skew(w,k=1) = (exp.(k .* w) .-1)/(exp(k)-1)