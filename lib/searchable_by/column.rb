module SearchableBy
  class Column
    attr_reader :attr, :type, :match, :match_phrase, :wildcard
    attr_accessor :node

    def initialize(attr, type: :string, match: :all, match_phrase: nil, wildcard: nil, **opts) # rubocop:disable Metrics/ParameterLists
      if opts.key?(:min_length)
        ActiveSupport::Deprecation.warn(
          'Setting min_length for individual columns is deprecated and will be removed in the next release.' \
          'Please pass it as an option to searchable_by instead',
        )
      end

      @attr  = attr
      @type  = type.to_sym
      @match = match
      @match_phrase = match_phrase || match
      @min_length = opts[:min_length].to_i
      @wildcard = wildcard
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

    # TODO: remove when removing min_length option from columns
    def usable?(value)
      value.term.length >= @min_length
    end

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
      else # :all (wraps term in wildcards) or :wildcard (explicit wildcards)
        term.gsub!('%', '\%')
        term.gsub!('_', '\_')
        term.gsub!(wildcard, '%') if wildcard
        pattern = type == :wildcard ? term : "%#{term}%"
        scope.and(node.matches(pattern))
      end
    end
  end
end
