#!/usr/bin/env ruby

req 'pnode pedge'
require 'json'

class PredictionTreeSerialization

  class VersionError < Exception; end

  VERSION = 202

  def self.read_from_json(json_string)
    map = JSON.parse(json_string)
    version = map['version']
    raise VersionError,"unexpected version: '#{version}'" if version != VERSION
    self.read_node(map['root_node'])
  end

  def self.to_json(root_node)
    map = {}
    map['version'] = VERSION
    map['root_node'] = self.build_node(root_node)
    map.to_json
  end


  private


  def self.build_node(node)
    node_info = nil
    if node.is_leaf?
      node_info = node.word_frequency
    else
      edge_list = []
      node.edge_list.each do |edge|
        edge_info = []

        edge_info << self.build_node(edge.destination_node)
        edge_info << edge.label
        edge_info << edge.filter_value

        edge_list << edge_info
      end
      node_info = edge_list
    end
    node_info
  end

  def self.read_node(node_info)
    node = PNode.new
    if node_info.is_a? Numeric
      node.word_frequency = node_info
    else
      edges = []
      node_info.each do |edge_info|
        edge = PEdge.new
        edge.destination_node = self.read_node(edge_info[0])
        edge.label = edge_info[1]
        edge.filter_value = edge_info[2]
        edges << edge
      end
      node.edge_list = edges
    end
    node
  end

end
