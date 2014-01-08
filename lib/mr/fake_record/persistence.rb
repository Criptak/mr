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

    attr_writer :current_saved_changes, :previous_saved_changes

    def save!
      self.id ||= MR::Factory.primary_key(self.class)
      current_time = CurrentTime.new
      self.created_at ||= current_time if self.respond_to?(:created_at=)
      if self.respond_to?(:updated_at=) && !self.updated_at_changed?
        self.updated_at = current_time
      end
      self.saved_attributes = self.attributes.dup
      self.previous_saved_changes = self.current_saved_changes
      changed_attributes = self.attributes.to_a - self.current_saved_changes.to_a
      self.current_saved_changes = Hash[changed_attributes]
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

    def current_saved_changes
      @current_saved_changes ||= {}
    end

    def previous_saved_changes
      @previous_saved_changes ||= {}
    end

    module ClassMethods

      def transaction
        yield
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
