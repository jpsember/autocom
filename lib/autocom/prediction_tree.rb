#!/usr/bin/env ruby

require 'js_base/Pretty'

class PredictionTree

  attr_reader :max_result_items

  def initialize(corpus)
    word_freq_map = build_word_frequency_map(corpus)
    @root_node = build_prediction_tree(word_freq_map)
  end

  def match(text)
    matches = []

    while true

      prefix = calc_prefix(text)
      break if !prefix

      cursor = @ngram_array.bsearch_index{|ngram,freq| ngram >= prefix}
      break if cursor == @ngram_array.size

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
        matches[insert_posn,0] = [[match,freq]]
        matches.pop if matches.size > max_results
      end
      break
    end
    matches.map{|m,f| m}
  end

  def to_s
    s = ''
    to_s_aux(@root_node,s,0,'')
    s
  end


  private


  def to_s_aux(node,s,indent,accum)
    s << ' '*indent << "'#{accum}'"
    if node.word_frequency != 0
      s << " *#{node.word_frequency}"
    end
    s << "\n"
    node.edge_list.each{|edge| to_s_aux(edge.destination_node,s,indent+1,accum+edge.label)}
  end


  class SNode
    attr_accessor :word
    attr_accessor :word_frequency

    def initialize(word,word_frequency)
      @word = word
      @word_frequency = word_frequency
    end

    def to_s
      "#{@word}(#{@word_frequency}) "
    end

    def inspect
      to_s
    end
  end

  class PNode
    attr_accessor :edge_list
    attr_accessor :word_frequency

    def initialize
      @edge_list = []
      @word_frequency = 0
      # Holds population, if <= n; else, a prediction tree containing the n most frequent elements
      @population_or_summary = 0
    end

    def population
      raise ArgumentError if !(@population_or_summary.is_a? Numeric)
      @population_or_summary
    end

    def adjust_population(amount = 1)
      @population_or_summary += amount
    end

    def find_child_node(character)
      index = @edge_list.bsearch_index do |edge|
        edge.label >= character
      end

      # puts "find_child_node char='#{character}', returned index #{index} for edge list #{@edge_list}"

      if index == @edge_list.size || @edge_list[index].label != character
        newedge = PEdge.new
        newedge.destination_node = PNode.new
        newedge.label = character
        @edge_list.insert(index,newedge)
      end
      @edge_list[index].destination_node
    end

    def to_s
      s=  "PNode pop #{self.population} freq:#{@word_frequency}"
      @edge_list.each do |edge|
        s << " '#{edge.label}'"
      end
      s
    end

    def summary(snodes,prefix)
      puts "\ngetting summary for node, prefix='#{prefix}'"

      if !(@population_or_summary.is_a? Numeric)
        @population_or_summary.each do |snode|
          snodes << SNode.new(prefix + snode.word,snode.word_frequency)
          puts "  stored modified snode: #{snodes.last}"
        end
      else
        if @word_frequency != 0
          puts "   ...storing base case (end of word reached)"
          snodes << SNode.new(prefix,@word_frequency)
        end
        @edge_list.each do |child_edge|
          puts "   ...calling recursively for child edge, prefix '#{prefix}', label '#{child_edge.label}'"
          child_edge.destination_node.summary(snodes,prefix+child_edge.label)
        end
      end
    end

    def store_summary(summary)
      @population_or_summary = summary
    end

  end

  class PEdge
    attr_accessor :destination_node
    attr_accessor :label
  end

  def build_prediction_tree(word_frequency_map)
    @max_result_items = 3

    root_node = PNode.new
    word_frequency_map.each_pair do |word,frequency|
      insert_word_into_tree(root_node,word,frequency)
    end

    compress_tree(root_node)

    build_summary_trees(root_node)

    root_node
  end


  def insert_word_into_tree(node,word,word_frequency,cursor = 0)
    node.adjust_population(1)
    if cursor == word.length
      node.word_frequency = word_frequency
    else
      character = word[cursor]
      child_node = node.find_child_node(character)
      insert_word_into_tree(child_node,word,word_frequency,cursor+1)
    end
  end

  # Examine the last several characters of the target text
  # to determine the matching prefix.
  #
  # Return nil if no valid prefix found.
  #
  def calc_prefix(text)
    cursor = text.length

    prefix = nil
    while cursor > 0 && text[cursor-1] != ' '
      cursor -= 1
    end

    prefix = text[cursor..-1] if cursor != text.length
    prefix
  end


  def build_word_frequency_map(corpus)
    word_freq_map = {}
    corpus.sentences.each{|sentence| read_sentence(sentence,word_freq_map)}
    word_freq_map
  end

  def read_sentence(sentence,word_freq_map)
    sentence.each do |word|
      if !word_freq_map.has_key?(word)
        word_freq_map[word] = 1
      else
        word_freq_map[word] += 1
      end
    end
  end

  def compress_tree(node)
    node.edge_list.each do |edge_a|
      while true
        node_b = edge_a.destination_node
        break if node_b.word_frequency != 0
        break if node_b.edge_list.size != 1
        edge_b = node_b.edge_list[0]
        edge_a.label = edge_a.label + edge_b.label
        edge_a.destination_node = edge_b.destination_node
      end
      compress_tree(edge_a.destination_node)
    end
  end

  def build_summary_trees(node,prefix='')
    # Recursively build child node summaries first
    node.edge_list.each{|child_edge| build_summary_trees(child_edge.destination_node,prefix+child_edge.label)}

    return if node.population <= @max_result_items

    # Gather summary items from children
    child_summaries = []
    node.edge_list.each do |child_edge|
      child_node = child_edge.destination_node
      child_summary = []
      child_node.summary(child_summary,prefix+child_edge.label)
      child_summaries << child_summary
    end
    summary = build_summary_from_child_summaries(child_summaries)
    node.store_summary(summary)
    puts "\nstored summary for node:\n#{Pretty.print(summary)}\n"

  end

  def build_summary_from_child_summaries(child_summaries)
    puts "building summary from #{child_summaries.size} child summaries"
    summary = []
    child_summaries.each do |child_summary|
      puts " proc next child"
      child_summary.each do |snode|
        insert_pos = summary.bsearch_index{|snode2| snode2.word > snode.word}
        puts "  insert pos = #{insert_pos} for #{snode}"
        if insert_pos < @max_result_items
          summary.insert(insert_pos,snode)
          summary.pop if summary.size > @max_result_items
        end
      end
    end
    puts " returning summary #{Pretty.print(summary)}\n"
    summary
  end

end
