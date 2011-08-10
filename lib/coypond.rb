require 'ripper'
require File.expand_path('../coypond/parser', __FILE__)

module Coypond
  class CoypondRunner
    
    def initialize(files)
      @files = files
    end
    
    def search(options)
      final_result = {}
      each_file do |file_name, source, parser|
        final_result[file_name] = []
        classes = modules = methods = {}
        classes = search_in_collection(parser.classes, options) if options[:class] || options[:all]
        modules = search_in_collection(parser.modules, options) if options[:module] || options[:all]
        methods = search_in_collection(parser.methods, options) if options[:method] || options[:all]
        result = classes.merge(modules.merge(methods))
        result.each do |dec, location|
          context = source.lines.to_a[location.first - 1]
          final_result[file_name] << [dec, location, context]
        end
      end
      return final_result
    end
    
    private
    def search_in_collection(collection, options)
      search_term = options[:search_term]
      search_term = search_term.downcase if options[:ignore_case]
      collection.select do |k,v|
        k = k.downcase if options[:ignore_case]
        if options[:regexp]
          Regexp.new("#{search_term}$").match(k)
        else
          k.end_with?(search_term)
        end
      end
    end
    
    def each_file
      @files.each do |file|
        source = File.read(file)
        parse_tree = Ripper::SexpBuilder.new(source).parse
        parser = Coypond::Parser.new.parse(parse_tree)
        yield(file, source, parser)
      end
    end
    
  end
end

if __FILE__ == $0
  def print_help
    puts "Usage:"
    puts "  coypond search_term [options] file1 [file2 [file3 [...]]]"
    puts ""
    puts "Options:"
    puts "  -m search method names"
    puts "  -c search class names"
    puts "  -M search Module names"
    puts "  -a search all available type names (default: true unless another search option was given)"
  end
  
  if $*.first == "-h" || $*.first == "--help"
    print_help
    exit(0)
  end
  options = {:search_term => $*.shift}
  while $*.first.start_with?("-")
    option = $*.shift
    case option
    when "-r"
      options[:regexp] = true
    when "-i"
      options[:ignore_case] = true
    when "-m"
      options[:method] = true
    when "-c"
      options[:class] = true
    when "-M"
      options[:module] = true
    when "-a"
      options[:all] = true
    end
  end
  
  options[:all] ||= (options.keys & [:class, :method, :module]).empty?
  
  coypond = Coypond::CoypondRunner.new($*)
  results = coypond.search(options)
  
  results.each do |file_name, res|
    unless res.empty?
      puts "#{file_name}:"
      res.each do |dec, location, context|
        puts "  #{location.join(",")}: #{context.strip}"
      end
      puts ""
    end
  end
end