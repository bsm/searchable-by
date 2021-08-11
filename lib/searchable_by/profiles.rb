module SearchableBy
  class Profiles
    def initialize
      @profiles = {}
    end

    def [](name)
      name = name.to_sym
      @profiles[name] ||= Config.new
    end

    def each(&block)
      @profiles.each(&block)
    end

    def initialize_copy(other)
      @profiles = {}
      other.each do |name, config|
        @profiles[name] = config.dup
      end
    end
  end
end
