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

  # Suggest autocompletions for a word stub at the end of some text.
  # Returns an array of zero or more Match objects
  #
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
      match = Match.new(@match_text,@match_stub,text_accum[0..-2]) # omit the $ suffix
      @matches << [match,node.word_frequency]
    else
      node.edge_list.each do |edge|
        next if edge.filter_value > @match_stub.length
        # Make sure any characters to the left of the cursor match the accumulated text's suffix
        next if (cursor != 0 && edge.label[0..cursor-1] != text_accum[-cursor..-1])
        # Add characters to right of cursor to the accumulated text, and recurse with child node
        match_aux(edge.destination_node,0,text_accum + edge.label[cursor..-1])
      end
    end
  end

  # Compare two strings to see how their prefixes compare, where the
  # prefix length is the length of the smaller of the two strings
  #
  # Returns the result of prefix from a <=> prefix from b
  def self.compare_prefixes(string_a, string_b)
    prefix_length = [string_a.length, string_b.length].min
    result = (string_a[0...prefix_length] <=> string_b[0...prefix_length])
    [prefix_length,result]
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
      edge = node.edge_list.bsearch do |e|
        _,result = self.class.compare_prefixes(e.label,unmatched_stub)
        result >= 0
      end

      break if !edge

      # Verify that the prefix of the found edge is a match (and not strictly greater)
      prefix_length,result = self.class.compare_prefixes(edge.label,unmatched_stub)
      break if result != 0

      if (prefix_length < edge.label.length)
        ret = [node,prefix_length]
        break
      end

      depth += edge.label.length
      node = edge.destination_node
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
