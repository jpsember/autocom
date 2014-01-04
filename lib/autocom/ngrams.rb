#!/usr/bin/env ruby

class Array

  def bsearch_index
    found = nil
    min = 0
    max = self.size
    while min < max
      mid = (min+max)/2
      result = yield(at(mid))
      # puts " min #{min} max #{max} mid #{mid} elem=#{at(mid)} result #{result}"
      if !result
        min = mid + 1
      else
        if !found || found > mid
          found = mid
        end
        max = mid
      end
    end
    found
  end
end


class Ngrams

  attr_reader :n

  def initialize(corpus, n)
    @n = n
    ngram_map = build(corpus)
    @freq_sum = calc_freq_sum(ngram_map)
    @ngram_array = build_ngram_array(ngram_map)
  end

  def to_s
    s = "#{self.n}-gram (#{@freq_sum} total)\n"
    s << "-------------------\n"
    @ngram_array.each{|ngram,freq| s << "#{ngram} #{freq}\n"}
    s
  end

  def match(text,max_results=5,min_log_prob=nil)
    matches = []

    while true

      prefix = calc_prefix(text)
      break if !prefix || prefix.end_with?(' ')

      min_freq = calc_min_freq(min_log_prob)

      cursor = @ngram_array.bsearch_index{|ngram,freq| ngram >= prefix}
      break if !cursor

      while cursor < @ngram_array.size
        ngram,freq = @ngram_array[cursor]
        cursor += 1

        break if !ngram.start_with?(prefix)
        next if freq < min_freq

        match = Match.new(text,prefix,ngram)
        info = (@n == 1) ? 'Unigram' : 'Bigram'
        info << " f:#{freq}"
        match.info = info

        # Insert into position based on frequency
        insert_posn = matches.bsearch_index{|ng,fr| freq >= fr}
        insert_posn = matches.length if !insert_posn
        matches[insert_posn,0] = [[match,freq]]
        matches.pop if matches.size > max_results
      end
      break
    end
    matches.map{|m,f| m}
  end


  private


  def calc_min_freq(min_log_prob)
    min_freq = 0
    if min_log_prob
      min_freq = 10 ** min_log_prob * @freq_sum
    end
    min_freq
  end


  # Examine the last several characters of the target text
  # to determine the matching prefix.
  #
  # Return nil if no valid prefix found.
  #
  def calc_prefix(text)
    cursor = text.length
    spaces_remaining = self.n

    prefix = nil
    while cursor >= 0
      if cursor == 0 || text[cursor-1] == ' '
        spaces_remaining -= 1
        if spaces_remaining == 0
          prefix = text[cursor..-1]
          if prefix.length == 0 || prefix.end_with?(' ')
            prefix = nil
          end
          break
        end
      end
      cursor -= 1
    end
    prefix
  end



  def build_ngram_array(ngram_map)
    keys = ngram_map.keys.sort
    keys.map{|key| [key, ngram_map[key]]}
  end

  def calc_freq_sum(ngram_map)
    sum = 0
    ngram_map.each_pair{|key,val| sum += val}
    sum
  end


  def build(corpus)
    ngram_map = {}
    corpus.sentences.each{|sentence| read_sentence(sentence,ngram_map)}
    ngram_map
  end

  def read_sentence(sentence,ngram_map)
    word_list = []
    sentence.each do |word|
      word_list << word
      if word_list.size == @n
        ngram = word_list.join(' ')
        if !ngram_map.has_key?(ngram)
          ngram_map[ngram] = 1
        else
          ngram_map[ngram] += 1
        end
        word_list.shift
      end
    end
  end

end
