#!/usr/bin/env ruby

class SearchEngine
  require 'json'
  
  attr_accessor :type, :term, :value, :results
  
  FILE_TYPES = %w(users tickets organizations)

  def initialize(test=false)
    @type = nil
    @term = nil
    @value = nil
    @results = []
    @test = test
  end
  
  def run
    instructions
    return unless step1
    return unless set_type
    return unless set_term
    return unless set_value
    search
  end

  def instructions
    result = [
      "Welcome to Zendesk search.\nType 'quit' to exit at any time, Press 'Enter' to continue\n\n",
      "\tSelect search options:",
      "\t* Press 1 to search Zendesk",
      "\t* Press 2 to see a list of searchable fields",
      "\t* Type 'quit' to exit\n",
    ]
    stdout_or_return(result)
  end
  
  def step1(command=nil)
    command ||= get_user_input
    return false if command == 'quit'
    if %w(1 2).include?(command)
      if command == '2'
        stdout_or_return(list_search_terms)
      end
      true
    else
      signal_invalid_input
    end
  end
  
  def set_type(command=nil)
    stdout_or_return(type_prompt)
    command ||= get_user_input
    return false if command == 'quit'
    type_index = command
    if [1,2,3].include?(type_index.to_i) # non-numerical inputs will be converted to 0
      @type = FILE_TYPES[type_index.to_i-1]
      true
    else
      signal_invalid_input
    end
  end
  
  def set_term(command=nil)
    prompt = [
      "You can search #{@type} for the following search terms: #{valid_search_terms(@type).join(", ")}.\n",
      "Enter search term"
    ]
    stdout_or_return(prompt)
    command ||= get_user_input
    return false if command == 'quit'
    if valid_search_terms(@type).include?(command)
      @term = command
      true
    else
      signal_invalid_input
    end
  end
  
  def set_value(command=nil)
    stdout_or_return(["Enter search value"])
    command ||= get_user_input
    return false if command == 'quit'
    @value = command
    true
  end

  def list_search_terms(output=nil, type=nil)
    output ||= []
    if type
      output.push("Search #{type.capitalize} with")
      output.push(valid_search_terms(type).join("\n"))
      output.push("\n")
    else
      FILE_TYPES.each do |type|
        list_search_terms(output, type)
      end
    end
    output
  end

  def search
    print_search
    data_hash = get_json(@type)
    @value = convert_value
    if @value == ""
      results = search_empty_values(data_hash)
    elsif has_array_value?(@term)
      results = data_hash.select{ |el| el[@term].include?(@value) }
    else 
      results = data_hash.select{|el| el[@term] == @value }
    end
    @results = results
    printout
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

  def print_search
    stdout_or_return(["Searching #{@type} for #{@term} with a value of #{@value}"])
  end
  
  private
  
  def get_user_input
    $stdin.gets.chomp
  end
  
  def stdout_or_return(array)
    if @test
      return array
    else
      array.each do |string|
        puts string
      end
    end
  end
  
  def signal_invalid_input
    stdout_or_return(["Invalid input"])
    false
  end
  
  def get_json(type)
    file = File.read("#{type}.json")
    JSON.parse(file)
  end
  
  def search_empty_values(data)
    if has_array_value?(@term)
      data.select{ |el| el[@term].empty? }
    else
      data.select{|el| el[@term].to_s.empty? }
    end
  end
  
  def valid_search_terms(type)
    data_hash = get_json(type)
    search_terms = data_hash.first.keys
  end
  
  def type_prompt
    output = []
    types = []
    FILE_TYPES.each_with_index do |file_type, i|
      types << "#{i+1}) #{file_type.capitalize}"
    end
    output.push("Select " + types.join(", "))
  end
  
  # Formatting methods
  
  def printout
    output = []
    if @results.any?
      @results.each do |result|
        output.push(format_result(result))
      end
      output.push("#{@results.count} record#{ @results.one? ? "" : "s"} found.")
    else
      output.push("No records found.")
    end
    stdout_or_return(output.flatten.compact)
  end
  
  def format_result(result)
    result_output = []
    result.each do |key, value|
      result_output.push(format_output(key, value))
    end
    if @type == 'users'
      result_output = result_output + find_associated_records(result)
    end
    result_output.push("\n")
    result_output
  end
  
  def format_output(key, value)
    if has_array_value?(key)
      format_string(key, value.join(", "))
    elsif %w(submitter_id assignee_id).include?(key) && value
      get_user(key, value)
    elsif key == 'organization_id'
      get_organization(value)
    else
      format_string(key, value)
    end
  end
  
  def find_associated_records(result)
    output = []
    data = get_json('tickets')
    submitted_tickets, assigned_tickets = find_submitted_and_assigned_tickets(result['_id'], data)
    
    submitted_tickets.each_with_index do |ticket, i|
      output.push(format_ticket(ticket['subject'], i, 'submitted'))
    end
    assigned_tickets.each_with_index do |ticket, i|
      output.push(format_ticket(ticket['subject'], i, 'assigned'))
    end
    output
  end
  
  def find_submitted_and_assigned_tickets(id, data)
    submitted_tickets = data.select{ |ticket| ticket['submitter_id'] == id }
    assigned_tickets = data.select{ |ticket| ticket['assignee_id'] == id }
    return submitted_tickets, assigned_tickets
  end
  
  def format_ticket(subject, index, modifier)
    format_string("#{modifier} ticket#{index}", subject)
  end
  
  def format_string(key, value)
    sprintf("%-20s %s \n", key, value)
  end
  
  def has_array_value?(key)
    # include any attribute with an array value in this list for proper searching and formatting
    %w(tags domain_names).include?(key)
  end

  def get_user(key, id)
    data = get_json('users')
    user = data.select{|user| user["_id"] == id }.first
    if user
      format_string(key.chomp("_id"), user['name'])
    end
  end

  def get_organization(id)
    data = get_json('organizations')
    organization = data.select{|org| org['_id'] == id }.first
    format_string('organization', organization['name'])
  end
  
  # End formatting methods
end

search_engine = SearchEngine.new
if ARGV[0] == 'run'
  search_engine.run
end