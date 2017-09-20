# README

## Description
This is an implementation of a search engine. The application loads its data from 3 `json` files containing different resources. The user interacts with the search engine through the terminal. 

## System requirements
* Ruby
* JSON

To test whether you have JSON, follow these steps in a console:
```
require 'json'
 => true
```
If this returns `false`, run `gem install json` in your terminal.
## Instructions for use

Start a new search: `ruby search_engine.rb run`
Run the tests: `ruby search_engine_test.rb`

## Contributing
To add a new record type to the search engine (f.e. events), follow these steps:
1. create a json file `events.json` and add it to the document root
2. add the file_type to `FILE_TYPES` at the top of `search_engine.rb`
3. if your new record type has any fields that contain an array as values, add the field to the `has_array_value?` method to ensure proper search and display
4. if there are any id fields in your records, make sure to name the field appropriately: anything that ends with `_id` will be converted to Integer, except for `external_id`
5. if there are any other integer fields, modify the `convert_value` method accordingly

## Considerations
* To ensure the correct flow through the steps, I chose to let each step return `true` or `false`, and `return` as soon as a method returns `false`.
* In order to make testing possible, I created the `stdout_or_return` method, which checks the `@test` variable. This prevents the stdout output from cluttering the test results.
* In order to not run `SearchEngine.new` when testing, I chose to use a `ARGV` argument when running the search engine in the console. This way, I can instantiate the search engine in the test without it waiting for input from the user
* I chose to replace the ids associated with the `submitter_id`, `assignee_id` and `organization_id` keys with the name of the associated record. This way the user isn't bothered with ids that are not actionable.
* I used the gem `flog` to calculate code complexity. I have kept all methods under the (arbitrary) limit of 20: http://jakescruggs.blogspot.com/2008/08/whats-good-flog-score.html


## Improvements
* When one of the steps returns `false`, go back to the previous step. This way, the user stays in the search until they type `'quit'`.