require 'assert'
require 'mr/fake_record/persistence'

module MR::FakeRecord::Persistence

  class UnitTests < Assert::Context
    desc "MR::FakeRecord::Persistence"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord::Persistence
        attribute :name,   :string
        attribute :active, :boolean
      end
    end
    subject{ @fake_record_class }

    should have_imeths :transaction, :human_attribute_name

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

    should "return the default option using `human_attribute_name`" do
      attribute_name = subject.human_attribute_name(:name, :default => "Name")
      assert_equal "Name", attribute_name
    end

    should "return the last part of the attribute name as a string when " \
           "no default option is passed using `human_attribute_name`" do
      attribute_name = subject.human_attribute_name('a.i18n.translation.name')
      assert_equal "name", attribute_name
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
    should have_imeths :save_called, :reset_save_called

    should "default it's save called to `false`" do
      assert_false subject.save_called
    end

    should "not raise an invalid record error using `save!` when its valid" do
      subject.errors.clear
      assert_nothing_raised{ subject.save! }
    end

    should "raise a invalid record error using `save!` when its invalid" do
      subject.errors.add(:name, 'invalid')
      exception = nil
      begin; subject.save!; rescue StandardError => exception; end

      assert_instance_of ActiveRecord::RecordInvalid, exception
      assert_equal 'Validation failed: Name invalid', exception.message
    end

    should "set it's id when saved for the first time using `save!`" do
      assert_nil subject.id
      subject.save!
      id = subject.id
      assert_equal @primary_key, id
      subject.save!
      assert_same id, subject.id
    end

    should "copy it's attributes to it's saved attributes using `save!`" do
      expected = { 'id' => @primary_key, 'name' => nil, 'active' => nil }
      assert_not_equal expected, subject.saved_attributes
      subject.save!
      assert_equal expected, subject.saved_attributes
    end

    should "set its save called to `true` using `save!`" do
      subject.save!
      assert_true subject.save_called
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

    should "allow resetting save called to `false` using `reset_save_called`" do
      subject.save!
      subject.reset_save_called
      assert_false subject.save_called
    end

  end

  class WithTimestampsTests < UnitTests
    desc "with timestamp attributes"
    setup do
      @default_timezone = ActiveRecord::Base.default_timezone
      @current_time = Time.now
      Time.stubs(:now).returns(@current_time)
      @fake_record_class.attribute :created_at, :datetime
      @fake_record_class.attribute :updated_at, :datetime
      @fake_record = @fake_record_class.new
    end
    teardown do
      ActiveRecord::Base.default_timezone = @default_timezone
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

    should "not overwrite updated at when its manually set" do
      expected = Time.local(2013, 1, 1)
      subject.updated_at = expected
      subject.save!
      assert_equal expected, subject.updated_at
      subject.save!
      assert_equal @current_time, subject.updated_at
    end

    should "use ActiveRecord's configured default timezone" do
      ActiveRecord::Base.default_timezone = :local
      subject.save!
      assert_equal Time.now.zone, subject.updated_at.zone
      ActiveRecord::Base.default_timezone = :utc
      subject.save!
      assert_equal Time.now.utc.zone, subject.updated_at.zone
    end

  end

end
