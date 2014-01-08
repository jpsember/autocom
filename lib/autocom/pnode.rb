class PNode

  attr_accessor :edge_list
  attr_accessor :word_frequency   # nonzero for leaf nodes only

  def initialize
    @edge_list = []
    @word_frequency = 0
  end

  def is_leaf?
    @edge_list.empty?
  end

end
