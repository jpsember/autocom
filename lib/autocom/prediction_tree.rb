req 'pnode pedge prediction_tree_serialization'

class PredictionTree

  attr_accessor :root_node

  def self.read_from_json(json_string)
    tree = PredictionTree.new
    tree.root_node = PredictionTreeSerialization.read_from_json(json_string)
    tree
  end

  def to_json
    PredictionTreeSerialization.to_json(@root_node)
  end

  def match(text)

    # Set up some temporary instance variables to use during this operation
    @match_text = text
    @match_stub = nil
    @matches = []

    while true
      @match_stub = calculate_stub(text)
      break if !@match_stub

      node,cursor = find_start_node
      break if !node

      match_aux(node,cursor,@match_stub)
      break
    end

    # Sort by frequency
    @matches.sort!{|a,b| b[1] <=> a[1]}

    # Strip the frequency component from the result
    @matches.map{|m,f| m}
  end

  def to_s
    s = ''
    to_s_aux(@root_node,s,0,'')
    s
  end


  private


  def match_aux(node,cursor,text_accum)
    if node.is_leaf?
      # Omit the $ we added along the last edge
      match = Match.new(@match_text,@match_stub,text_accum[0...-1])
      @matches << [match,node.word_frequency]
    else
      node.edge_list.each do |edge|
        next if edge.filter_value > @match_stub.length
        # If the cursor is nonzero, the edge labels include prefixes that we must match to the stub
        if cursor > 0
          label_prefix = edge.label[0..cursor-1]
          next if label_prefix != text_accum[-cursor..-1]
          text_to_add = edge.label[cursor..-1]
        else
          text_to_add = edge.label
        end
        match_aux(edge.destination_node,0,text_accum + text_to_add)
      end
    end
  end

  # Find the position within the tree corresponding to the autocompletion stub
  #
  # Returns [<node>, <position within label>]; uf stub doesn't match any word in the tree, <node> is nil
  #
  def find_start_node
    node = @root_node
    depth = 0
    ret = [nil,0]

    while true
      # Get the portion of the stub we haven't matched yet
      unmatched_stub = @match_stub[depth..-1]

      if unmatched_stub.length == 0
        ret = [node,0]
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
        ret = [node,found_prefix_size]
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

end
