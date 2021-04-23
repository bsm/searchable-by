module SearchableBy
  module Util
    def self.norm_values(query)
      values = []
      query  = query.to_s.dup

      # wildcard searching
      # add full query without splitting by terms
      values.push Value.new(query, false, false) if query.include? '*'

      # capture any phrases inside double quotes
      # exclude from search if preceded by '-'
      query.gsub!(/([\-+]?)"+([^"]*)"+/) do |_|
        term = Regexp.last_match(2)
        negate = Regexp.last_match(1) == '-'

        values.push Value.new(term, negate, true) unless term.blank?
        ''
      end

      # for the remaining terms remove sign if precedes
      # exclude term from search if sign preceding is '-'
      query.split.each do |term|
        negate = term[0] == '-'
        term.slice!(0) if negate || term[0] == '+'

        values.push Value.new(term, negate, false) unless term.blank?
      end

      values.uniq!
      values
    end

    def self.build_clauses(columns, values)
      clauses = values.map do |value|
        grouping = columns.map do |column|
          column.build_condition(value)
        end
        grouping.compact!
        next if grouping.empty?

        clause = grouping.inject(&:or)
        clause = clause.not if value.negate
        clause
      end
      clauses.compact!
      clauses
    end
  end
end
