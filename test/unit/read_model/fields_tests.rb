require 'assert'
require 'mr/read_model/fields'

require 'mr/factory'

module MR::ReadModel::Fields

  class UnitTests < Assert::Context
    desc "MR::ReadModel::Fields"
    setup do
      @read_model_class = Class.new do
        include MR::ReadModel::Fields
        def initialize(data); set_data(data); end
      end
    end
    subject{ @read_model_class }

    should have_imeths :fields, :field

    should "include the ReadModel Data and Querying mixins" do
      assert_includes MR::ReadModel::Data, subject
      assert_includes MR::ReadModel::Querying, subject
    end

    should "return a FieldSet using `fields`" do
      fields = subject.fields
      assert_instance_of MR::ReadModel::FieldSet, fields
      assert_same fields, subject.fields
    end

    should "add a field to the FieldSet using `field`" do
      subject.field :test, :string
      field = subject.fields.find(:test)

      assert_instance_of MR::ReadModel::Field, field
      assert_equal 'test',  field.name
      assert_equal :string, field.type
    end

    should "define a reader method for the field using `field`" do
      subject.field :test, :string
      data = { 'test' => 'something' }
      read_model = subject.new(data)

      assert_respond_to :test, read_model
      assert_equal 'something', read_model.test
    end

    should "add a select to its relation when `field` is passed select args" do
      subject.field :test, :string, 'some_table.some_column'

      assert_equal 1, subject.relation.expressions.size
      expression = subject.relation.expressions.first
      assert_equal 'some_table.some_column AS test', expression.args.first
    end

    should "add a select to its relation when `field` is passed a block" do
      subject.field(:test, :string){ |column| column }

      assert_equal 1, subject.relation.expressions.size
      expression = subject.relation.expressions.first
      expected = 'some_table.some_column AS test'
      assert_equal expected, expression.block.call('some_table.some_column')
    end

    should "raise an ArgumentError when `field` is passed an invalid field type" do
      assert_raises(ArgumentError){ subject.field :test, :invalid }
    end

  end

  class InstanceTests < UnitTests
    desc "for a read model instance"
    setup do
      @data = {
        'name'        => 'test',
        'active'      => true,
        'description' => 'desc'
      }
      @read_model_class.class_eval do
        field :name,        :string
        field :active,      :boolean
        field :description, :string
      end
      @read_model = @read_model_class.new(@data)
    end
    subject{ @read_model }

    should have_imeths :fields

    should "allow reading all the fields using `fields`" do
      expected = {
        'name'        => 'test',
        'active'      => true,
        'description' => 'desc'
      }
      assert_equal expected, subject.fields
    end

  end

  class FieldSetTests < UnitTests
    desc "FieldSet"
    setup do
      @field_set = MR::ReadModel::FieldSet.new.tap do |s|
        s.add :name,   :string
        s.add :active, :boolean
      end
    end
    subject{ @field_set }

    should have_imeths :find, :read_all
    should have_imeths :add
    should have_imeths :each

    should "be enumerable" do
      assert_includes Enumerable, MR::ReadModel::FieldSet
    end

    should "return all of it's fields values using `read_all`" do
      @data = { 'name' => 'Name', 'active' => 'true' }
      expected = { 'name' => 'Name', 'active' => true }
      assert_equal expected, subject.read_all(@data)
    end

    should "yield it's fields using `each`" do
      yielded_fields = []
      subject.each{ |f| yielded_fields << f }
      assert_includes subject.find(:name), yielded_fields
      assert_includes subject.find(:active), yielded_fields
    end

  end

  class FieldTests < UnitTests
    desc "Field"
    setup do
      @field = MR::ReadModel::Field.new(:test, :boolean)
    end
    subject{ @field }

    should have_readers :name, :type
    should have_readers :method_name, :ivar_name
    should have_imeths :read, :define_on

    should "know it's name and type" do
      assert_equal 'test',   subject.name
      assert_equal :boolean, subject.type
    end

    should "know it's method name and ivar name" do
      assert_equal 'test',  subject.method_name
      assert_equal '@test', subject.ivar_name
    end

    should "read a value and type-cast it from passed-in data using `read`" do
      assert_equal true,  subject.read('test' => 'true')
      assert_equal false, subject.read('test' => 'false')
    end

    should "return `nil` when passed-in data's value is `nil` using `read`" do
      assert_equal nil, subject.read('test' => nil)
    end

    should "define a reader method on an object using `define_on`" do
      subject.define_on(@read_model_class)
      read_model = @read_model_class.new('test' => 'true')

      assert_respond_to subject.method_name, read_model
      value = read_model.send(subject.method_name)
      assert_same value, read_model.send(subject.method_name)
    end

    should "raise a bad field type error when built with an invalid field type" do
      assert_raises(MR::ReadModel::BadFieldTypeError) do
        MR::ReadModel::Field.new(:test, :invalid)
      end
    end

  end

end
