require 'active_record'

module SearchableBy
  autoload :Column, 'searchable_by/column'
  autoload :Concern, 'searchable_by/concern'
  autoload :Config, 'searchable_by/config'
  autoload :Util, 'searchable_by/util'

  Value = Struct.new(:term, :negate)
end

ActiveRecord::Base.extend SearchableBy::Concern if defined?(::ActiveRecord::Base)
