#!/usr/bin/env ruby

require 'js_base/Pretty'
req 'pnode pedge'

class PredictionTree

  attr_reader :max_result_items

  def initialize(corpus)
    @max_result_items = 5
    word_freq_map = build_word_frequency_map(corpus)
    build_prediction_tree(word_freq_map)
  end


  def match(text)

    # Set up some temporary instance variables to use during this operation
    @match_text = text
    @matches = []

    while true
      prefix = calc_prefix(text)
      break if !prefix
      @match_prefix = prefix

      node_cursor = find_start_node(prefix)
      break if !node_cursor

      match_aux(node_cursor.node,node_cursor.depth,node_cursor.character_offset,@match_prefix)
      break
    end

    matches = @matches

    # Clear the temporary instance variables
    @matches = nil
    @match_text = nil

    # Sort by frequency
    matches.sort!{|a,b| b[1] <=> a[1]}

    # Strip the frequency component from the result
    matches.map{|m,f| m}
  end

  def to_s
    s = ''
    to_s_aux(@root_node,s,0,'')
    s
  end


  private


  def match_aux(node,filter_value,character_offset,text_accum)
    if node.is_leaf?
      # Omit the $ we added along the last edge
      match = Match.new(@match_text,@match_prefix,text_accum[0...-1])
      @matches << [match,node.word_frequency]
    else
      node.edge_list.each do |edge|
        next if edge.filter_value > filter_value
        # If the initial text prefix did not contain the entire start node label,
        # make sure that portion of the text prefix agrees with this edge's label
        if character_offset > 0
          label_prefix = edge.label[0...character_offset]
          text_to_add = edge.label[character_offset..-1]
          next if label_prefix != text_accum[-character_offset..-1]
        else
          text_to_add = edge.label
        end
        match_aux(edge.destination_node,filter_value,0,text_accum+text_to_add)
      end
    end
  end

  class NodeCursor
    attr_accessor :node,:depth,:character_offset
    def initialize(node,depth,character_offset)
      @node = node
      @depth = depth
      @character_offset = character_offset
    end
    def to_s
      "NodeCursor[ node=#{@node} depth=#{@depth} ch.offset=#{@character_offset} ]"
    end
  end

  def find_start_node(prefix,node=@root_node,depth=0)
    if depth==prefix.length
      return NodeCursor.new(node,depth,0)
    end

    suffix = prefix[depth..-1]
    # Find an edge whose label is a prefix for the suffix
    active_edge = nil
    active_prefix_size = nil
    node.edge_list.each do |edge|
      label = edge.label
      label_prefix_size = [prefix.length-depth,label.length].min
      label_prefix = label[0...label_prefix_size]
      if suffix.start_with?(label_prefix)
        active_edge = edge
        active_prefix_size = label_prefix_size
        break
      end
    end
    return nil if !active_edge

    unimp "clean this up later"
    depth_adjustment = active_prefix_size
    if active_prefix_size < active_edge.label.length
      return NodeCursor.new(node,depth+depth_adjustment,depth_adjustment)
    end

    return find_start_node(prefix,active_edge.destination_node,depth+depth_adjustment)
  end

  def to_s_aux(node,s,indent,accum)
    s << ' '*indent << "#{node.unique_id}: "
    if node.is_leaf?
      s << "'#{accum[0...-1]}' *#{node.word_frequency}"
    end
    s << "\n"
    node.edge_list.each do |edge|
      s << ' '*(2+indent) << edge.to_s(false) << "\n"
      to_s_aux(edge.destination_node,s,indent+4,accum+edge.label)
    end

  end

  def build_prediction_tree(word_frequency_map)
    PNode.reset_node_ids

    @root_node = PNode.new
    word_frequency_map.each_pair do |word,frequency|
      insert_word_into_tree(@root_node,word+'$',frequency)
    end

    # It would be nice if the edge filters could be done as the tree was being constructed;
    # but then again, we can't expect to compress the tree simultaneously, so keep it simple
    install_edge_filters(@root_node,0)

    compress_tree(@root_node)
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
        break if node_b.edge_list.size != 1
        edge_b = node_b.edge_list[0]
        assert!(edge_a.filter_value == edge_b.filter_value)
        node_c = edge_b.destination_node
        edge_a.label = edge_a.label + edge_b.label
        edge_a.destination_node = node_c
        node_c.parent_edge = edge_a
      end
      compress_tree(node_b)
    end
  end

  def install_edge_filters(node,node_depth)
    leaf_nodes = []
    if node.is_leaf?
      leaf_nodes << node
    else
      node.edge_list.each do |child_edge|
        child_node = child_edge.destination_node
        leaf_nodes.concat(install_edge_filters(child_node,node_depth+1))
      end

      # Sort leaf nodes by highest frequency first
      leaf_nodes.sort!{|a,b| b.word_frequency <=> a.word_frequency}
      while leaf_nodes.length > @max_result_items
        leaf_node = leaf_nodes.pop
        filter_word(leaf_node.parent_edge,node_depth+1)
      end
    end
    leaf_nodes
  end

  def filter_word(edge,filter_depth)
    while edge
      break if edge.filter_value >= filter_depth
      edge.filter_value = filter_depth
      parent_node = edge.source_node
      # Propagate the lowest of the sibling edges' filter values upward
      filter_depth = parent_node.edge_list.inject(filter_depth){|f,e| f = [f,e.filter_value].min}
      edge = parent_node.parent_edge
    end
  end

end
