class PEdge

  attr_accessor :destination_node
  attr_accessor :label
  attr_accessor :filter_value

  # Required only during construction:
  attr_accessor :source_node

  def initialize
    @filter_value = 0
  end

  def to_s
    s = ''
    s << "--#{label}-->"
    s << " f#{@filter_value}" if @filter_value != 0
    s
  end

end
