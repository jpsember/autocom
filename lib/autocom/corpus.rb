#!/usr/bin/env ruby

require 'tokn'

class Corpus

  @@dfa = nil

  attr_reader :sentences

  def initialize(content_string)
    @sentences = read_corpus(content_string)
  end


  private


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
