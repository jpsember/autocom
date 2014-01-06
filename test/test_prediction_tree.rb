#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom'

class TestPredictionTree <  Test::Unit::TestCase

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

  def test_prediction_tree
    IORecorder.new.perform do
      corpus = read_corpus
      tree = PredictionTree.build_from_corpus(corpus,3)
      while true
        puts
        line = $stdin.gets.chomp
        break if line == ''
        window = line.to_i
        if window > 0
          tree = PredictionTree.build_from_corpus(corpus,window)
          next
        end
        show_match(tree,line)
      end
    end
  end

  def test_dump_tree
    IORecorder.new.perform do
      corpus = read_corpus
      (2..6).each do |window|
        tree = PredictionTree.build_from_corpus(corpus,window)
        puts "Tree for window size #{window}:\n----------------------------\n#{tree}\n"
      end
    end
  end

  def test_to_json
    IORecorder.new.perform do
      corpus = read_corpus('tiny_corpus')
      tree = PredictionTree.build_from_corpus(corpus,3)
      json = tree.to_json
      puts json
    end
  end

  def test_to_json_large
    IORecorder.new.perform do
      corpus = read_corpus('large_corpus')
      tree = PredictionTree.build_from_corpus(corpus)
      puts tree.to_json
    end
  end

  def test_from_json_large
    IORecorder.new.perform do
      text = FileUtils.read_text_file(file_path('large_corpus_json.txt'))
      tree = PredictionTree.read_from_json(text)
      show_match(tree,'res')
    end
  end

  def test_from_json_1
    text = FileUtils.read_text_file(file_path('json_tree_1.txt'))
    tree = PredictionTree.read_from_json(text)
    IORecorder.new.perform do
      puts tree
      puts
      show_match(tree,'fa z')
    end
  end

  def test_from_json_2
    text = FileUtils.read_text_file(file_path('json_tree_2.txt'))
    tree = PredictionTree.read_from_json(text)
    IORecorder.new.perform do
      puts tree
      puts
      show_match(tree,'and ba')
    end
  end

end
