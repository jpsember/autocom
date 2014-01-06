class PNode
  attr_accessor :edge_list
  attr_accessor :word_frequency
  attr_accessor :population
  attr_reader :unique_id
  attr_accessor :parent_edge

  @@next_unique_id = 100

  def self.reset_node_ids(id = 100)
    @@start_unique_id = id
    @@next_unique_id = id
  end

  def initialize
    @edge_list = []
    @word_frequency = 0
    @population = 0
    @unique_id = @@next_unique_id
    @@next_unique_id += 1
  end

  def adjust_population(amount = 1)
    @population += amount
  end

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

  def to_s
    s=  "PNode\##{@unique_id}: pop #{self.population} freq #{@word_frequency}"
    @edge_list.each do |edge|
      s << " '#{edge.label}'"
    end
    s
  end

  def inspect
    to_s
  end

  def is_leaf?
    @edge_list.empty?
  end

end
