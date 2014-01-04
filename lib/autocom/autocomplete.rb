class AutoComplete

  def initialize(corpus_text,max_results=10,min_log_prob_unigram=nil,min_log_prob_bigram=nil)
    corpus = Corpus.new(corpus_text)
    @unigram = Ngrams.new(corpus,1)
    @bigram = Ngrams.new(corpus,2)
    @max_results = max_results
    @min_log_prob_unigram = min_log_prob_unigram
    @min_log_prob_bigram = min_log_prob_bigram
  end

  def match(text)
    matches_b = @bigram.match(text,@max_results,@min_log_prob_bigram)
    matches_u = @unigram.match(text,@max_results,@min_log_prob_unigram)

    ret = matches_b.dup

    # Concatenate only those unigram matches that don't produce the same text as
    # an existing bigram one
    matches_u.each do |m1|
      equiv = false
      ret.each do |m2|
        if Match.equivalent(m1,m2)
          equiv = true
          break
        end
      end
      next if equiv
      ret << m1
    end
    ret.slice!(@max_results..-1)
    ret
  end

end
