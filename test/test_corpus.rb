#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom'

class TestCorpus <  Test::Unit::TestCase

  def read_corpus
    Corpus.new(FileUtils.read_text_file(File.join(File.dirname(__FILE__),'sample_corpus.txt')))
  end

  def test_corpus
    IORecorder.new.perform do
      corpus = read_corpus
      corpus.sentences.each do |sentence|
        puts sentence.join(' ')
      end
    end
  end

end
