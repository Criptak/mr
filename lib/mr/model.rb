require 'ns-options'
require 'set'
require 'mr/associations/belongs_to'
require 'mr/associations/has_many'
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
    event = @record.new_record? ? 'create' : 'update'
    raise InvalidError.new(self, self.errors) if !@record.valid?
    self.transaction(event) do
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
        a.define_methods(self)
      end
    end

    def find(id)
      self.new(self.record_class.find(id))
    end

    def all
      self.record_class.all.map{|record| self.new(record) }
    end

  end

  class InvalidError < RuntimeError
    attr_reader :errors
    def initialize(model, errors)
      @errors = errors
      super "Invalid #{model.class} couldn't be saved"
    end
  end

  class InvalidRecordError < RuntimeError
    def initialize(record)
      super "The passed record is not a kind of MR::Record: #{record.inspect}"
    end
  end

end
