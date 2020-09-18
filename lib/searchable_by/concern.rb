module SearchableBy
  module Concern
    def self.extended(base) # :nodoc:
      base.class_attribute :_searchable_by_config, instance_accessor: false, instance_predicate: false
      base._searchable_by_config = Config.new
      super
    end

    def inherited(base) # :nodoc:
      base._searchable_by_config = _searchable_by_config.dup
      super
    end

    def searchable_by(max_terms: nil, **options, &block)
      _searchable_by_config.instance_eval(&block)
      _searchable_by_config.max_terms = max_terms if max_terms
      _searchable_by_config.options.update(options) unless options.empty?
      _searchable_by_config
    end

    # @param [String] query the search query
    # @return [ActiveRecord::Relation] the scoped relation
    def search_by(query)
      columns = _searchable_by_config.columns
      return all if columns.empty?

      values = Util.norm_values(query).first(_searchable_by_config.max_terms)
      return all if values.empty?

      columns.each do |col|
        col.node ||= col.attr.is_a?(Proc) ? col.attr.call : arel_table[col.attr]
      end
      clauses = Util.build_clauses(columns, values)
      return all if clauses.empty?

      scope = instance_exec(&_searchable_by_config.scoping)
      clauses.each do |clause|
        scope = scope.where(clause)
      end
      scope
    end
  end
end
