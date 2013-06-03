require 'assert'
require 'mr/fake_record'
require 'ns-options/assert_macros'
require 'test/support/ar_models'
require 'thread'

module MR::FakeRecord

  class BaseTests < Assert::Context
    desc "FakeRecord"
    setup do
      @fake_user_record = FakeUserRecord.new
    end
    subject{ @fake_user_record }

    # check that it has accessors for it's attributes methods
    should have_accessors :id, :name, :email, :active, :area_id
    # check that it has accessors for it's belongs_to associations
    should have_accessors :area
    # check that it has accessors for it's has_many associations
    should have_accessors :comments

    should have_cmeths :attributes, :belongs_to, :has_many, :mr_id_provider

    should have_imeths :attributes, :attributes=, :new_record?, :valid?
    should have_imeths :save!, :destroy, :transaction
    should have_imeths :saved_attributes, :destroyed?

    should "set an area_id when setting the area belongs_to association" do
      assert_nil subject.area
      assert_nil subject.area_id

      mock_area = mock("Area")
      mock_area.stubs(:id).returns(1)

      subject.area = mock_area

      assert_equal mock_area,    subject.area
      assert_equal mock_area.id, subject.area_id
    end

    should "default a has_many association to an empty array" do
      assert_equal [], subject.comments
    end

    should "allow reading and writing multiple attributes" do
      assert_nothing_raised do
        subject.attributes = {
          :name   => 'Joe Test',
          :email  => 'joe.test@example.com',
          :active => true
        }
      end

      expected = {
        :id         => nil,
        :name       => 'Joe Test',
        :email      => 'joe.test@example.com',
        :active     => true,
        :area_id    => nil,
        :created_at => nil,
        :updated_at => nil
      }
      assert_equal expected, subject.attributes
    end

    should "store the attributes that were last saved and " \
           "default id, created_at and updated_at" do
      subject.attributes = {
        :name   => 'Joe Test',
        :email  => 'joe.test@example.com',
        :active => true
      }
      subject.save!

      saved = subject.saved_attributes
      assert_not_nil saved[:id]
      assert_equal 'Joe Test',             saved[:name]
      assert_equal 'joe.test@example.com', saved[:email]
      assert_equal true,                   saved[:active]
      assert_equal nil,                    saved[:area_id]
      assert_instance_of Time,             saved[:created_at]
      assert_instance_of Time,             saved[:updated_at]
    end

    should "set a flag when it's destroyed" do
      assert_equal false, subject.destroyed?
      subject.destroy
      assert_equal true, subject.destroyed?
    end

  end

  class DefaultIdTests < BaseTests
    desc "default ID generation"
    setup do
      @provider = FakeUserRecord.mr_id_provider
      @started_at = @provider.current
    end
    subject{ @provider }

    should have_readers :mutex, :current

    should "store a mutex and it's the current id" do
      assert_instance_of Mutex,  subject.mutex
      assert_instance_of Fixnum, subject.current
    end

    should "increated the counter and return the value with #next" do
      next_id = subject.next
      assert_equal @started_at + 1, next_id
      assert_equal @started_at + 1, subject.current
    end

    should "generate ids for each new record created" do
      threads = [*(0..2)].map do |n|
        Thread.new do
          Thread.current['fake_user'] = FakeUserRecord.new.tap{|u| u.save! }
        end
      end
      fake_users = threads.map do |thread|
        thread.join
        thread['fake_user']
      end
      fake_users.each_with_index do |fake_user, n|
        expected_id = @started_at + (n + 1)
        assert_equal expected_id, fake_user.id
      end
    end

  end

  class ConfigTests < BaseTests
    include NsOptions::AssertMacros

    desc "fr_config"
    setup do
      @config = FakeUserRecord.fr_config
    end
    subject{ @config }

    should have_option :attributes, Set, :default => []

  end

end
