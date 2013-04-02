require 'ns-options'
require 'set'
require 'mr/associations'
require 'mr/fields'
require 'mr/record'

module MR; end
module MR::Model

  def self.included(klass)
    klass.class_eval do

      include NsOptions
      options :mr_config do
        option :record_class
        option :fields, Set, :default => []
      end

      extend ClassMethods

    end
  end

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
      raise InvalidRecordError.new(@record)
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
    new_record = @record.new_record?
    self.transaction do
      run_callback 'before_save'
      run_callback new_record ? 'before_create' : 'before_update'
      @record.save!
      run_callback new_record ? 'after_create' : 'after_update'
      run_callback 'after_save'
    end
  end

  def destroy
    run_callback 'before_destroy'
    @record.destroy
    run_callback 'after_destroy'
  end

  def transaction(&block)
    @record.transaction(&block)
  end

  def valid?
    @record.valid?
  end

  def ==(other)
    if other.kind_of?(self.class)
      @record == other.record
    else
      super
    end
  end

  private

  def before_save;    end
  def after_save;     end
  def before_create;  end
  def after_create;   end
  def before_update;  end
  def after_update;   end
  def before_destroy; end
  def after_destroy;  end

  def run_callback(name)
    self.send(name)
  end

  module ClassMethods

    def record_class(*args)
      self.mr_config.record_class *args
    end

    def fields
      self.mr_config.fields
    end

    def field_reader(*field_names)
      field_names.each do |field_name|
        MR::Fields::Reader.new(self, field_name)
        self.mr_config.fields.add field_name.to_sym
      end
    end

    def field_writer(*field_names)
      field_names.each do |field_name|
        MR::Fields::Writer.new(self, field_name)
        self.mr_config.fields.add field_name.to_sym
      end
    end

    def field_accessor(*field_names)
      field_names.each do |field_name|
        MR::Fields::Reader.new(self, field_name)
        MR::Fields::Writer.new(self, field_name)
        self.mr_config.fields.add field_name.to_sym
      end
    end

    def belongs_to(name, class_name, options = nil)
      MR::Associations::BelongsTo.new(name, class_name, options).tap do |a|
        a.define_methods(self)
      end
    end

    def has_many(name, class_name, options = nil)
      MR::Associations::HasMany.new(name, class_name, options).tap do |a|
        a.define_method(self)
      end
    end

  end

  class InvalidRecordError < RuntimeError
    def initialize(record)
      super "The passed record is not a kind of MR::Record: #{record.inspect}"
    end
  end

end
