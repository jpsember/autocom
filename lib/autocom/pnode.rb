class PNode

  attr_accessor :edge_list
  attr_accessor :word_frequency

  # Required only during construction
  attr_accessor :parent_edge

  def initialize
    @edge_list = []
    @word_frequency = 0
  end

  # Find the child node whose label begins with a particular character;
  # if none exists, add one
  #
  def find_child_node(character)
    index = @edge_list.bsearch_index do |edge|
      edge.label >= character
    end

    if index == @edge_list.size || @edge_list[index].label != character
      newedge = PEdge.new
      newedge.destination_node = PNode.new
      newedge.source_node = self
      newedge.label = character
      @edge_list.insert(index,newedge)
      newedge.destination_node.parent_edge = newedge
    end
    @edge_list[index].destination_node
  end

  def is_leaf?
    @edge_list.empty?
  end

end
