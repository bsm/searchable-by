module SearchableBy
  module Util
    def self.norm_values(query, min_length: 0)
      values = []
      query  = query.to_s.dup

      # capture any phrases inside double quotes
      # exclude from search if preceded by '-'
      query.gsub!(/([\-+]?)"+([^"]*)"+/) do |_|
        term = Regexp.last_match(2)
        negate = Regexp.last_match(1) == '-'

        values.push Value.new(term, negate, true) unless term.blank? || term.length < min_length
        ''
      end

      # for the remaining terms remove sign if precedes
      # exclude term from search if sign preceding is '-'
      query.split.each do |term|
        negate = term[0] == '-'
        term.slice!(0) if negate || term[0] == '+'

        values.push Value.new(term, negate, false) unless term.blank? || term.length < min_length
      end

      values.uniq!
      values
    end

    def self.build_clauses(columns, values)
      values.filter_map do |value|
        # TODO: remove when removing min_length option from columns
        usable = columns.all? do |column|
          column.send(:usable?, value)
        end
        next unless usable

        group = columns.filter_map do |column|
          column.build_condition(value)
        end
        next if group.empty?

        clause = group.inject(&:or)
        clause = clause.not if value.negate
        clause
      end
    end
  end
end
