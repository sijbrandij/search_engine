require 'minitest/spec'
require 'minitest/autorun'
require_relative 'search_engine'

describe SearchEngine do
  def setup
    @search = SearchEngine.new(true)
  end
  
  describe 'instructions' do
    it 'returns instructions' do
      response = @search.instructions
      assert_equal 5, response.size
      assert response.join(" ").include?("searchable fields")
    end
  end
  
  describe 'step1' do
    it 'returns false for invalid input' do
      refute @search.step1('some unimplemented step')
    end
    
    it 'returns false for input quit' do
      refute @search.step1('quit')
    end
    
    it 'returns true for input 1' do
      assert @search.step1('1')
    end
    
    it 'returns true for input 2' do
      assert @search.step1('2')
    end
  end
  
  describe 'set_type' do
    it 'returns false for invalid input' do
      refute @search.set_type('some input')
    end
    
    it 'returns false for input quit' do
      refute @search.set_type('quit')
    end
    
    it 'returns true for input 1 and sets type' do
      assert @search.set_type('1')
      assert_equal 'users', @search.type
    end
    
    it 'returns true for input 2 and sets type' do
      assert @search.set_type('2')
      assert_equal 'tickets', @search.type
    end
    
    it 'returns true for input 3 and sets type' do
      assert @search.set_type('3')
      assert_equal 'organizations', @search.type
    end
  end
  
  describe 'set_term' do
    it 'returns false for invalid input' do
      @search.type = 'users'
      refute @search.set_term('not-a-search-field')
    end
    
    it 'returns false for input quit' do
      @search.type = 'users'
      refute @search.set_term('quit')
    end
    
    it 'returns true for valid field and sets term' do
      @search.type = 'users'
      assert @search.set_term('_id')
      assert_equal '_id', @search.term
    end
  end
  
  describe 'set_value' do
    it 'returns false for input quit' do
      @search.type = 'users'
      @search.term = '_id'
      refute @search.set_value('quit')
    end
    
    it 'finds records' do
      @search.type = 'users'
      @search.term = '_id'
      @search.set_value('1')
      assert_equal '1', @search.value
    end
  end
  
  describe 'search' do
    it 'sets records' do
      @search.type = 'users'
      @search.term = '_id'
      @search.value = '1'
      @search.search
      assert @search.results.any?
      assert_equal 1, @search.results.size
    end
    
    it 'converts values' do
      @search.type = 'users'
      @search.term = '_id'
      @search.value = '1'
      @search.search
      assert_equal 1, @search.value
    end
    
    it 'finds records with empty fields' do
      @search.type = 'organizations'
      @search.term = 'description'
      @search.value = ''
      @search.search
      assert_equal 26, @search.results.size
    end
  end
  
  describe 'convert_value' do
    it 'converts to integer when term is _id' do
      @search.term = '_id'
      @search.value = '1'
      assert_equal 1, @search.convert_value
    end
    
    it 'does not convert external_id' do
      @search.term = 'external_id'
      @search.value = '1234some_id'
      assert_equal '1234some_id', @search.convert_value
    end
    
    it 'converts boolean values' do
      @search.term = 'suspended'
      @search.value = 'true'
      assert_equal true, @search.convert_value
    end
    
    it 'does not convert regular string' do
      @search.term = 'description'
      @search.value = 'some description'
      assert_equal 'some description', @search.convert_value
    end
  end
  
  describe 'print_search' do
    it 'returns search parameters' do
      @search.type = 'users'
      @search.term = 'alias'
      @search.value = 'The incredible'
      assert_equal ["Searching users for alias with a value of The incredible"], @search.print_search
    end
  end
  
  describe 'signal_invalid_input' do
    it 'returns false' do
      refute @search.signal_invalid_input
    end
  end
  
  describe 'get_json' do
    it 'returns data hash if file exists' do
      assert @search.get_json('users')
    end
    
    it 'returns nil for non-existent file' do
      assert_nil @search.get_json('non-existent.json')
    end
  end
  
  describe 'search_empty_values' do
    it 'searches empty values for terms that have array vales' do
      @search.term = 'domain_names'
      data = JSON.parse(File.read('organizations.json'))
      assert_equal [], @search.search_empty_values(data)
    end
    
    it 'searches empty values for terms that have non-array value' do
      @search.term = 'description'
      data = JSON.parse(File.read('organizations.json'))
      assert_equal 26, @search.search_empty_values(data).count
    end
  end
  
  describe 'valid_search_terms' do
    it 'returns an array of search terms' do
      assert_equal 16, @search.valid_search_terms('tickets').count
    end
  end
  
  describe 'type_prompt' do
    it 'returns an array' do
      assert_equal Array, @search.type_prompt.class
    end
  end
  
  describe 'printout' do
    it 'returns "no records found" if there are no results' do
      assert_equal ["No records found."], @search.printout
    end
    
    it 'returns a array containing results' do
      @search.type = 'organizations'
      @search.term = '_id'
      @search.value = 101
      @search.search
      assert_equal 11, @search.printout.count
    end
    
    it 'includes a line with total results found' do
      @search.type = 'organizations'
      @search.term = '_id'
      @search.value = 101
      @search.search
      assert_equal "1 record found.", @search.printout.last 
    end
  end
  
  describe 'format_result' do
    it 'formats result' do
      @search.type = 'tickets'
      result = {
        "_id": "436bf9b0-1147-4c0a-8439-6f79833bff5b",
        "url": "http://initech.zendesk.com/api/v2/tickets/436bf9b0-1147-4c0a-8439-6f79833bff5b.json",
        "external_id": "9210cdc9-4bee-485f-a078-35396cd74063",
        "created_at": "2016-04-28T11:19:34 -10:00",
        "type": "incident",
        "subject": "A Catastrophe in Korea (North)",
        "description": "Nostrud ad sit velit cupidatat laboris ipsum nisi amet laboris ex exercitation amet et proident. Ipsum fugiat aute dolore tempor nostrud velit ipsum.",
        "priority": "high",
        "status": "pending",
        "submitter_id": 38,
        "assignee_id": 24,
        "organization_id": 116,
        "tags": [
          "Ohio",
          "Pennsylvania",
          "American Samoa",
          "Northern Mariana Islands"
        ],
        "has_incidents": false,
        "due_at": "2016-07-31T02:37:50 -10:00",
        "via": "web"
      }
      output = @search.format_result(result)
      assert_equal result.keys.size+1, output.length
      assert_equal Array, output.class
    end
    
    it 'adds lines for tickets to users' do
      @search.type = 'users'
      result = {
        "_id": 1,
        "url": "http://initech.zendesk.com/api/v2/users/1.json",
        "external_id": "74341f74-9c79-49d5-9611-87ef9b6eb75f",
        "name": "Francisca Rasmussen",
        "alias": "Miss Coffey",
        "created_at": "2016-04-15T05:19:46 -10:00",
        "active": true,
        "verified": true,
        "shared": false,
        "locale": "en-AU",
        "timezone": "Sri Lanka",
        "last_login_at": "2013-08-04T01:03:27 -10:00",
        "email": "coffeyrasmussen@flotonic.com",
        "phone": "8335-422-718",
        "signature": "Don't Worry Be Happy!",
        "organization_id": 119,
        "tags": [
          "Springville",
          "Sutton",
          "Hartsville/Hartley",
          "Diaperville"
        ],
        "suspended": true,
        "role": "admin"
      }
      output = @search.format_result(result)
      assert_equal result.keys.length+5, output.length
      assert_equal [true], output[19..-2].map{|el| el.include?('ticket')}.uniq
    end
  end
  
  describe 'format_output' do
    it 'returns array as joined string' do
      assert_equal "tags                 Ohio, Montana", @search.format_output('tags', ['Ohio', 'Montana']).chomp
    end
    
    it 'returns user name instead of id' do
      assert_equal "submitter            Francisca Rasmussen", @search.format_output('submitter_id', 1).chomp
    end
    
    it 'returns organization name instead of organization id' do
      assert_equal "organization         Enthaze", @search.format_output('organization_id', 101).chomp
    end
  end
  
  describe 'find_submitted_and_assigned_records' do
    it 'returns two variables with records' do
      submitted, assigned = @search.find_submitted_and_assigned_tickets(1)
      assert_equal 2, submitted.count
      assert_equal 2, assigned.count
    end
  end
  
  describe 'format_ticket' do
    it 'returns formatted string' do
      assert_equal "assigned ticket0     Some ticket", @search.format_ticket('Some ticket', 0, 'assigned').chomp
    end
  end
  
  describe 'format_string' do
    it 'returns formatted string' do
      assert_equal "some key             some value", @search.format_string('some key', 'some value').chomp
    end
  end
  
  describe 'has_array_value?' do
    it 'returns true for terms with array values' do
      assert @search.has_array_value?('tags')
    end
    
    it 'returns false for terms that do not have array values' do
      refute @search.has_array_value?('_id')
    end
  end
  
  describe 'get_user' do
    it 'returns formatted user' do
      assert_equal "submitter            Francisca Rasmussen", @search.get_user('submitter_id', 1).chomp
    end
  end
  
  describe 'get_organization' do
    it 'returns formatted organization' do
      assert_equal "organization         Enthaze", @search.get_organization(101).chomp
    end
  end
end
