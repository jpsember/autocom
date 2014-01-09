#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom/app'

class TestPredictionTree <  Test::Unit::TestCase

  def file_path(name)
    File.join(File.dirname(__FILE__),name)
  end

  def show_match(tree,line,show_line=false)
    if show_line
      puts "Matches for line '#{line}':"
    end

    matches = tree.match(line)
    matches.each do |match|
      puts match
    end
    puts if show_line
  end

  def build_from_json(name)
    PredictionTree.read_from_json(FileUtils.read_text_file(file_path("json_tree_#{name}.txt")))
  end

  def test_to_json
    IORecorder.new.perform do
      tree = build_from_json('2')
      json = tree.to_json
      puts json
    end
  end

  def test_to_json_large
    IORecorder.new.perform do
      tree = build_from_json('large')
      json = tree.to_json
      puts json
    end
  end

  def test_from_json_large
    IORecorder.new.perform do
      tree = build_from_json('large')
      show_match(tree,'res')
    end
  end

  def test_from_json_1
    tree = build_from_json('1')
    IORecorder.new.perform do
      puts tree
      puts
      show_match(tree,'fa z')
    end
  end

  def test_from_json_2
    tree = build_from_json('2')
    IORecorder.new.perform do
      puts tree
      puts
      show_match(tree,'and ba')
    end
  end

  def test_from_json_3
    tree = build_from_json('3')
    IORecorder.new.perform do
      puts tree
      puts
      show_match(tree,'a',true)
      puts
      show_match(tree,'aa',true)
      puts
      show_match(tree,'aaa',true)
      puts
      show_match(tree,'aaax',true)
    end
  end


end
