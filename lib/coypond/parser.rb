module Coypond
  class Parser
    
    attr_reader :classes, :modules, :methods
    
    def initialize
      @classes = {}
      @modules = {}
      @methods = {}
    end
    
    def extract_ref(type, *tail)
      case type
      when :const_path_ref
        var_ref = extract_ref(*(tail.first)).first
        name, location = extract_const_and_location(tail[1])
        return [[var_ref, name].join("::"), location]
      else
        return extract_const_and_location(tail.first)
      end
    end
    
    def parse(parse_tree, prefix=nil)
      return self unless parse_tree.is_a? Array
      case parse_tree.first
      when :module
        name, location = extract_ref(*(parse_tree[1]))
        prefix = [prefix, name].compact.join("::")
        @modules[prefix] = location
        parse_tree[2..-1].each do |pt|
          parse(pt, prefix)
        end
      when :class
        name, location = extract_ref(*(parse_tree[1]))
        prefix = [prefix, name].compact.join("::")
        @classes[prefix] = location
        parse_tree[2..-1].each do |pt|
          parse(pt, prefix)
        end
      when :def
        name, location = extract_const_and_location(parse_tree[1])
        prefix = [prefix, name].compact.join("#")
        @methods[prefix] = location
      else
        parse_tree[1..-1].each do |pt|
          parse(pt, prefix)
        end
      end
      return self
    end
    
    private
    def extract_const_and_location(tuple)
      return tuple[1..2]
    end
    
  end
end