#!/usr/bin/env ruby

require 'js_base/Pretty'
req 'pnode pedge'

class PredictionTree

  attr_reader :max_result_items

  def initialize(corpus)
    word_freq_map = build_word_frequency_map(corpus)
    build_prediction_tree(word_freq_map)
  end


  def match_aux(node,filter_value,text_accum)
    if node.word_frequency != 0
      # Omit the $ we added along the last edge
      match = Match.new(@match_text,@match_prefix,text_accum[0...-1])
      @matches << [match,node.word_frequency]
    else
      node.edge_list.each do |edge|
        next if edge.filter_value > filter_value
        match_aux(edge.destination_node,filter_value,text_accum+edge.label)
      end
    end
  end

  def match(text)
    @match_text = text
    @matches = []

    while true
      prefix = calc_prefix(text)
      break if !prefix
      @match_prefix = prefix

      node,depth = find_start_node(prefix)
      break if !node

      match_aux(node,depth,@match_prefix)
      break
    end

    # Sort by frequency
    @matches.sort!{|a,b| b[1] <=> a[1]}

    @matches.map{|m,f| m}
  end

  def to_s
    s = ''
    to_s_aux(@root_node,s,0,'')
    s
  end


  private


  def find_start_node(prefix,node=@root_node,depth=0)
    return [node,depth] if depth==prefix.length
    suffix = prefix[depth..-1]
    # Find an edge whose label is a prefix for the suffix
    active_edge = nil
    node.edge_list.each do |edge|
      if suffix.start_with?(edge.label)
        active_edge = edge
        break
      end
    end
    return [nil,nil] if !active_edge

    depth_adjustment = active_edge.label.length
    return find_start_node(prefix,active_edge.destination_node,depth+depth_adjustment)
  end

  def to_s_aux(node,s,indent,accum)
    s << ' '*indent << "#{node.unique_id}: '#{accum}'"
    if node.word_frequency != 0
      s << " *#{node.word_frequency}"
    end
    s << "\n"
    indent += 1
    node.edge_list.each do |edge|
      s << ' '*indent << edge.to_s << "\n"
      to_s_aux(edge.destination_node,s,indent,accum+edge.label)
    end
    indent -= 1
  end


  def build_prediction_tree(word_frequency_map)
    PNode.reset_node_ids

    @max_result_items = 5

    @root_node = PNode.new
    word_frequency_map.each_pair do |word,frequency|
      insert_word_into_tree(@root_node,word+'$',frequency)
    end

    apply_edge_filters(@root_node,0)

    # compress_tree(root_node)

    # build_summary_trees(root_node)

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

  def apply_edge_filters(node,node_depth)
    leaf_nodes = []
    # Is this a leaf node?
    if node.word_frequency != 0
      leaf_nodes << node
    else
      node.edge_list.each do |child_edge|
        child_node = child_edge.destination_node
        leaf_nodes.concat(apply_edge_filters(child_node,node_depth+1))
      end

      # Sort leaf nodes by highest frequency first
      leaf_nodes.sort!{|a,b| b.word_frequency <=> a.word_frequency}
      while leaf_nodes.length > @max_result_items
        filter_word(leaf_nodes.pop,node_depth+1)
      end
    end
    # puts "apply edge filters for #{node}, leaf nodes:\n #{Pretty.print(leaf_nodes)}"
    leaf_nodes
  end

  def filter_word(leaf_node,filter_depth)
    node = leaf_node
    while true
      edge = node.parent_edge
      break if !edge
      parent = edge.source_node
      break if edge.filter_value >= filter_depth
      # puts "  changing edge #{edge} filter from #{edge.filter_value} to #{filter_depth}"
      edge.filter_value = filter_depth
      node = parent
      # Propagate the lowest of the child edge filter values
      filter_depth = node.edge_list.inject(filter_depth){|f,e| f = [f,e.filter_value].min}
    end
  end

end
