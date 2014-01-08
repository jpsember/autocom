#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom/prediction_tree_builder'

class TestPredictionTreeBuilder <  Test::Unit::TestCase

  def setup
    build_json_trees_if_missing
  end


  def file_path(name)
    File.join(File.dirname(__FILE__),name)
  end

  def read_corpus(path='small_corpus')
    text = FileUtils.read_text_file(file_path("#{path}.txt"))
    text = Corpus.process_frequency_tags(text)
    Corpus.new(text)
  end

  def show_match(tree,line)
    matches = tree.match(line)
    matches.each do |match|
      puts match
    end
  end

  def build_from_corpus(corpus,window)
    PredictionTreeBuilder.build_from_word_frequency_map(corpus.word_frequency_map,window)
  end

  def build_json_trees_if_missing
    info = ['1','tiny_corpus',2,'2','small_corpus',3,'3','small_corpus2',5,'large','large_corpus',10]
    i = 0
    while i < info.size
      source_name = info[i+1]
      dest_path = file_path("json_tree_#{info[i]}.txt")
      window = info[i+2]
      i += 3
      if !File.exists?(dest_path)
        corpus = read_corpus(source_name)
        tree = build_from_corpus(corpus,window)
        FileUtils.write_text_file(dest_path,tree.to_json)
      end
    end
  end

  def test_prediction_tree_various_window_sizes
    IORecorder.new.perform do
      corpus = read_corpus
      tree = nil
      window = 3
     puts "\nType a prefix and press return for match, or number to change window size; blank to quit"
      while true
        if !tree
          tree = build_from_corpus(corpus,window)
        end
        puts
        line = $stdin.gets.chomp
        break if line == ''
        window = line.to_i
        if window > 0
          tree = nil
        else
          show_match(tree,line)
        end
      end
    end
  end

  def test_small_corpus2
    IORecorder.new.perform do
      corpus = read_corpus('small_corpus2')
      tree = build_from_corpus(corpus,10)
      puts tree.to_json
    end
  end


end
