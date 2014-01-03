require 'active_model'
require 'mr/factory'
require 'mr/fake_record/attributes'

module MR; end
module MR::FakeRecord

  module Persistence

    def self.included(klass)
      klass.class_eval do
        include MR::FakeRecord::Attributes
        extend ClassMethods

        attribute :id, :primary_key
      end
    end

    def save!
      self.id ||= MR::Factory.primary_key(self.class)
      self.created_at ||= Time.now if self.respond_to?(:created_at=)
      self.updated_at   = Time.now if self.respond_to?(:updated_at=)
      self.previous_attributes = self.saved_attributes.dup
      changed_attributes = self.attributes.to_a - self.saved_attributes.to_a
      self.saved_attributes = Hash[changed_attributes]
    end

    def destroy
      @destroyed = true
    end

    def transaction(&block)
      self.class.transaction(&block)
    end

    def new_record?
      !self.id
    end

    def destroyed?
      !!@destroyed
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def valid?
      self.errors.empty?
    end

    module ClassMethods

      def transaction
        yield
      end

    end

  end

end
