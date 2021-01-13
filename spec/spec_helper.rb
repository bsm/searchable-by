ENV['RACK_ENV'] ||= 'test'
require 'searchable-by'
require 'rspec'

ActiveRecord::Base.configurations = { 'test' => { 'adapter' => 'sqlite3', 'database' => ':memory:' } }
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
    column :title, match: :prefix, match_phrase: :exact
    column :body
    column proc { User.arel_table[:name] }, match: :exact
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
  ax1: USERS[:a].posts.create!(title: 'ax1', body: 'my recipe '),
  ax2: USERS[:a].posts.create!(title: 'ax2', body: 'your recipe'),
  bx1: USERS[:b].posts.create!(title: 'bx1', body: 'her recipe'),
  bx2: USERS[:b].posts.create!(title: 'bx2', body: 'our recipe'),
  ab1: USERS[:a].posts.create!(title: 'ab1', reviewer: USERS[:b], body: 'their recipe'),
}.freeze
