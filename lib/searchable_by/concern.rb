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

    def searchable_by(max_terms: nil, min_length: 0, **options, &block)
      _searchable_by_config.instance_eval(&block)
      _searchable_by_config.max_terms = max_terms if max_terms
      _searchable_by_config.min_length = min_length
      _searchable_by_config.options.update(options) unless options.empty?
      _searchable_by_config
    end

    # @param [String] query the search query
    # @return [ActiveRecord::Relation] the scoped relation
    def search_by(query)
      config  = _searchable_by_config
      columns = config.columns
      return all if columns.empty?

      scope = instance_exec(&config.scoping)

      scope.where(columns.group_by(&:tokenizer).map do |tokenizer, cols|
        values = Util.norm_values(query, min_length: config.min_length, tokenizer: tokenizer).first(config.max_terms)
        next if values.empty?

        cols.each do |col|
          col.node ||= col.attr.is_a?(Proc) ? col.attr.call : arel_table[col.attr]
        end
        Util.build_clauses(cols, values).inject(&:and)
      end.compact.inject(&:or))
    end
  end
end
