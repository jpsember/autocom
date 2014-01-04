#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom'

class TestCorpus <  Test::Unit::TestCase

  def setup
    enter_test_directory
  end

  def teardown
    leave_test_directory
  end

  def read_corpus
    Corpus.new(FileUtils.read_text_file('../sample_corpus.txt'))
  end

  def test_corpus
    IORecorder.new.perform do
      corpus = read_corpus
      corpus.sentences.each do |sentence|
        puts sentence.join(' ')
      end
    end
  end


  def test_unigram
    IORecorder.new.perform do
      corpus = read_corpus
      unigrams = Ngrams.new(corpus,1)
      puts(unigrams.to_s)
    end
  end

  def test_unigram_match
    IORecorder.new.perform do
      corpus = read_corpus
      unigrams = Ngrams.new(corpus,1)
      matches = unigrams.match('bu',5,-2.2)
      matches.each{|x| puts x}
    end
  end


  def test_bigram
    IORecorder.new.perform do
      corpus = read_corpus
      ngrams = Ngrams.new(corpus,2)
      puts(ngrams.to_s)
    end
  end

  def test_bigram_match
    IORecorder.new.perform do
      corpus = read_corpus
      ngrams = Ngrams.new(corpus,2)
      matches = ngrams.match('after we g',5,nil)
      matches.each{|x| puts x}
    end
  end

end
