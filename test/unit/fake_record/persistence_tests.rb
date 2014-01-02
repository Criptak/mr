require 'assert'
require 'mr/fake_record/persistence'

module MR::FakeRecord::Persistence

  class UnitTests < Assert::Context
    desc "MR::FakeRecord::Persistence"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord::Persistence
      end
    end
    subject{ @fake_record_class }

    should have_imeths :transaction

    should "include FakeRecord Attributes mixin" do
      assert_includes MR::FakeRecord::Attributes, subject
    end

    should "add an id primary key attribute" do
      attribute = subject.attributes.find(:id)
      assert_not_nil attribute
      assert attribute.primary
    end

    should "yield to any block passed to `transaction`" do
      called = nil
      subject.transaction{ called = true }
      assert called
    end

  end

  class InstanceTests < UnitTests
    desc "for a fake record instance"
    setup do
      @primary_key = 1
      MR::Factory.stubs(:primary_key).tap do |s|
        s.with(@fake_record_class)
        s.returns(@primary_key)
      end
      @fake_record = @fake_record_class.new
    end
    teardown do
      MR::Factory.unstub(:primary_key)
    end
    subject{ @fake_record }

    should have_accessors :id
    should have_imeths :save!, :destroy
    should have_imeths :transaction
    should have_imeths :new_record?, :destroyed?
    should have_imeths :errors, :valid?

    should "set it's id when saved for the first time using `save!`" do
      assert_nil subject.id
      subject.save!
      id = subject.id
      assert_equal @primary_key, id
      subject.save!
      assert_same id, subject.id
    end

    should "copy it's saved attributes to it's previous attributes using `save!`" do
      expected = { 'test' => true }
      subject.saved_attributes = expected
      assert_not_equal expected, subject.previous_attributes
      subject.save!
      assert_equal expected, subject.previous_attributes
    end

    should "copy set it's attributes to it's saved attributes using `save!`" do
      expected = { 'id' => @primary_key }
      assert_not_equal expected, subject.saved_attributes
      subject.save!
      assert_equal expected, subject.saved_attributes
    end

    should "mark the fake record as destroyed using `destroy`" do
      assert_not subject.destroyed?
      subject.destroy
      assert subject.destroyed?
    end

    should "yield to any block passed to `transaction`" do
      called = nil
      subject.transaction{ called = true }
      assert called
    end

    should "return whether a record has been saved or not using `new_record?`" do
      assert subject.new_record?
      subject.save!
      assert_not subject.new_record?
    end

    should "return an instance of ActiveModel::Errors using `errors`" do
      assert_instance_of ActiveModel::Errors, subject.errors
    end

    should "return whether a record has any errors or not using `valid?`" do
      subject.errors.clear
      assert subject.valid?
      subject.errors.add(:test, 'invalid')
      assert_not subject.valid?
    end

  end

  class WithTimestampsTests < UnitTests
    desc "with timestamp attributes"
    setup do
      @current_time = Time.now
      Time.stubs(:now).returns(@current_time)
      @fake_record_class.attribute :created_at, :datetime
      @fake_record_class.attribute :updated_at, :datetime
      @fake_record = @fake_record_class.new
    end
    teardown do
      Time.unstub(:now)
    end
    subject{ @fake_record }

    should "set it's created at when saved for the first time using `save!`" do
      assert_nil subject.created_at
      subject.save!
      created_at = subject.created_at
      assert_equal @current_time, created_at
      subject.save!
      assert_same created_at, subject.created_at
    end

    should "set it's updated at everytime `save!` is called" do
      assert_nil subject.updated_at
      subject.save!
      updated_at = subject.updated_at
      assert_equal @current_time, updated_at
      new_time = Time.local(2013, 1, 1)
      Time.stubs(:now).returns(new_time)
      subject.save!
      assert_equal new_time, subject.updated_at
    end

  end

end
