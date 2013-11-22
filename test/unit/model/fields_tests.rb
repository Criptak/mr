require 'assert'
require 'mr/model/fields'

require 'mr/fake_record'

module MR::Model::Fields

  class UnitTests < Assert::Context
    desc "MR::Model::Fields"
    setup do
      @model_class = Class.new do
        include MR::Model::Fields
        def initialize(record); set_record record; end
      end
      @record = FakeTestRecord.new
    end
    subject{ @model_class }

    should have_imeths :fields, :field_reader, :field_writer, :field_accessor

    should "include Model::Configuration mixin" do
      assert_includes MR::Model::Configuration, subject
    end

    should "return an instance of a FieldSet using `fields`" do
      fields = subject.fields
      assert_instance_of MR::Model::FieldSet, fields
      assert_same fields, subject.fields
    end

    should "add reader methods for a field using `field_reader`" do
      subject.field_reader :name
      @record.name = 'test'
      model = subject.new(@record)

      assert_respond_to :name, model
      assert_respond_to :name_changed?, model
      assert_equal @record.name, model.name
      assert_equal @record.name_changed?, model.name_changed?
    end

    should "add writer methods for a field using `field_writer`" do
      subject.field_writer :name
      model = subject.new(@record)

      assert_respond_to :name=, model
      model.name = 'test'
      assert_equal 'test', @record.name
    end

    should "add accessor methods for a field using `field_accessor`" do
      subject.field_accessor :name
      model = subject.new(@record)

      assert_respond_to :name, model
      assert_respond_to :name_changed?, model
      assert_respond_to :name=, model
      model.name = 'test'
      assert_equal 'test', @record.name
      assert_equal @record.name, model.name
      assert_equal @record.name_changed?, model.name_changed?
    end

  end

  class InstanceTests < UnitTests
    desc "for a model instance"
    setup do
      @model_class.class_eval do
        field_accessor :name, :active, :description
      end
      @model = @model_class.new(@record)
    end
    subject{ @model }

    should have_imeths :fields, :fields=

    should "allow reading all the fields using `fields`" do
      subject.name = 'test'
      subject.active = true
      subject.description = 'desc'

      expected = {
        'name'        => 'test',
        'active'      => true,
        'description' => 'desc'
      }
      assert_equal expected, subject.fields
    end

    should "allow writing multiple fields using `fields=`" do
      subject.fields = {
        'name'        => 'test',
        'active'      => true,
        'description' => 'desc'
      }
      assert_equal 'test', subject.name
      assert_equal true,   subject.active
      assert_equal 'desc', subject.description
    end

    should "raise an ArgumentError when a non-Hash is passed to `fields=`" do
      assert_raises(ArgumentError){ subject.fields = 'test' }
    end

    should "raise a no field error when writing a bad field using `fields=`" do
      assert_raises(MR::Model::NoFieldError) do
        subject.fields = { :not_valid => 'test' }
      end
    end

  end

  class FieldSetTests < UnitTests
    desc "FieldSet"
    setup do
      @fields_set = MR::Model::FieldSet.new
    end
    subject{ @fields_set }

    should have_imeths :names
    should have_imeths :find, :get
    should have_imeths :read_all, :batch_write
    should have_imeths :add_reader, :add_writer

    should "return a list of all the field names using `names`" do
      subject.get('name')
      subject.get('active')
      assert_equal [ 'active', 'name' ], subject.names
    end

    should "return an existing field or raise a no field error using `find`" do
      subject.get('name')
      field = subject.find('name')
      assert_instance_of MR::Model::Field, field
      assert_equal 'name', field.name

      assert_raises(MR::Model::NoFieldError){ subject.find('not_valid') }
    end

    should "return an existing field or build a new field using `get`" do
      field = subject.get('name')
      assert_instance_of MR::Model::Field, field
      assert_equal 'name', field.name
      assert_same field, subject.get('name')
    end

    should "return a hash of field names and values using `read_all`" do
      assert_equal({}, subject.read_all(@record))
      subject.get('name')
      @record.name = 'test'
      assert_equal({ 'name' => 'test' }, subject.read_all(@record))
    end

    should "set multiple field values using `batch_write`" do
      subject.get('name')
      subject.get('active')
      values = { :name => 'test', :active => true }
      subject.batch_write(values, @record)

      assert_equal 'test', @record.name
      assert_equal true,   @record.active
    end

    should "add a field and define reader methods for it using `add_reader`" do
      subject.add_reader('name', @model_class)

      assert_instance_of MR::Model::Field, subject.find('name')
      model = @model_class.new(@record)
      assert_respond_to :name, model
      assert_respond_to :name_changed?, model
    end

    should "add a field and define writer methods for it using `add_writer`" do
      subject.add_writer('name', @model_class)

      assert_instance_of MR::Model::Field, subject.find('name')
      model = @model_class.new(@record)
      assert_respond_to :name=, model
    end

  end

  class FieldTests < UnitTests
    desc "Field"
    setup do
      @field = MR::Model::Field.new('name')
    end
    subject{ @field }

    should have_readers :name
    should have_readers :reader_method_name, :changed_method_name
    should have_readers :writer_method_name

    should have_imeths :read, :write, :changed?
    should have_imeths :define_reader_on, :define_writer_on

    should "know it's name and method names" do
      assert_equal 'name',          subject.name
      assert_equal 'name',          subject.reader_method_name
      assert_equal 'name_changed?', subject.changed_method_name
      assert_equal 'name=',         subject.writer_method_name
    end

    should "read a record's attribute using `read`" do
      @record.name = 'test'
      assert_equal 'test', subject.read(@record)
    end

    should "write a record's attribute using `write`" do
      subject.write('test', @record)
      assert_equal 'test', @record.name
    end

    should "return if a record's attribute has changed using `changed`" do
      assert_equal false, subject.changed?(@record)
      subject.write('test', @record)
      assert_equal true, subject.changed?(@record)
    end

    should "define reader methods using `define_reader_on`" do
      subject.define_reader_on(@model_class)
      model = @model_class.new(@record)
      assert_respond_to :name, model
      assert_respond_to :name_changed?, model
    end

    should "define writer methods using `define_writer_on`" do
      subject.define_writer_on(@model_class)
      model = @model_class.new(@record)
      assert_respond_to :name=, model
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
    attribute :name,        :string
    attribute :active,      :boolean
    attribute :description, :text
  end

end
