class PEdge
  attr_accessor :source_node,:destination_node
  attr_accessor :label
  attr_accessor :filter_value

  def initialize
    @filter_value = 0
  end

  def to_s
    #" --'#{label}'-> "
    "#{@source_node.unique_id} --'#{label}'--> #{@destination_node.unique_id} (f #{filter_value})"
  end

  def inspect
    to_s
  end

end
