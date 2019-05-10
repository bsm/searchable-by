ENV['RACK_ENV'] ||= 'test'
require 'searchable-by'
require 'rspec'

ActiveRecord::Base.configurations['test'] = { 'adapter' => 'sqlite3', 'database' => ':memory:' }
ActiveRecord::Base.establish_connection :test

ActiveRecord::Base.connection.instance_eval do
  create_table :authors do |t|
    t.string  :name
  end
  create_table :posts do |t|
    t.integer :author_id, null: false
    t.string  :title
    t.text    :body
  end
end

class AbstractModel < ActiveRecord::Base
  self.abstract_class = true

  searchable_by do
    column :id
  end
end

class Author < AbstractModel
  has_many :posts
end

class Post < AbstractModel
  belongs_to :author

  searchable_by do
    column :title
    column { Author.arel_table[:name] }

    scope do
      joins(:author)
    end
  end
end

AUTHORS = {
  alice: Author.create!(name: 'Alice'),
  bob: Author.create!(name: 'Bob'),
}.freeze

POSTS = {
  alice1: AUTHORS[:alice].posts.create!(title: 'titla'),
  alice2: AUTHORS[:alice].posts.create!(title: 'title'),
  bob1: AUTHORS[:bob].posts.create!(title: 'titlo'),
  bob2: AUTHORS[:bob].posts.create!(title: 'titlu'),
}.freeze
