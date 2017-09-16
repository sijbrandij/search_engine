class SearchEngine
  require 'json'
  
  attr_accessor :type, :term, :value, :results
  
  FILE_TYPES = %w(users tickets organizations)

  def initialize
    @type = nil
    @term = nil
    @value = nil
    @results = []
    
    instructions
    step1
  end

  def instructions
    puts "Welcome to Zendesk search.\nType 'quit' to exit at any time, Press 'Enter' to continue\n\n"
    puts "\tSelect search options:"
    puts "\t* Press 1 to search Zendesk"
    puts "\t* Press 2 to see a list of searchable fields"
    puts "\t* Type 'quit' to exit"
    puts "\n"
  end
  
  def check_for_quit(command)
    
  end
  
  def step1
    command = gets.chomp
    return if command == 'quit'
    if %w(1 2).include?(command)
      if command == '2'
        print_search_terms
      end
      step2
    else
      puts "Invalid input"
    end
  end
  
  def step2
    construct_prompt
    puts "Select 1) Users 2) Tickets or 3) Organizations"
    type_index = gets.chomp
    return if type_index == 'quit'
    if [1,2,3].include?(type_index.to_i) # non-numerical inputs will be converted to 0
      @type = FILE_TYPES[type_index.to_i-1]
      step3
    else
      puts "Invalid input"
      step2
    end
  end
  
  def step3
    puts "You can search #{@type} for the following search terms: #{valid_search_terms(@type).join(", ")}.\n"
    puts "Enter search term"
    @term = gets.chomp
    return if @term == 'quit'
    if valid_search_terms(@type).include?(@term)
      step4
    else
      puts "Invalid input"
      step3
    end
  end
  
  def step4
    puts "Enter search value"
    @value = gets.chomp
    return if @value == 'quit'
    print_search
    @results = search
    printout
  end
  
  def construct_prompt
    string = "Select "
    types = []
    FILE_TYPES.each_with_index do |file_type, i|
      types << "#{i+1}) #{file_type.capitalize}"
    end
    string << types.join(", ")
  end

  def valid_search_terms(type)
    data_hash = get_json(type)
    search_terms = data_hash.first.keys
  end

  def print_search_terms(type=nil)
    if type
      puts "-" * 40
      puts "Search #{type.capitalize} with"
      puts valid_search_terms(type).join("\n")
      puts "\n"
    else
      FILE_TYPES.each do |type|
        print_search_terms(type)
      end
    end
  end

  def search
    data_hash = get_json(@type)
    @value = convert_value
    if @value == ""
      results = search_empty_values(data_hash)
    elsif has_array_value?(@term)
      results = data_hash.select{ |el| el[@term].include?(@value) }
    else 
      results = data_hash.select{|el| el[@term] == @value }
    end
  end
  
  def search_empty_values(data)
    if has_array_value?(@term)
      data.select{ |el| el[@term].empty? }
    else
      data.select{|el| el[@term].to_s.empty? }
    end
  end

  def convert_value
    if %w(true false).include?(@value)
      # convert boolean strings to true booleans
      @value == 'true'
    elsif @term.end_with?("_id") && @term != 'external_id'
      # convert ids to integers
      @value.to_i
    else
      # return without alteration
      @value
    end
  end

  def get_json(type)
    file = File.read("#{type}.json")
    JSON.parse(file)
  end

  def printout
    if @results.any?
      @results.each do |result|
        print_result(result)
      end
      puts "#{@results.count} record#{ @results.one? ? "" : "s"} found."
    else
      puts "No records found."
    end
  end

  def print_result(result)
    result.each do |key, value|
      puts format_output(key, value)
    end
    puts "\n"
  end

  def print_search
    puts "Searching #{@type} for #{@term} with a value of #{@value}"
  end
  
  def format_output(key, value)
    if has_array_value?(key)
      printf "%-20s %s", key, value.join(", ")
    else
      printf "%-20s %s", key, value
    end
  end
  
  def has_array_value?(key)
    # include any attribute with an array value in this list for proper searching and formatting
    %w(tags domain_names).include?(key)
  end
end

SearchEngine.new