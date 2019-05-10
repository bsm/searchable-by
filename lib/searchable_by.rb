require 'active_record'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/array/extract_options'

module ActiveRecord
  module SearchableBy
    class Config < Hash
      def initialize
        update columns: [], max_terms: 5
        scope { all }
      end

      def column(*attrs, &block)
        self[:columns].push(*attrs)
        self[:columns].push(block) if block
      end

      def scope(&block)
        self[:scope] = block
      end
    end

    def self.norm_values(query)
      values = Array.wrap(query)
      values.map! {|x| x.to_s.split(/[[:cntrl:]\s]+/) }
      values.flatten!
      values.reject!(&:blank?)
      values.uniq!
      values
    end

    def self.build_clauses(attributes, values)
      clauses = values.map do |value|
        c0, *cn = attributes.map do |attr|
          build_condition(attr, value)
        end.compact
        cn.inject(c0) {|x, part| x.or(part) } if c0
      end
      clauses.compact!
      clauses
    end

    def self.build_condition(attr, value)
      casted = value
      casted = attr.type_cast_for_database(casted) if attr.able_to_type_cast?
      case casted
      when String
        casted.gsub!('%', '\%')
        casted.gsub!('_', '\_')
        casted.downcase!
        attr.lower.matches("%#{casted}%")
      when Integer
        attr.eq(casted) unless casted.zero? && value != '0'
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
        attributes = _searchable_by_config[:columns].map do |col|
          col.is_a?(Proc) ? col.call : arel_table[col]
        end
        return all if attributes.empty?

        values = SearchableBy.norm_values(query).first(_searchable_by_config[:max_terms])
        return all if values.empty?

        clauses = SearchableBy.build_clauses(attributes, values)
        return all if clauses.empty?

        scope = instance_exec(&_searchable_by_config[:scope])
        clauses.inject(scope) do |x, clause|
          x.where(clause)
        end
      end
    end
  end

  class Base
    extend SearchableBy::ClassMethods
  end
end
