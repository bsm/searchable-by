require 'spec_helper'

describe ActiveRecord::SearchableBy do
  context 'norm_values' do
    def norm(str)
      described_class.norm_values(str)
    end

    it 'should tokenise strings' do
      # rubocop:disable Style/StringLiterals
      expect(norm('simple words')).to eq(%w[simple words])
      expect(norm(" with   \t spaces\n")).to eq(%w[with spaces])
      expect(norm('with with duplicates with')).to eq(%w[with duplicates])
      expect(norm('with "full term"')).to match_array(['with', "full term"])
      expect(norm('"""odd double quotes around"""')).to match_array(["odd double quotes around"])
      expect(norm('""even double quotes around""')).to match_array(%w[even double quotes around])
      expect(norm('with -"minus before"')).to match_array(['with', "-minus before"])
      expect(norm('with "-minus within"')).to match_array(['with', "-minus within"])
      expect(norm('with +"plus before"')).to match_array(['with', "+plus before"])
      expect(norm('with "+plus within"')).to match_array(['with', "+plus within"])
      expect(norm('+plus "in other term"')).to match_array(['+plus', "in other term"])
      expect(norm('contains"doublequotes')).to match_array(['contains"doublequotes'])
      # rubocop:enable Style/StringLiterals
    end
  end

  it 'should ignore bad inputs' do
    expect(Post.search_by(nil).count).to eq(5)
    expect(Post.search_by('').count).to eq(5)
  end

  it 'should configure correctly' do
    expect(AbstractModel._searchable_by_config.columns.size).to eq(1)
    expect(Post._searchable_by_config.columns.size).to eq(5)
  end

  it 'should generate SQL' do
    sql = Post.search_by('123').to_sql
    expect(sql).to include(%("posts"."id" = 123))
    expect(sql).to include(%("posts"."title" LIKE '%123%'))

    sql = Post.search_by('foo%bar').to_sql
    expect(sql).not_to include(%("posts"."id"))
    expect(sql).to include(%("posts"."title" LIKE '%foo\\%bar%'))
  end

  it 'should search' do
    expect(Post.search_by('ALICE').pluck(:title)).to match_array(%w[a1 a2 ab])
    expect(Post.search_by('bOb').pluck(:title)).to match_array(%w[b1 b2 ab])
  end

  it 'should search across multiple words' do
    expect(Post.search_by('ALICE your').pluck(:title)).to match_array(%w[a2])
  end

  it 'should support search markers' do
    expect(Post.search_by('aLiCe -your').pluck(:title)).to match_array(%w[a1 ab])
    expect(Post.search_by('+alice "your recipe"').pluck(:title)).to match_array(%w[a2])
    expect(Post.search_by('bob -"her recipe"').pluck(:title)).to match_array(%w[b2 ab])
    expect(Post.search_by('bob +"her recipe"').pluck(:title)).to match_array(%w[b1])
  end

  it 'should search within scopes' do
    expect(Post.where(title: 'a1').search_by('ALICE').pluck(:title)).to match_array(%w[a1])
    expect(Post.where(title: 'a1').search_by('bOb').pluck(:title)).to match_array(%w[])
  end

  it 'should search integers' do
    expect(Post.search_by(POSTS[:ab].id.to_s).count).to eq(1)
  end
end
