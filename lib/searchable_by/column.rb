module SearchableBy
  class Column
    attr_reader :attr, :type, :match, :match_phrase, :wildcard
    attr_accessor :node

    def initialize(attr, type: :string, match: :all, match_phrase: nil, wildcard: nil, **_opts) # rubocop:disable Metrics/ParameterLists
      @attr  = attr
      @type  = type.to_sym
      @match = match
      @match_phrase = match_phrase || match
      @wildcard = wildcard
    end

    def full_match?
      match == :full
    end

    def partial_match?
      match != :full && match_phrase != :full
    end

    def build_condition(value)
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
      when :full
        escape_term!(term)
        scope.and(node.matches(term))
      when :prefix
        escape_term!(term)
        scope.and(node.matches("#{term}%"))
      else # :all (wraps term in wildcards)
        escape_term!(term)
        scope.and(node.matches("%#{term}%"))
      end
    end

    def escape_term!(term)
      term.gsub!('%', '\%')
      term.gsub!('_', '\_')
      term.gsub!(wildcard, '%') if wildcard
    end
  end
end
