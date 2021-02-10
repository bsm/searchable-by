module SearchableBy
  class Column
    attr_reader :attr, :type, :match, :match_phrase, :min_length
    attr_accessor :node

    def initialize(attr, type: :string, match: :all, match_phrase: nil, min_length: 0)
      @attr  = attr
      @type  = type.to_sym
      @match = match
      @match_phrase = match_phrase || match
      @min_length = min_length
    end

    def build_condition(value)
      return Arel::Nodes::False.new if value.term.length < min_length # no-match

      scope = node.not_eq(nil)

      case type
      when :int, :integer
        int_condition(scope, value)
      else
        str_condition(scope, value)
      end
    end

    private

    def int_condition(scope, value)
      scope.and(node.eq(Integer(value.term)))
    rescue ArgumentError
      nil
    end

    def str_condition(scope, value)
      term = value.term.dup
      type = value.phrase ? match_phrase : match

      case type
      when :exact
        term.downcase!
        scope.and(node.lower.eq(term))
      when :prefix
        term.gsub!('%', '\%')
        term.gsub!('_', '\_')
        scope.and(node.matches("#{term}%"))
      else
        term.gsub!('%', '\%')
        term.gsub!('_', '\_')
        scope.and(node.matches("%#{term}%"))
      end
    end
  end
end
