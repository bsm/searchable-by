# Searchable By

ActiveRecord plugin to quickly create search scopes.

## Installation

Add `gem 'searchable-by'` to your Gemfile.

## Usage

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Allow to search strings and ints.
  searchable_by :id, :title

  # Allow custom search scopes.
  searchable_by -> { Author.arel_table[:name] } do |scope|
    scope.joins(:author)
  end
end

Post.search_by(params[:search])  # => ActiveRecord::Relation
```
