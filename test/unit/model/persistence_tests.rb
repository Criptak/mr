require 'assert'
require 'mr/model/persistence'

require 'mr/fake_record'

module MR::Model::Persistence

  class UnitTests < Assert::Context
    desc "MR::Model::Persistence"
    setup do
      @model_class = Class.new do
        include MR::Model::Persistence
        record_class TestRecord
        def initialize(record); set_record record; end
      end
    end
    subject{ @model_class }

    should have_imeths :transaction

    should "call the record class's transaction method using `transaction`" do
      yielded = nil
      subject.transaction{ yielded = true }
      assert yielded
    end

  end

  class InstanceTests < UnitTests
    desc "for a model instance"
    setup do
      @record = TestRecord.new
      @model = @model_class.new(@record)
    end
    subject{ @model }

    should have_imeths :save, :destroy
    should have_imeths :transaction
    should have_imeths :errors, :valid?
    should have_imeths :new?, :destroyed?

    should "save the record using `save`" do
      assert @record.new_record?
      subject.save
      assert_not @record.new_record?
    end

    should "destroy the record using `destroy`" do
      assert_not @record.destroyed?
      subject.destroy
      assert @record.destroyed?
    end

    should "call the record's transaction method using `transaction`" do
      yielded = nil
      subject.transaction{ yielded = true }
      assert yielded
    end

    should "return the record's error messages using `errors`" do
      @record.errors.add(:name, 'something went wrong')
      assert_equal @record.errors.messages, subject.errors
    end

    should "call the record's valid method using `valid?`" do
      assert_equal true,  subject.valid?
      @record.errors.add(:name, 'something went wrong')
      assert_equal false, subject.valid?
    end

    should "call the record's new record method using `new?`" do
      assert_equal true,  subject.new?
      @record.save!
      assert_equal false, subject.new?
    end

    should "call the record's destroyed method using `destroyed?`" do
      @record.save!
      assert_equal false, subject.destroyed?
      @record.destroy
      assert_equal true,  subject.destroyed?
    end

    should "raise an invalid error when calling `save` with an invalid record" do
      @record.errors.add(:name, 'something went wrong')
      @record.errors.add(:name, 'another thing failed')
      @record.errors.add(:active, 'is not valid')

      exception = nil
      begin; subject.save; rescue StandardError => exception; end

      assert_instance_of MR::Model::InvalidError, exception
      assert_equal subject.errors, exception.errors
      description = subject.errors.map do |(attribute, messages)|
        messages.map{|message| "#{attribute.inspect} #{message}" }
      end.sort.join(', ')
      expected = "Invalid #{subject.class} couldn't be saved: #{description}"
      assert_equal expected, exception.message
    end

  end

  class TestRecord
    include MR::FakeRecord
  end

end
