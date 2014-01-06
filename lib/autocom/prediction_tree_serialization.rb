#!/usr/bin/env ruby

req 'pnode pedge'
require 'json'

class PredictionTreeSerialization

  class VersionError < Exception; end

  VERSION = 201

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
    node_info = []
    node_info << node.word_frequency
    edge_list = []

    node.edge_list.each do |edge|
      edge_info = []

      edge_info << self.build_node(edge.destination_node)
      edge_info << edge.label
      edge_info << edge.filter_value

      edge_list << edge_info
    end
    node_info << edge_list

    node_info
  end

  def self.read_node(node_info)
    # puts "reading node from node_info: #{node_info}"

    frequency,edge_list = node_info
    # puts " freq=#{frequency}"
    # puts " edge_list=#{edge_list}"

    node = PNode.new
    node.word_frequency = frequency
    edges = []
    edge_list.each do |edge_info|
      edge = PEdge.new
      # puts "   ...reading destination node from #{edge_info[0]}"
      edge.destination_node = self.read_node(edge_info[0])
      edge.label = edge_info[1]
      edge.filter_value = edge_info[2]
      # puts "   label=#{edge.label}"
      # puts "   filter=#{edge.filter_value}"
      edges << edge
    end
    node.edge_list = edges
    node
  end

end
