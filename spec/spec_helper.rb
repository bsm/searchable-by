ENV['RACK_ENV'] ||= 'test'
require 'searchable-by'
require 'rspec'

ActiveRecord::Base.configurations['test'] = { 'adapter' => 'sqlite3', 'database' => ':memory:' }
ActiveRecord::Base.establish_connection :test

ActiveRecord::Base.connection.instance_eval do
  create_table :users do |t|
    t.string  :name
  end
  create_table :posts do |t|
    t.integer :author_id, null: false
    t.integer :reviewer_id
    t.string  :title
    t.text    :body
  end
end

class AbstractModel < ActiveRecord::Base
  self.abstract_class = true

  searchable_by do
    column :id, type: :integer
  end
end

class User < AbstractModel
  has_many :posts, foreign_key: :author_id
end

class Post < AbstractModel
  belongs_to :author, class_name: 'User'
  belongs_to :reviewer, class_name: 'User'

  searchable_by do
    column :title, :body
    column { User.arel_table[:name] }
    column { User.arel_table.alias('reviewers_posts')[:name] }

    scope do
      joins(:author).left_outer_joins(:reviewer)
    end
  end
end

USERS = {
  a: User.create!(name: 'Alice'),
  b: User.create!(name: 'Bob'),
}.freeze

POSTS = {
  a1: USERS[:a].posts.create!(title: 'a1', body: 'my recipe '),
  a2: USERS[:a].posts.create!(title: 'a2', body: 'your recipe'),
  b1: USERS[:b].posts.create!(title: 'b1', body: 'her recipe'),
  b2: USERS[:b].posts.create!(title: 'b2', body: 'our recipe'),
  ab: USERS[:a].posts.create!(title: 'ab', reviewer: USERS[:b], body: 'their recipe'),
}.freeze
