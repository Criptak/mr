require 'assert'
require 'mr/fake_record_associations'

require 'mr/fake_record'

class MR::FakeRecord::AssociationOld

  class UnitTests < Assert::Context
    desc "MR::FakeRecord::AssociationOld"
    setup do
      record_class = Class.new do
        attr_accessor :user, :created_by_id
        attr_accessor :users
      end
      @record = record_class.new
      @association = MR::FakeRecord::AssociationOld.new(:user, {
        :class_name => FakeTestRecord.name
      })
    end
    subject{ @association }

    should have_readers :name, :options, :ivar_name, :fake_record_class_name
    should have_imeths :fake_record_class
    should have_imeths :read, :write, :define_methods
    should have_imeths :belongs_to?, :collection?, :reflection, :klass

    should "know it's name, ivar name and fake record class name" do
      assert_equal :user, subject.name
      assert_instance_of Hash, subject.options
      assert_equal '@user', subject.ivar_name
      assert_equal FakeTestRecord.name, subject.fake_record_class_name
    end

    should "return false with #belongs_to?" do
      assert_equal false, subject.belongs_to?
    end

    should "return false with #collection?" do
      assert_equal false, subject.collection?
    end

    should "return itself with #reflection" do
      assert_equal subject, subject.reflection
    end

    should "return it's fake record class with #klass" do
      assert_equal subject.fake_record_class, subject.klass
    end

    should "constantize the fake record class name and return it with #fake_record_class" do
      assert_equal FakeTestRecord, subject.fake_record_class
    end

    should "read and write the record's ivar with #read and #write" do
      associated_record = FakeTestRecord.new
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

  class BelongsToOldTests < UnitTests
    desc "BelongsToOld"
    setup do
      @belongs_to = MR::FakeRecord::BelongsToOld.new(:user, {
        :class_name  => FakeTestRecord.name,
        :foreign_key => :created_by_id
      })
    end
    subject{ @belongs_to }

    should have_readers :foreign_key

    should "be a kind of fake association" do
      assert subject.kind_of?(MR::FakeRecord::AssociationOld)
    end

    should "know it's foreign_key" do
      assert_equal "created_by_id", subject.foreign_key
      belongs_to = MR::FakeRecord::BelongsToOld.new(:user, {
        :class_name => 'FakeTestRecord'
      })
      assert_equal "user_id", belongs_to.foreign_key
    end

    should "return true with #belongs_to?" do
      assert_equal true, subject.belongs_to?
    end

    should "set the created_by_id when setting the user belongs_to association" do
      associated_record = FakeTestRecord.new.tap{ |r| r.save! }
      assert_nil @record.user
      assert_nil @record.created_by_id
      subject.write(@record, associated_record)
      assert_equal associated_record,    @record.user
      assert_equal associated_record.id, @record.created_by_id
    end

  end

  class HasManyOldTests < UnitTests
    desc "HasManyOld"
    setup do
      @has_many = MR::FakeRecord::HasManyOld.new(:users, {
        :class_name => FakeTestRecord.name
      })
    end
    subject{ @has_many }

    should "be a kind of fake association" do
      assert subject.kind_of?(MR::FakeRecord::AssociationOld)
    end

    should "return true with #collection?" do
      assert_equal true, subject.collection?
    end

    should "default the value to an empty array with #read" do
      assert_equal [], subject.read(@record)
      assert_equal [], @record.users
    end

    should "allow writing a non-array value with #write" do
      associated_record = FakeTestRecord.new.tap{ |r| r.save! }
      assert_nothing_raised{ subject.write(@record, associated_record) }
      assert_equal [ associated_record ], @record.users
    end

  end

  class HasOneOldTests < UnitTests
    desc "HasOneOld"
    setup do
      @has_one = MR::FakeRecord::HasOneOld.new(:user, {
        :class_name => FakeTestRecord.name
      })
    end
    subject{ @has_one }

    should "be a kind of fake association" do
      assert subject.kind_of?(MR::FakeRecord::AssociationOld)
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
  end

end
