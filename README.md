# Searchable By

[![Test](https://github.com/bsm/searchable-by/actions/workflows/test.yml/badge.svg)](https://github.com/bsm/searchable-by/actions/workflows/test.yml)

ActiveRecord plugin to quickly create search scopes.

## Installation

Add `gem 'searchable-by'` to your Gemfile.

## Usage

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Limit the number of terms per query to 3.
  # Ignore search terms shorter than 3 characters (useful for trigram indexes).
  searchable_by max_terms: 3, min_length: 3 do
    # Allow to search strings with custom match type.
    column :title,
      match: :prefix,       # Use btree index-friendly prefix match, e.g. `ILIKE 'term%'` instead of default `ILIKE '%term%'`.
      match_phrase: :exact, # For phrases use exact match type, e.g. searching for `"My Post"` will query `WHERE LOWER(title) = 'my post'`.

    # ... and integers.
    column :id, type: :integer

    # Allow custom arel nodes.
    column { Author.arel_table[:name] }
    column { Arel::Nodes::NamedFunction.new('CONCAT', [arel_table[:prefix], arel_table[:suffix]]) }

    # Allow custom wildcard replacement using a match and non-space tokenizer e.g. searching for `"My* Post"` will query `ILIKE 'my% post'`.
    column :metadata, match: :prefix, match_phrase: :exact, wildcard: '*', tokenizer: :downcase

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
