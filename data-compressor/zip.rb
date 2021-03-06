#!/usr/bin/env ruby

def compress(original)
  tree = build_tree(original)
  table = build_table(tree)
  compressed = []

  original.bytes.each do |byte|
    bits = look_up_byte(table, byte)
    compressed << bits
  end.flatten

  pack_table(table, compressed)

  compressed
end

def decompress(compressed, data_length)
  table = unpack_table(compressed)

  data_length.times.map do
    look_up_bits(table, bits)
  end.map(&:chr).join
end

def build_tree(original)
  bytes = original.bytes
  unique_bytes = bytes.uniq

  nodes = unique_bytes.map do |byte|
    Leaf.new(byte, bytes.count(byte))
  end

  until nodes.length == 1
    left_node = nodes.delete(nodes.min_by(&:count))
    right_node = nodes.delete(nodes.min_by(&:count))
    count = left_node.count + right_node.count
    nodes << Node.new(left_node, right_node, count)
  end

  nodes.first
end

def build_table(node, path = [])
  if node.is_a?(Node)
    build_table(node.left, path + [0]) + build_table(node.right, path + [1])
  else
    [TableRow.new(node.byte, path)]
  end
end

def look_up_byte(table, byte)
  table.each do |row|
    return row.bits if row.byte == byte
  end

  raise 'oops'
end

def look_up_bits(table, bits)
  table.each do |row|
    if row.bits == bits.take(row.bits.length)
      bits.shift(row.bits.length)
      return row.byte
    end
  end

  raise 'oops'
end

def pack_table(table, compressed)
  compressed.unshift(table.length)

  table.each do |row|
    compressed.unshift(row.byte)
    compressed.unshift(row.bits.length)
    compressed.unshift(row.bits)
  end
end

def unpack_table(compressed)
  table_length = compressed.shift.first

  table = table_length.times.map do
    byte = compressed.shift
    bit_count = compressed.shift
    bits = compressed.shift(bit_count)
    TableRow.new(byte, bits)
  end
end

Node = Struct.new(:left, :right, :count)
Leaf = Struct.new(:byte, :count)

TableRow = Struct.new(:byte, :bits)

original = 'abbcccc'
p original

compressed = compress(original)
p compressed

decompressed = decompress(compressed, original.length)
p decompressed
