
function solve_wordle(words, freqs, first_w_score)
    w_f_dict = Dict(zip(words,freqs))
    print("Enter guess word (empty for auto-suggestion): ")
    w=readline()
    if length(w) < 5
        w = sample(words,Weights(tight_scale(first_w_score)))
        println("First guess word is: $w")
    end
    let_pos = Dict{Int,Char}()
    let_nopos = Dict{Char,Vector{Int}}()
    bad_lets = Set{Char}()
    word_set = words
    for i=2:7   
        # Parsing response
        println("For each character enter (0 - gray (mistake), 1 - yellow (wrong placement), 2 - green (correct)) ")
        resp = readline()
        while !occursin(r"^[012]{5}$",resp)
            println("Try again:")
            resp = readline()
        end
        if resp == "22222"
            println("Congratulations, you solved after $(i-1) guesses")
            return
        end
        i == 7 && break
        for j in eachindex(resp)
            c = resp[j]
            if c=='2'
                let_pos[j]=w[j]
            elseif c=='1'
                let_nopos[w[j]] = push!(get(let_nopos,w[j],Int[]),j)
            else
                push!(bad_lets,w[j]) 
            end
        end
        # Word recomendation 
        word_set = filter(w->all(w[r[1]]==r[2] for r in let_pos), word_set)
        word_set  = filter(w->all(occursin(s[1],w) && all(w[p]!=s[1] for p in s[2]) for s in let_nopos), word_set)
        word_set   = filter(w->all(!occursin(c,w[setdiff(1:5,keys(let_pos))]) for c in setdiff(bad_lets,keys(let_nopos))), word_set)
        freqs =  [w_f_dict[w] for w in word_set]
        print("Enter next guess word (empty for auto-suggestion): ")
        w=readline()
        if length(w) < 5
            if length(word_set) == 1
                println("It can only be $(word_set[1])")
                return
            end
            w = sample(word_set,FrequencyWeights(freqs)) 
            println("Out of a possible $(length(word_set)) words, why don't you try: $w")
        end
    end
    println("Too bad, you didn't make it this time!")
end

function tight_scale(weights)
    w_min , w_max = extrema(weights)
    exp_skew((w_max .- weights)./(w_max - w_min),10)
end

exp_skew(w,k=1) = (exp.(k .* w) .-1)/(exp(k)-1)