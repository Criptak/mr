require 'assert'
require 'mr/fake_record/attributes'

module MR::FakeRecord::Attributes

  class UnitTests < Assert::Context
    desc "MR::FakeRecord::Attributes"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord::Attributes
      end
    end
    subject{ @fake_record_class }

    should have_imeths :attributes, :attribute, :columns

    should "return an instance of a AttributeSet using `attributes`" do
      attributes = subject.attributes
      assert_instance_of MR::FakeRecord::AttributeSet, attributes
      assert_same attributes, subject.attributes
    end

    should "add attribute methods with `attribute`" do
      subject.attribute :name, :string, :null => false
      fake_record = subject.new

      assert_respond_to :name,          fake_record
      assert_respond_to :name=,         fake_record
      assert_respond_to :name_was,      fake_record
      assert_respond_to :name_changed?, fake_record
      fake_record.name = 'test'
      assert_equal 'test', fake_record.name
      attribute = subject.attributes.find(:name)
      assert_equal false, attribute.null
    end

    should "return an array of fake record attributes with `columns`" do
      subject.attribute :name,   :string
      subject.attribute :active, :boolean
      columns = subject.columns

      expected = [
        MR::FakeRecord::Attribute.new(:name, :string),
        MR::FakeRecord::Attribute.new(:active, :boolean)
      ].sort
      assert_equal expected, columns
    end

  end

  class InstanceTests < UnitTests
    desc "for a fake record instance"
    setup do
      @fake_record_class.attribute :name, :string
      @fake_record_class.attribute :active, :boolean
      @fake_record = @fake_record_class.new
    end
    subject{ @fake_record }

    should have_writers :saved_attributes
    should have_imeths :saved_attributes
    should have_imeths :attributes, :attributes=
    should have_imeths :column_for_attribute

    should "return an empty hash using `saved_attributes`" do
      assert_equal({}, subject.saved_attributes)
    end

    should "return a hash of attribute values using `attributes`" do
      subject.name = 'test'
      subject.active = true
      expected = { 'name' => 'test', 'active' => true }
      assert_equal expected, subject.attributes
    end

    should "allow writing multiple attribute values using `attributes=`" do
      subject.attributes = { 'name' => 'test', 'active' => true }
      assert_equal 'test', subject.name
      assert_equal true,   subject.active
    end

    should "ignore non hash arguments passed to `attributes=`" do
      assert_nothing_raised{ subject.attributes = 'test' }
    end

    should "return the matching attribute column using `column_for_attribute`" do
      expected = @fake_record_class.columns.detect{ |c| c.name == 'name' }
      assert_equal expected, subject.column_for_attribute('name')
      assert_nil subject.column_for_attribute('doesnt_exist')
    end

  end

  class AttributeSetTests < UnitTests
    desc "AttributeSet"
    setup do
      @fake_record = @fake_record_class.new
      @attribute_set = MR::FakeRecord::AttributeSet.new
    end
    subject{ @attribute_set }

    should have_imeths :add, :find
    should have_imeths :read_all, :batch_write
    should have_imeths :each, :to_a

    should "be enumerable" do
      assert_includes Enumerable, subject.class
    end

    should "add an attribute to the set with `add` and return it using `find`" do
      subject.add @fake_record_class, :created_at, :timestamp, :null => false

      attribute = subject.find(:created_at)
      assert_instance_of MR::FakeRecord::Attribute, attribute
      assert_equal 'created_at', attribute.name
      assert_equal :timestamp,   attribute.type
      assert_equal false,        attribute.null
    end

    should "allow mass reading and writing using `read_all` and `batch_write`" do
      subject.add @fake_record_class, :name, :string
      subject.add @fake_record_class, :active, :boolean
      values = { 'name' => 'test', 'active' => true }
      subject.batch_write(values, @fake_record)
      assert_equal 'test', @fake_record.name
      assert_equal true,   @fake_record.active
      assert_equal values, subject.read_all(@fake_record)
    end

    should "yield each attribute using `each`" do
      yielded = []
      subject.each{ |a| yielded << a }
      assert_equal yielded.sort, subject.to_a
    end

    should "return it's attributes sorted using `to_a`" do
      subject.add @fake_record_class, :name, :string
      subject.add @fake_record_class, :active, :boolean
      array = subject.to_a

      expected = [
        MR::FakeRecord::Attribute.new(:name, :string),
        MR::FakeRecord::Attribute.new(:active, :boolean)
      ].sort
      assert_equal expected, array
    end

    should "raise a NoAttributeError using `find` with an invalid name" do
      assert_raises(MR::FakeRecord::NoAttributeError) do
        subject.find(:doesnt_exist)
      end
    end

  end

  class AttributeTests < UnitTests
    desc "Attribute"
    setup do
      @fake_record_class.attribute :name, :string
      @fake_record = @fake_record_class.new
      @attribute = MR::FakeRecord::Attribute.new(:name, :string)
    end
    subject{ @attribute }

    should have_readers :name, :type, :primary, :null
    should have_readers :reader_method_name, :writer_method_name
    should have_readers :was_method_name, :changed_method_name
    should have_imeths :read, :write, :was, :changed?

    should "know it's name and type" do
      assert_equal 'name',  subject.name
      assert_equal :string, subject.type
    end

    should "know if it's a primary attribute or not" do
      attribute = MR::FakeRecord::Attribute.new(:name, :string)
      assert_equal false, attribute.primary
      attribute = MR::FakeRecord::Attribute.new(:id, :primary_key)
      assert_equal true, attribute.primary
    end

    should "default its null attribute to true" do
      assert_equal true, subject.null
    end

    should "allow setting its null attribute using an options hash" do
      attribute = MR::FakeRecord::Attribute.new(:name, :string, :null => false)
      assert_equal false, attribute.null
      attribute = MR::FakeRecord::Attribute.new(:name, :string, :null => true)
      assert_equal true, attribute.null
    end

    should "know it's method names" do
      assert_equal "name",          subject.reader_method_name
      assert_equal "name=",         subject.writer_method_name
      assert_equal "name_was",      subject.was_method_name
      assert_equal "name_changed?", subject.changed_method_name
    end

    should "read an attribute's value using `read`" do
      assert_nil subject.read(@fake_record)
      @fake_record.name = 'test'
      assert_equal 'test', subject.read(@fake_record)
    end

    should "write an attribute's value using `write`" do
      subject.write('test', @fake_record)
      assert_equal 'test', @fake_record.name
    end

    should "read an attribute's previous value using `was`" do
      @fake_record.saved_attributes = {}
      assert_nil subject.was(@fake_record)
      @fake_record.saved_attributes = { 'name' => 'test' }
      assert_equal 'test', subject.was(@fake_record)
    end

    should "detect if an attribute's changed using `changed?`" do
      @fake_record.saved_attributes = {}
      assert_equal false, subject.changed?(@fake_record)
      subject.write('test', @fake_record)
      assert_equal true, subject.changed?(@fake_record)
      @fake_record.saved_attributes = { 'name' => 'test' }
      assert_equal false, subject.changed?(@fake_record)
    end

    should "be comparable" do
      attribute = MR::FakeRecord::Attribute.new(:name, :string)
      assert_equal attribute, subject
      attribute = MR::FakeRecord::Attribute.new(:id, :string)
      assert_not_equal attribute, subject
      attribute = MR::FakeRecord::Attribute.new(:name, :boolean)
      assert_not_equal attribute, subject
      attribute = MR::FakeRecord::Attribute.new(:name, :string, :null => false)
      assert_not_equal attribute, subject
    end

    should "be sortable" do
      attributes = [
        MR::FakeRecord::Attribute.new(:id, :primary_key),
        MR::FakeRecord::Attribute.new(:name, :string),
        MR::FakeRecord::Attribute.new(:active, :boolean)
      ].sort
      assert_equal [ 'active', 'id', 'name' ], attributes.map(&:name)
    end

    should "define attribute methods using `define_on`" do
      subject.define_on(@fake_record_class)
      fake_record = @fake_record_class.new

      assert_respond_to :name,          fake_record
      assert_respond_to :name=,         fake_record
      assert_respond_to :name_was,      fake_record
      assert_respond_to :name_changed?, fake_record
    end

  end

end
