require 'assert'
require 'mr/fake_record_associations'

require 'test/support/test_models'

class MR::FakeRecord::Association

  class BaseTests < Assert::Context
    desc "MR::FakeRecord::Association"
    setup do
      record_class = Class.new do
        attr_accessor :user, :created_by_id
        attr_accessor :users
      end
      @record = record_class.new
      @association = MR::FakeRecord::Association.new(:user, 'TestFakeRecord')
    end
    subject{ @association }

    should have_readers :name, :ivar_name, :fake_record_class_name
    should have_imeths :type, :read, :write, :define_methods

    should "know it's name, ivar name and fake record class name" do
      assert_equal :user,            subject.name
      assert_equal '@user',          subject.ivar_name
      assert_equal 'TestFakeRecord', subject.fake_record_class_name
    end

    should "raise a NotImplementedError with #type" do
      assert_raises(NotImplementedError){ subject.type }
    end

    should "read and write the record's ivar with #read and #write" do
      associated_record = TestFakeRecord.new
      assert_nothing_raised{ subject.write(@record, associated_record) }
      assert_equal associated_record, @record.user
      assert_equal associated_record, subject.read(@record)
    end

    should "define a reader and writer method with #define_methods" do
      @my_class = Class.new
      subject.define_methods(@my_class)
      assert_respond_to :user, @my_class.new
      assert_respond_to :user=, @my_class.new
    end

  end

  class BelongsToTests < BaseTests
    desc "BelongsTo"
    setup do
      @belongs_to = MR::FakeRecord::BelongsTo.new(:user, 'TestFakeRecord', {
        :foreign_key => :created_by_id
      })
    end
    subject{ @belongs_to }

    should have_readers :foreign_key

    should "know it's foreign_key" do
      assert_equal "created_by_id", subject.foreign_key
      belongs_to = MR::FakeRecord::BelongsTo.new(:user, 'TestFakeRecord')
      assert_equal "user_id", belongs_to.foreign_key
    end

    should "return belongs_to with #type" do
      assert_equal :belongs_to, subject.type
    end

    should "set the created_by_id when setting the user belongs_to association" do
      associated_record = TestFakeRecord.new.tap{ |r| r.save! }
      assert_nil @record.user
      assert_nil @record.created_by_id
      subject.write(@record, associated_record)
      assert_equal associated_record,    @record.user
      assert_equal associated_record.id, @record.created_by_id
    end

  end

  class HasManyTests < BaseTests
    desc "HasMany"
    setup do
      @has_many = MR::FakeRecord::HasMany.new(:users, 'TestFakeRecord')
    end
    subject{ @has_many }

    should "return has_many with #type" do
      assert_equal :has_many, subject.type
    end

    should "default the value to an empty array with #read" do
      assert_equal [], subject.read(@record)
      assert_equal [], @record.users
    end

    should "allow writing a non-array value with #write" do
      associated_record = TestFakeRecord.new.tap{ |r| r.save! }
      assert_nothing_raised{ subject.write(@record, associated_record) }
      assert_equal [ associated_record ], @record.users
    end

  end

  class HasOneTests < BaseTests
    desc "HasOne"
    setup do
      @has_one = MR::FakeRecord::HasOne.new(:user, 'TestFakeRecord')
    end
    subject{ @has_one }

    should "return has_one with #type" do
      assert_equal :has_one, subject.type
    end

  end

end
