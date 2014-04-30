require 'assert'
require 'mr/model'

require 'mr/fake_record'

module MR::Model

  class UnitTests < Assert::Context
    desc "MR::Model"
    setup do
      @model_class = Class.new do
        include MR::Model
        record_class FakeTestRecord
        field_reader :id
        field_accessor :name, :active
      end
    end
    subject{ @model_class }

    should have_imeths :find, :all

    should "include the configuration, fields, associations and persistence mixins" do
      assert_includes MR::Model::Configuration, subject
      assert_includes MR::Model::Fields, subject
      assert_includes MR::Model::Associations, subject
      assert_includes MR::Model::Persistence, subject
    end

    should "allow passing a record to it's initialize" do
      fake_record = FakeTestRecord.new(:name => 'test')
      model = subject.new(fake_record)
      assert_equal 'test', model.name
    end

    should "allow passing fields to it's initialize" do
      model = subject.new(:name => 'test')
      assert_equal 'test', model.name
    end

    should "allow passing both a record and fields to it's initialize" do
      fake_record = FakeTestRecord.new(:name => 'test1')
      model = subject.new(fake_record, :name => 'test2')
      assert_equal 'test2', model.name
      assert_equal 'test2', fake_record.name
    end

  end

  class WithRecordClassSpyTests < UnitTests
    setup do
      @fake_records = [*1..2].map{ FakeTestRecord.new.tap(&:save!) }
      RecordClassSpy.fake_records = @fake_records
      @model_class.record_class RecordClassSpy
    end
    teardown do
      RecordClassSpy.fake_records = nil
    end

    should "call find on the record class using `find`" do
      fake_record = @fake_records.first
      model = subject.find(fake_record.id)
      assert_equal subject.new(fake_record), model
    end

    should "call all on the record class and map building instances using `all`" do
      exp = @fake_records.map{ |fake_record| subject.new(fake_record) }
      assert_equal exp, subject.all
    end

  end

  class InstanceTests < UnitTests
    desc "for a model instance"
    setup do
      @fake_record = FakeTestRecord.new
      @model = @model_class.new(@fake_record, :name => 'test', :active => true)
      @model.save
    end
    subject{ @model }

    should have_imeths :inspect

    should "return a readable inspect" do
      object_hex = (subject.object_id << 1).to_s(16)
      expected = "#<#{subject.class}:0x#{object_hex} @active=true " \
                 "@id=#{subject.id} @name=\"test\">"
      assert_equal expected, subject.inspect
    end

    should "be comparable" do
      same_model = @model_class.new(@fake_record)
      assert_equal same_model, subject
      other_model = @model_class.new.tap(&:save)
      assert_not_equal other_model, subject
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
    attribute :name,   :string
    attribute :active, :boolean
  end

  class RecordClassSpy
    include MR::Record

    def self.fake_records=(values)
      @fake_records = values
    end

    def self.find(id)
      @fake_records.detect{ |fake_record| fake_record.id == id }
    end

    def self.all
      @fake_records
    end
  end

end
