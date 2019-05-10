# Searchable By

ActiveRecord plugin to quickly create search scopes.

## Installation

Add `gem 'searchable-by'` to your Gemfile.

## Usage

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Limit the number of terms per query to 3.
  searchable_by max_terms: 3 do
    # Allow to search strings.
    column :title

    # ... and integers.
    column :id, type: :integer

    # Allow custom arel nodes.
    column { Author.arel_table[:name] }
    column { Arel::Nodes::NamedFunction.new('CONCAT', [arel_table[:prefix], arel_table[:suffix]]) }

    # Support custom scopes.
    scope do
      joins(:author)
    end
  end
end

# Search for 'alice'
Post.search_by('alice') # => ActiveRecord::Relation

# Search for 'alice' AND 'pie recipe'
Post.search_by('alice "pie recipe"')

# Search for 'alice' but NOT for 'pie recipe'
Post.search_by('alice -"pie recipe"')
```
