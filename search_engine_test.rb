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
end
