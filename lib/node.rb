require 'mash'

class Node < Hash
  class Attribute
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  def initialize
    @data = {}
    super
  end

  def []=(key,value)
    key = convert_key(key)
    result = super
    attribute = Attribute.new(result)
    @data[key] = attribute
  end

  def [](key)
    key = convert_key(key)
    case @data[key]
    when nil
      @data[key] = Node.new
    when Node::Attribute
      @data[key].value
    when Node
      @data[key]
    else
      raise "should never happen"
    end
  end

  def to_hash
    hash = {}
    @data.each do |key,item|
      if item.is_a?(Node)
        hash[key] = item.to_hash
      else
        hash[key] = item.value
      end
    end
    hash
  end

  def to_mash
    Mash.from_hash(to_hash)
  end

private
  def convert_key(key)
    key.to_sym
  end
end
