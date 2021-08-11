module SearchableBy
  module Concern
    def self.extended(base) # :nodoc:
      base.class_attribute :_searchable_by_config, instance_accessor: false, instance_predicate: false
      base._searchable_by_config = Hash.new {|h, k| h[k] = Config.new }
      super
    end

    def inherited(base) # :nodoc:
      base._searchable_by_config = _searchable_by_config.deep_dup
      super
    end

    def searchable_by(profile = :default, max_terms: nil, min_length: 0, **options, &block)
      _searchable_by_config[profile.to_sym].configure(max_terms, min_length, **options, &block)
      _searchable_by_config
    end

    # @param [String] query the search query
    # @return [ActiveRecord::Relation] the scoped relation
    def search_by(query, profile: :default)
      config  = _searchable_by_config[profile.to_sym]
      columns = config.columns
      return all if columns.empty?

      values = Util.norm_values(query, min_length: config.min_length).first(config.max_terms)
      return all if values.empty?

      columns.each do |col|
        col.node ||= col.attr.is_a?(Proc) ? col.attr.call : arel_table[col.attr]
      end
      clauses = Util.build_clauses(columns, values)
      return all if clauses.empty?

      scope = instance_exec(&config.scoping)
      clauses.each do |clause|
        scope = scope.where(clause)
      end
      scope
    end
  end
end
