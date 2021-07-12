module SearchableBy
  class Config
    attr_reader :columns, :scoping, :options
    attr_accessor :max_terms, :min_length

    def initialize
      @columns = []
      @max_terms = 5
      @min_length = 0
      @options = {}
      scope { all }
    end

    def initialize_copy(other)
      @columns = other.columns.dup
      super
    end

    def column(*attrs, &block)
      opts = attrs.extract_options!
      attrs.each do |attr|
        columns.push Column.new(attr, **@options, **opts)
      end
      columns.push Column.new(block, **@options, **opts) if block
      columns
    end

    def scope(&block)
      @scoping = block
    end
  end
end
