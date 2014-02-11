require 'mr/model/configuration'

module MR; end
module MR::Model

  module Persistence

    def self.included(klass)
      klass.class_eval do
        include MR::Model::Configuration
        extend ClassMethods
      end
    end

    def save
      self.transaction{ record.save! }
    rescue ActiveRecord::RecordInvalid => exception
      # `caller` is not consistent between 1.8 and 2.0, if we stop supporting
      # older versions, we can switch to using `caller`
      called_from = exception.backtrace[6..-1]
      raise InvalidError.new(self, self.errors, called_from)
    end

    def destroy
      record.destroy
    end

    def transaction(&block)
      record.transaction(&block)
    end

    def errors
      record.errors.messages
    end

    def valid?
      record.valid?
    end

    def new?
      record.new_record?
    end

    def destroyed?
      record.destroyed?
    end

    module ClassMethods

      def transaction(&block)
        self.record_class.transaction(&block)
      end

    end

  end

  class InvalidError < RuntimeError
    attr_reader :errors

    def initialize(model, errors, backtrace = nil)
      @errors = errors || {}
      desc = @errors.map do |(attribute, messages)|
        messages.map{ |message| "#{attribute.inspect} #{message}" }
      end.sort.join(', ')
      super "Invalid #{model.class} couldn't be saved: #{desc}"
      set_backtrace(backtrace) if backtrace
    end

  end

end
