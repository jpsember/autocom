#!/usr/bin/env ruby

require 'tokn'

class Corpus

  @@dfa = nil

  attr_reader :sentences

  def initialize(content_string)
    @sentences = read_corpus(content_string)
  end

  def self.process_frequency_tags(text)
    ends_with_freq = Regexp.new(".*\\.(\\d+)$")
    txt2 = ''
    frequency_token_found = false
    text.lines.each do |line|
      line.chomp!
      match = ends_with_freq.match(line)
      if !frequency_token_found
        return text if !match
        frequency_token_found = true
      end

      if match
        rep = match[1].to_i
        skip_digits = match[1].length + 1
        line = line[0...-skip_digits]
        line += ' '
        line *= rep
      end
      txt2 << line << "\n"
    end
    txt2
  end

  def word_frequency_map
    word_freq_map = {}
    @sentences.each{|sentence| add_sentence_to_frequency_map(sentence,word_freq_map)}
    word_freq_map
  end

  private

  def add_sentence_to_frequency_map(sentence,word_freq_map)
    sentence.each do |word|
      if !word_freq_map.has_key?(word)
        word_freq_map[word] = 1
      else
        word_freq_map[word] += 1
      end
    end
  end

  def read_corpus(content_string)

    sentences = []
    word_buffer = []
    tokenizer = Tokn::Tokenizer.new(Corpus.dfa,content_string,'WS')
    while tokenizer.hasNext
      tok = tokenizer.read

      if tok.id == 2 # WORD
        text = tok.text.downcase
        word_buffer << text
      else
        if word_buffer.size > 0
          sentences << word_buffer
          word_buffer = []
        end
      end
    end
    if word_buffer.size > 0
      sentences << word_buffer
    end

    sentences
  end

  @@dfa_script =  <<-'EOS'
UNKNOWN: [\u0000-\uffff]
WS: [\f\r\s\t\n]+
WORD: [a-zA-Z]+('[a-zA-Z]+)*
EOS
# ' # Sublime gets confused

  def self.dfa
    if !@@dfa
      txt = @@dfa_script
      persist_path = File.join(Dir.home,'.corpus_dfa')
      @@dfa = Tokn::DFA.from_script(txt,persist_path)
    end
    return @@dfa
  end

end
