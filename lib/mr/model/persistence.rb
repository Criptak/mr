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
      self.transaction do
        raise InvalidError.new(self, self.errors) unless self.valid?
        record.save!
      end
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

    def initialize(model, errors)
      @errors = errors || {}
      desc = @errors.map do |(attribute, messages)|
        messages.map{ |message| "#{attribute.inspect} #{message}" }
      end.sort.join(', ')
      super "Invalid #{model.class} couldn't be saved: #{desc}"
    end

  end

end
