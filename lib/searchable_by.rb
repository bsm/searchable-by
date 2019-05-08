require 'active_record'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/array/extract_options'

module ActiveRecord
  module SearchableBy
    def self.build_condition(attr, value)
      value  = value.to_s
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
        base._searchable_by_config = []
        super
      end

      def inherited(base) # :nodoc:
        base._searchable_by_config = _searchable_by_config.deep_dup
        super
      end

      def searchable_by(*attrs, &block)
        opts = attrs.extract_options!
        opts[:scope] = block if block

        attrs.each do |attr|
          _searchable_by_config.push opts.merge(attr: attr)
        end
      end

      # @param [String] value the search query
      # @return [ActiveRecord::Relation] the scoped relation
      def search_by(value)
        scope = all
        value = value.to_s
        return scope unless value.present?

        clause = nil
        _searchable_by_config.each do |opts|
          attr   = opts[:attr].is_a?(Proc) ? opts[:attr].call : arel_table[opts[:attr]]
          cond   = SearchableBy.build_condition(attr, value)
          clause = clause ? clause.or(cond) : cond if cond
          scope  = opts[:scope].call(scope) if opts[:scope]
        end

        scope = scope.where(clause) if clause
        scope
      end
    end
  end

  class Base
    extend SearchableBy::ClassMethods
  end
end
