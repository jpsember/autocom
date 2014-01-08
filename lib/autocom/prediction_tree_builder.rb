# Subclasses of PredictionTree that builds it from a word frequency map
#
class PredictionTreeBuilder < PredictionTree

  def self.build_from_word_frequency_map(map,window_size=5)
    tree = PredictionTreeBuilder.new
    tree.build_from_word_frequency_map_aux(map,window_size)
    tree
  end

  def build_from_word_frequency_map_aux(word_frequency_map,window_size=5)
    @window_size = window_size
    self.root_node = PNodeEnhanced.new
    word_frequency_map.each_pair do |word,frequency|
      insert_word_into_tree(self.root_node,word+'$',frequency)
    end
    install_edge_filters
    compress_tree
  end


  private


  # Subclasses of PNode, PEdge that include extra fields required for building only

  class PNodeEnhanced < PNode
    attr_accessor :parent_edge
  end

  class PEdgeEnhanced < PEdge
    attr_accessor :source_node
  end

  # Find a node's child node whose label begins with a particular character;
  # if none exists, add one
  #
  def find_child_node(node,character)
    edge_list = node.edge_list
    index = node.edge_list.binary_search do |edge|
      edge.label >= character
    end

    if index == edge_list.size || edge_list[index].label != character
      newedge = PEdgeEnhanced.new
      newedge.destination_node = PNodeEnhanced.new
      newedge.source_node = node
      newedge.label = character
      edge_list.insert(index,newedge)
      newedge.destination_node.parent_edge = newedge
    end
    edge_list[index].destination_node
  end

  def insert_word_into_tree(node,word,word_frequency,cursor = 0)
    if cursor == word.length
      node.word_frequency = word_frequency
    else
      character = word[cursor]
      child_node = find_child_node(node,character)
      insert_word_into_tree(child_node,word,word_frequency,cursor+1)
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
