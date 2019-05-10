require 'active_record'
require 'shellwords'

module ActiveRecord
  module SearchableBy
    class Config < Hash
      def initialize
        update columns: [], max_terms: 5
        scope { all }
      end

      def column(*attrs, &block)
        opts = attrs.extract_options!
        cols = self[:columns]
        attrs.each do |attr|
          cols.push(opts.merge(column: attr))
        end
        cols.push(opts.merge(column: block)) if block
        cols
      end

      def scope(&block)
        self[:scope] = block
      end
    end

    def self.norm_values(query)
      values = Shellwords.split(query.to_s)
      values.flatten!
      values.reject!(&:blank?)
      values.uniq!
      values
    end

    def self.build_clauses(relations, values)
      clauses = values.map do |value|
        negate = value[0] == '-'
        value.slice!(0) if negate || value[0] == '+'

        c0, *cn = relations.map do |opts|
          build_condition(opts, value)
        end.compact
        next unless c0

        [cn.inject(c0) {|x, part| x.or(part) }, negate]
      end
      clauses.compact!
      clauses
    end

    def self.build_condition(opts, value)
      case opts[:type]
      when :int, :integer
        begin
          opts[:rel].eq(Integer(value))
        rescue ArgumentError
          nil
        end
      else
        value = value.dup
        value.gsub!('%', '\%')
        value.gsub!('_', '\_')
        opts[:rel].matches("%#{value}%")
      end
    end

    module ClassMethods
      def self.extended(base) # :nodoc:
        base.class_attribute :_searchable_by_config, instance_accessor: false, instance_predicate: false
        base._searchable_by_config = Config.new
        super
      end

      def inherited(base) # :nodoc:
        base._searchable_by_config = _searchable_by_config.deep_dup
        super
      end

      def searchable_by(max_terms: 5, &block)
        _searchable_by_config.instance_eval(&block)
        _searchable_by_config[:max_terms] = max_terms if max_terms
      end

      # @param [String] query the search query
      # @return [ActiveRecord::Relation] the scoped relation
      def search_by(query)
        columns = _searchable_by_config[:columns]
        return all if columns.empty?

        values = SearchableBy.norm_values(query).first(_searchable_by_config[:max_terms])
        return all if values.empty?

        relations = columns.map do |opts|
          rel = opts[:column].is_a?(Proc) ? opts[:column].call : arel_table[opts[:column]]
          opts.merge(rel: rel)
        end
        clauses = SearchableBy.build_clauses(relations, values)
        return all if clauses.empty?

        scope = instance_exec(&_searchable_by_config[:scope])
        clauses.inject(scope) do |x, (clause, negate)|
          negate ? x.where.not(clause) : x.where(clause)
        end
      end
    end
  end

  class Base
    extend SearchableBy::ClassMethods
  end
end
