require 'active_support/core_ext/string'

module MR::Associations

  module Helpers

    def constantize(class_name, name)
      class_name.to_s.constantize
    rescue NameError
      raise NoAssociatedClassError.new(name, class_name)
    end

  end

  class NoAssociatedClassError < RuntimeError
    def initialize(name, class_name)
      super "A class couldn't be found " \
            "for the #{name.inspect} association using #{class_name.inspect}"
    end
  end

end
