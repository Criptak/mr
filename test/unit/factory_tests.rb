require 'assert'
require 'mr/factory'
require 'thread'

require 'test/support/test_models'

module MR::Factory

  class BaseTests < Assert::Context
    desc "MR::Factory"
    subject{ MR::Factory }

    should have_imeths :new
    should have_imeths :primary_key, :integer, :float, :decimal
    should have_imeths :date, :datetime, :time, :timestamp
    should have_imeths :string, :text, :hex
    should have_imeths :boolean
    should have_imeths :binary

    should "return unique integers for an identifier with #primary_key" do
      threads = [*0..2].map do |n|
        Thread.new{ Thread.current['id'] = subject.primary_key('test') }
      end
      primary_keys = threads.map{ |thread| thread.join; thread['id'] }
      primary_keys.each_with_index do |primary_key, n|
        assert_equal n + 1, primary_key
      end
      assert_equal 1, subject.primary_key('not_test')
    end

    should "return a random Fixnum with #integer" do
      assert_instance_of Fixnum, subject.integer(10)
    end

    should "return a random Float with #float and #decimal" do
      assert_instance_of Float,  subject.float(10)
      assert_instance_of Float,  subject.decimal(10)
    end

    should "return a Date with #date" do
      returned_date = subject.date
      assert_instance_of Date, returned_date
      assert_same returned_date, subject.date
    end

    should "return a DateTime with #datetime" do
      returned_datetime = subject.datetime
      assert_instance_of DateTime, returned_datetime
      assert_same returned_datetime, subject.datetime
    end

    should "return a Time with #time" do
      returned_time = subject.time
      assert_instance_of Time, returned_time
      assert_same returned_time, subject.time
    end

    should "return a random a-z String with #string and #text" do
      string = subject.string(10)
      assert_instance_of String, string
      assert_match(/\A[a-z]{10}\Z/, string)

      text = subject.text(10)
      assert_instance_of String, text
      assert_match(/\A[a-z]{10}\Z/, text)
    end

    should "return a random hex String with #hex" do
      hex = subject.hex(10)
      assert_instance_of String, hex
      assert_match(/\A[0-9a-f]{10}\Z/, hex)
    end

    should "return a dasherized String with #slug" do
      slug = subject.slug(10)
      assert_instance_of String, slug
      assert_match(/\A[a-z]{4}-[a-z]{4}-[a-z]{2}\Z/, slug)
    end

    should "return true with #boolean" do
      assert_equal true, subject.boolean
    end

    should "return a string of bytes with #binary" do
      assert_instance_of String, subject.binary
    end

  end

  class PrimaryKeyProviderTests < BaseTests
    desc "PrimaryKeyProvider"
    setup do
      @provider   = PrimaryKeyProvider.new
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

  end

end
