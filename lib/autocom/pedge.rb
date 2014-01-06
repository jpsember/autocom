class PEdge
  attr_accessor :source_node,:destination_node
  attr_accessor :label
  attr_accessor :filter_value

  def initialize
    @filter_value = 0
  end

  def to_s(with_node_ids = true)
    s = ''
    s << "#{@source_node.unique_id} " if with_node_ids
    s << "--#{label}-->"
    s << " #{@destination_node.unique_id}" if with_node_ids
    s << " f#{@filter_value}" if @filter_value != 0
    s
  end

  def inspect
    to_s
  end

end
