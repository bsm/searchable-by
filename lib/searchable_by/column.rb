module SearchableBy
  class Column
    attr_reader :attr, :type, :match
    attr_accessor :node

    def initialize(attr, type: :string, match: :all)
      @attr  = attr
      @type  = type.to_sym
      @match = match
    end

    def build_condition(value)
      case type
      when :int, :integer
        begin
          node.not_eq(nil).and(node.eq(Integer(value.term)))
        rescue ArgumentError
          nil
        end
      else
        term = value.term.dup
        term.gsub!('%', '\%')
        term.gsub!('_', '\_')
        case match
        when :suffix
          term << '%'
        else
          term = "%#{term}%"
        end
        node.not_eq(nil).and(node.matches(term))
      end
    end
  end
end
