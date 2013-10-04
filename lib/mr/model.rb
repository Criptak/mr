require 'ns-options'
require 'set'
require 'mr'
require 'mr/associations/one_to_one'
require 'mr/associations/one_to_many'
require 'mr/fields'
require 'mr/record'

module MR; end
module MR::Model

  def self.included(klass)
    klass.class_eval do

      include NsOptions
      options :mr_config do
        option :record_class
        option :interface_module
        option :fields,       Set, :default => []
        option :associations, Set, :default => []
      end
      self.mr_config.interface_module = Module.new

      extend ClassMethods
      include InstanceMethods
      include self.mr_config.interface_module

    end
  end

  module InstanceMethods

    attr_reader :record
    protected :record

    def initialize(*args)
      field_values, @record = [
        args.last.kind_of?(Hash) ? args.pop : {},
        args.last || self.class.record_class.new
      ]
      if @record.kind_of?(MR::Record)
        @record.model = self
      else
        raise MR::InvalidRecordError.new(@record)
      end
      self.fields = field_values
    end

    def fields
      self.class.fields.inject({}) do |h, name|
        h.merge({ name => self.send(name) })
      end
    end

    def fields=(values)
      values.each do |name, value|
        self.send "#{name}=", value
      end
    end

    def save(field_values = nil)
      self.fields = field_values || {}
      event = @record.new_record? ? 'create' : 'update'
      self.transaction(event) do
        run_callback 'before_validation'
        run_callback "before_validation_on_#{event}"
        raise InvalidError.new(self, self.errors) if !@record.valid?
        run_callback 'before_save'
        run_callback "before_#{event}"
        @record.save!
        run_callback "after_#{event}"
        run_callback 'after_save'
      end
    end

    def destroy
      self.transaction('destroy') do
        run_callback 'before_destroy'
        @record.destroy
        run_callback 'after_destroy'
      end
    end

    def transaction(*args, &block)
      if (event = args.first) && !['create', 'update', 'destroy'].include?(event)
        raise ArgumentError, 'transaction events must be one of: create, update, destroy'
      end

      run_callback 'before_transaction'
      run_callback "before_transaction_on_#{event}" if event
      @record.transaction(&block)
      run_callback "after_transaction_on_#{event}" if event
      run_callback 'after_transaction'
    end

    def errors
      @record.errors.messages
    end

    def valid?
      @record.valid?
    end

    def new?
      @record.new_record?
    end

    def destroyed?
      @record.destroyed?
    end

    def ==(other)
      if other.kind_of?(self.class)
        @record == other.record
      else
        super
      end
    end

    private

    def before_validation; end
    def before_validation_on_create; end
    def before_validation_on_update; end
    def before_save;    end
    def after_save;     end
    def before_create;  end
    def after_create;   end
    def before_update;  end
    def after_update;   end
    def before_destroy; end
    def after_destroy;  end

    def before_transaction; end
    def after_transaction;  end
    def before_transaction_on_create; end
    def after_transaction_on_create;  end
    def before_transaction_on_update; end
    def after_transaction_on_update;  end
    def before_transaction_on_destroy; end
    def after_transaction_on_destroy;  end

    def run_callback(name)
      self.send(name)
    end

  end

  module ClassMethods

    def record_class(value = nil)
      (self.record_class = value) if value
      self.mr_config.record_class
    end

    def record_class=(value)
      raise ArgumentError, "must be a MR::Record" unless value < MR::Record
      self.mr_config.record_class = value
      value.model_class = self
    end

    def fields
      self.mr_config.fields
    end

    def field_reader(*field_names)
      field_names.each do |field_name|
        MR::Fields::Reader.new(self.mr_config.interface_module, field_name)
        self.mr_config.fields.add field_name.to_sym
      end
    end

    def field_writer(*field_names)
      field_names.each do |field_name|
        MR::Fields::Writer.new(self.mr_config.interface_module, field_name)
        self.mr_config.fields.add field_name.to_sym
      end
    end

    def field_accessor(*field_names)
      field_names.each do |field_name|
        MR::Fields::Reader.new(self.mr_config.interface_module, field_name)
        MR::Fields::Writer.new(self.mr_config.interface_module, field_name)
        self.mr_config.fields.add field_name.to_sym
      end
    end

    def associations
      self.mr_config.associations
    end

    def belongs_to(name, class_name, options = nil)
      options ||= {}
      options[:class_name] = class_name
      MR::Associations::BelongsTo.new(name, options).tap do |a|
        a.define_methods(self.mr_config.interface_module)
        self.associations << a
      end
    end

    def has_many(name, class_name, options = nil)
      options ||= {}
      options[:class_name] = class_name
      MR::Associations::HasMany.new(name, options).tap do |a|
        a.define_methods(self.mr_config.interface_module)
        self.associations << a
      end
    end

    def has_one(name, class_name, options = nil)
      options ||= {}
      options[:class_name] = class_name
      MR::Associations::HasOne.new(name, options).tap do |a|
        a.define_methods(self.mr_config.interface_module)
        self.associations << a
      end
    end

    def polymorphic_belongs_to(name, options = nil)
      MR::Associations::PolymorphicBelongsTo.new(name, options).tap do |a|
        a.define_methods(self.mr_config.interface_module)
        self.associations << a
      end
    end

    def find(id)
      self.new(self.record_class.find(id))
    end

    def all
      self.record_class.all.map{|record| self.new(record) }
    end

    def transaction(&block)
      self.record_class.transaction(&block)
    end

  end

  class InvalidError < RuntimeError
    attr_reader :errors
    def initialize(model, errors)
      @errors = errors
      super "Invalid #{model.class} couldn't be saved: #{errors_description}"
    end

    private

    def errors_description
      return '' if !@errors.kind_of?(::Hash)

      @errors.keys.inject([]) do |details, thing|
        (@errors[thing] || []).each{ |msg| details << "#{thing.inspect} #{msg}" }
        details
      end.join(', ')
    end
  end

end
