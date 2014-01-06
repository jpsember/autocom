req 'pnode pedge prediction_tree_serialization'

class PredictionTree

  attr_reader :max_result_items

  def self.build_from_corpus(corpus,window_size=5)
    tree = PredictionTree.new(nil)
    tree.build_from_corpus_aux(corpus,window_size)
    tree
  end

  def self.read_from_json(json_string)
    root_node = PredictionTreeSerialization.read_from_json(json_string)
    self.new(root_node)
  end

  def to_json
    PredictionTreeSerialization.to_json(@root_node)
  end

  def initialize(root_node)
    @root_node = root_node
  end

  def match(text)

    # Set up some temporary instance variables to use during this operation
    @match_text = text
    @match_stub = nil
    @matches = []

    while true
      @match_stub = calculate_stub(text)
      break if !@match_stub

      node_cursor = find_start_node
      break if !node_cursor

      match_aux(node_cursor.node,node_cursor.depth,node_cursor.character_offset,@match_stub)
      break
    end

    matches = @matches

    # Clear the temporary instance variables
    @matches = nil
    @match_text = nil
    @match_stub = nil

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

  def build_from_corpus_aux(corpus,window_size=5)
    @window_size = window_size
    word_freq_map = build_word_frequency_map(corpus)
    build_prediction_tree(word_freq_map)
  end


  private


  def match_aux(node,filter_value,character_offset,text_accum)
    if node.is_leaf?
      # Omit the $ we added along the last edge
      match = Match.new(@match_text,@match_stub,text_accum[0...-1])
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
  end

  def find_start_node
    node = @root_node
    depth = 0
    ret = nil
    while true
      # Get the portion of the stub we haven't matched yet
      unmatched_stub = @match_stub[depth..-1]

      if unmatched_stub.length == 0
        ret = NodeCursor.new(node,depth,0)
        break
      end

      # Find the (at most one) edge whose label is a prefix for the unmatched stub portion
      found_edge = nil
      found_prefix_size = nil
      node.edge_list.each do |edge|
        label = edge.label
        label_prefix_size = [unmatched_stub.length,label.length].min
        label_prefix = label[0...label_prefix_size]
        if unmatched_stub.start_with?(label_prefix)
          found_edge = edge
          found_prefix_size = label_prefix_size
          break
        end
      end
      break if !found_edge

      depth += found_prefix_size
      if found_prefix_size < found_edge.label.length
        ret = NodeCursor.new(node,depth,found_prefix_size)
        break
      end
      node = found_edge.destination_node
    end
    ret
  end

  def to_s_aux(node,s,indent,accum)
    s << ' '*indent
    if node.is_leaf?
      s << "'#{accum[0...-1]}' *#{node.word_frequency}"
    end
    s << "\n"
    node.edge_list.each do |edge|
      s << ' '*(2+indent) << edge.to_s << "\n"
      to_s_aux(edge.destination_node,s,indent+4,accum+edge.label)
    end
  end

  def build_prediction_tree(word_frequency_map)
    @root_node = PNode.new
    word_frequency_map.each_pair do |word,frequency|
      insert_word_into_tree(@root_node,word+'$',frequency)
    end
    install_edge_filters
    compress_tree
  end


  def insert_word_into_tree(node,word,word_frequency,cursor = 0)
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
  def calculate_stub(text)
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

  def install_edge_filters
    install_edge_filters_aux(@root_node,0)
  end

  def install_edge_filters_aux(node,node_depth)
    leaf_nodes = []
    if node.is_leaf?
      leaf_nodes << node
    else
      node.edge_list.each do |child_edge|
        child_node = child_edge.destination_node
        leaf_nodes.concat(install_edge_filters_aux(child_node,node_depth+1))
      end

      # Sort leaf nodes by highest frequency first
      leaf_nodes.sort!{|a,b| b.word_frequency <=> a.word_frequency}
      while leaf_nodes.length > @window_size
        leaf_node = leaf_nodes.pop
        add_filter_to_edge(leaf_node.parent_edge,node_depth+1)
      end
    end
    leaf_nodes
  end

  def add_filter_to_edge(edge,filter_depth)
    while edge
      break if edge.filter_value >= filter_depth
      edge.filter_value = filter_depth
      parent_node = edge.source_node
      # Propagate the lowest of the sibling edges' filter values upward
      filter_depth = parent_node.edge_list.inject(filter_depth){|f,e| f = [f,e.filter_value].min}
      edge = parent_node.parent_edge
    end
  end

  def compress_tree
    compress_tree_aux(@root_node)
  end

  def compress_tree_aux(node)
    node.edge_list.each do |edge_a|
      while true
        node_b = edge_a.destination_node
        break if node_b.edge_list.size != 1
        edge_b = node_b.edge_list[0]
        node_c = edge_b.destination_node
        edge_a.label = edge_a.label + edge_b.label
        edge_a.destination_node = node_c
        node_c.parent_edge = edge_a
      end
      compress_tree_aux(node_b)
    end
  end

end
