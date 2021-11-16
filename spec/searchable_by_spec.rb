require 'spec_helper'

describe SearchableBy do
  it 'ignores bad inputs' do
    expect(Post.search_by(nil).count).to eq(5)
    expect(Post.search_by('').count).to eq(5)
  end

  it 'configures correctly' do
    expect(AbstractModel._searchable_by_profiles[:default].columns.size).to eq(1)
    expect(Post._searchable_by_profiles[:default].columns.size).to eq(6)
    expect(User._searchable_by_profiles[:default].min_length).to eq(3)
  end

  it 'generates SQL' do
    sql = Post.search_by('123').to_sql
    expect(sql).to include(%("posts"."id" IS NOT NULL AND "posts"."id" = 123))
    expect(sql).to include(%("posts"."title" IS NOT NULL AND "posts"."title" LIKE '123%'))
    expect(sql).to include(%("posts"."body" IS NOT NULL AND "posts"."body" LIKE '%123%'))
    expect(sql).to include(%("users"."name" IS NOT NULL AND LOWER("users"."name") = '123'))

    sql = Post.search_by('foo%bar').to_sql
    expect(sql).not_to include(%("posts"."id"))
    expect(sql).to include(%("posts"."title" LIKE 'foo\\%bar%'))
    expect(sql).to include(%("posts"."body" LIKE '%foo\\%bar%'))

    sql = User.search_by('uni*dom').to_sql
    expect(sql).to include(%("users"."country" LIKE 'uni%dom'))
    expect(sql).to include(%("users"."bio" LIKE '%uni*dom%'))

    sql = User.search_by('"uni * dom"').to_sql
    expect(sql).to include(%("users"."country" LIKE 'uni % dom'))
    expect(sql).to include(%("users"."bio" LIKE '%uni * dom%'))
  end

  it 'searches' do
    expect(Post.search_by('ALICE').pluck(:title)).to match_array(%w[ax1 ax2 ab1])
    expect(Post.search_by('bOb').pluck(:title)).to match_array(%w[bx1 bx2 ab1])
  end

  it 'searches across multiple words' do
    expect(Post.search_by('ALICE your').pluck(:title)).to match_array(%w[ax2])
  end

  it 'supports search markers' do
    expect(Post.search_by('aLiCe -your').pluck(:title)).to match_array(%w[ax1 ab1])
    expect(Post.search_by('+alice "your recipe"').pluck(:title)).to match_array(%w[ax2])
    expect(Post.search_by('bob -"her recipe"').pluck(:title)).to match_array(%w[bx2 ab1])
    expect(Post.search_by('bob +"her recipe"').pluck(:title)).to match_array(%w[bx1])
  end

  it 'respects match options' do
    # name uses match: :exact
    expect(Post.search_by('alice').pluck(:title)).to match_array(%w[ax1 ax2 ab1])
    expect(Post.search_by('ali').pluck(:title)).to be_empty
    expect(Post.search_by('lice').pluck(:title)).to be_empty
    expect(Post.search_by('li').pluck(:title)).to be_empty

    # title uses match: :prefix
    expect(Post.search_by('ax').pluck(:title)).to match_array(%w[ax1 ax2])
    expect(Post.search_by('bx').pluck(:title)).to match_array(%w[bx1 bx2])
    expect(Post.search_by('ab').pluck(:title)).to match_array(%w[ab1])
    expect(Post.search_by('ba').pluck(:title)).to be_empty

    # title uses match_phrase: :exact
    expect(Post.search_by('"ab"').pluck(:title)).to be_empty
    expect(Post.search_by('"ab1"').pluck(:title)).to match_array(%w[ab1])

    # country uses match: :full in combination with wildcard: '*'
    expect(Post.search_by('*kingdom').pluck(:title)).to match_array(%w[ax1 ax2 ab1])

    # body uses match: :all (default)
    expect(Post.search_by('recip').pluck(:title)).to match_array(%w[ax1 ax2 bx1 bx2 ab1])
  end

  it 'supports min term length in context' do
    # values are discarded - too short for bio
    expect(User.search_by('+be')).to match_array(USERS.values_at(:a, :b))
    expect(User.search_by('is')).to match_array(USERS.values_at(:a, :b))

    # value is used to scope
    expect(User.search_by('ear')).to match_array(USERS.values_at(:a))

    # one used, one discarded
    expect(User.search_by('beard is')).to match_array(USERS.values_at(:a))
  end

  it 'searches within scopes' do
    expect(Post.where(title: 'ax1').search_by('ALICE').pluck(:title)).to match_array(%w[ax1])
    expect(Post.where(title: 'ax1').search_by('bOb').pluck(:title)).to be_empty
  end

  it 'searches integers' do
    expect(Post.search_by(POSTS[:ab1].id.to_s).count).to eq(1)
  end

  it 'supports wildcards' do
    expect(User.search_by('*uni*dom')).to match_array(USERS.values_at(:a))
    expect(User.search_by('*uni*o*')).to match_array(USERS.values_at(:a, :b))
    expect(User.search_by('*uni*of*dom')).to be_empty
  end

  it 'supports profiles' do
    expect(User.search_by('king', profile: :country_only)).to match_array(USERS.values_at(:a))
    expect(User.search_by('Norris', profile: :country_only)).to be_empty
  end
end
