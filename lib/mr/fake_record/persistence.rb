require 'active_model'
require 'active_record'
require 'active_record/validations'
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

    # ActiveRecord methods

    def save!
      raise ActiveRecord::RecordInvalid.new(self) unless self.valid?
      self.id ||= MR::Factory.primary_key(self.class)
      current_time = CurrentTime.new
      self.created_at ||= current_time if self.respond_to?(:created_at=)
      if self.respond_to?(:updated_at=) && !self.updated_at_changed?
        self.updated_at = current_time
      end
      self.saved_attributes = self.attributes.dup
      @save_called = true
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

    # Non-ActiveRecord methods

    def save_called
      @save_called = false if @save_called.nil?
      @save_called
    end

    def reset_save_called
      @save_called = false
    end

    module ClassMethods

      # ActiveRecord methods

      def transaction
        yield
      end

      # this is needed to raise ActiveRecord::RecordInvalid
      def human_attribute_name(attribute, options = {})
        options[:default] || attribute.to_s.split('.').last
      end

    end

    module CurrentTime
      def self.new
        if ActiveRecord::Base.default_timezone == :utc
          Time.now.utc
        else
          Time.now
        end
      end
    end

  end

end
