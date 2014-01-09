#!/usr/bin/env ruby

require 'js_base/test'
require 'autocom/app'

class TestApp <  Test::Unit::TestCase

  def setup
    enter_test_directory
  end

  def teardown
    leave_test_directory
  end

  def test_binary
    FileUtils.cp('../sample_corpus.txt','sample_corpus.txt')
    IORecorder.new.perform do
      AutoComApp.new.run("-c sample_corpus.txt -w 3".split(' '))
    end
  end

  def test_binary_system_call
    # We can't do any system calls that require user input, since we're not connected to a terminal.
    IORecorder.new.perform do
      output,_ = scall('autocom -h')
      puts output
    end
  end

  def test_build_tree_text_file_ext
    FileUtils.cp('../small_corpus.txt','small_corpus.txt')
    IORecorder.new.perform do
      puts
      puts "Building tree from text file, extension provided"
      AutoComApp.new.run("-c small_corpus.txt -w 3".split(' '))
    end
  end

  def test_build_tree_text_file_noext
    FileUtils.cp('../small_corpus.txt','small_corpus.txt')
    IORecorder.new.perform do
      puts
      puts "Building tree from text file, no extension provided"
      AutoComApp.new.run("-c small_corpus -w 3".split(' '))
    end
  end

  def test_read_tree_json_ext
    FileUtils.cp('../json_tree_large.txt','json_tree.predtree')
    IORecorder.new.perform do
      puts
      puts "Reading tree from json, extension provided"
      AutoComApp.new.run("-c json_tree.predtree".split(' '))
    end
  end

  def test_read_tree_json_noext
    FileUtils.cp('../json_tree_large.txt','json_tree.predtree')
    IORecorder.new.perform do
      puts
      puts "Reading tree from json, no extension provided"
      AutoComApp.new.run("-c json_tree".split(' '))
    end
  end

  def test_no_tree_found
    IORecorder.new.perform do
      puts
      puts "Failing for no tree found"
      assert_raise(SystemExit){ AutoComApp.new.run("-c no_such_tree".split(' '))  }
    end
  end


end
