#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom'

class TestPredictionTree <  Test::Unit::TestCase

  def read_corpus
    text = FileUtils.read_text_file(File.join(File.dirname(__FILE__),'small_corpus.txt'))
    text = Corpus.process_frequency_tags(text)
    Corpus.new(text)
  end

  def test_prediction_tree
    IORecorder.new.perform do
      corpus = read_corpus
      tree = PredictionTree.new(corpus,3)
      while true
        puts
        line = $stdin.gets.chomp
        break if line == ''
        window = line.to_i
        if window > 0
          tree = PredictionTree.new(corpus,window)
          next
        end
        matches = tree.match(line)
        matches.each do |match|
          puts match
        end
      end
    end
  end

end
