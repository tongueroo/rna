class Node < Hash
  class Attribute
    attr_reader :value
    def initialize(value)
      @value = value
    end
    def [](key)
      puts "Node::Attribute key #{key}"
      nil
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
    if @data[key].nil?
      result = @data[key] = Node.new
    elsif @data[key].is_a?(Node::Attribute)
      result = @data[key].value
    elsif @data[key].is_a?(Node)
      result = @data[key]
    else
      raise "should never happen"
    end
    result
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

private
  def convert_key(key)
    key.to_sym
  end
end
