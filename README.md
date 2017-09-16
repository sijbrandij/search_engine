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

Go to the document root in your terminal and type `ruby search_engine.rb` to start a new search.

## Contributing
To add a new record type to the search engine (f.e. events), follow these steps:
1. create a json file `events.json` and add it to the document root
2. add the file_type to `FILE_TYPES` at the top of `search_engine.rb`
3. if your new record type has any fields that contain an array as values, add the field to the `has_array_value?` method to ensure proper search and display
4. if there are any integer fields in your records, make sure to name the field appropriately: anything that ends with `_id` will be converted to Integer, except for `external_id`
