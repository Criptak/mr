require 'assert'
require 'mr/factory'

require 'thread'
require 'mr/type_converter'

module MR::Factory

  class UnitTests < Assert::Context
    desc "MR::Factory"
    setup do
      @type_converter = MR::TypeConverter.new
    end
    subject{ MR::Factory }

    should have_imeths :new
    should have_imeths :primary_key, :decimal, :timestamp
    should have_imeths :type_converter

    should "extend `Assert::Factory`" do
      assert_respond_to :integer,   subject
      assert_respond_to :float,     subject
      assert_respond_to :date,      subject
      assert_respond_to :datetime,  subject
      assert_respond_to :time,      subject
      assert_respond_to :string,    subject
      assert_respond_to :text,      subject
      assert_respond_to :slug,      subject
      assert_respond_to :hex,       subject
      assert_respond_to :binary,    subject
      assert_respond_to :file_name, subject
      assert_respond_to :dir_path,  subject
      assert_respond_to :file_path, subject
      assert_respond_to :boolean,   subject
    end

    should "return unique integers for an identifier using `primary_key`" do
      assert_equal 1, subject.primary_key('test')
      assert_equal 2, subject.primary_key('test')
      assert_equal 1, subject.primary_key('other')
    end

    should "return a random decimal using `decimal`" do
      assert_kind_of BigDecimal, subject.decimal
    end

    should "allow passing a maximum value using `decimal`" do
      decimal = subject.decimal(2)
      assert decimal <= 2
      assert decimal >= 1
    end

    should "return a random time object using `timestamp`" do
      assert_kind_of Time, subject.timestamp
    end

    should "return an instance of MR::TypeConverter using `type_converter`" do
      assert_instance_of MR::TypeConverter, subject.type_converter
    end

  end

  class PrimaryKeyProviderTests < UnitTests
    desc "PrimaryKeyProvider"
    setup do
      @provider   = PrimaryKeyProvider.new
      @started_at = @provider.current
    end
    subject{ @provider }

    should have_readers :mutex, :current

    should "store a mutex and it's current value" do
      assert_instance_of Mutex,  subject.mutex
      assert_instance_of Fixnum, subject.current
    end

    should "increated the counter and return the value using `next`" do
      next_id = subject.next
      assert_equal @started_at + 1, next_id
      assert_equal @started_at + 1, subject.current
    end

    should "lock getting the next value using `next`" do
      threads = [*0..2].map do |n|
        Thread.new{ Thread.current['id'] = @provider.next }
      end
      primary_keys = threads.map{ |thread| thread.join; thread['id'] }
      assert_includes 1, primary_keys
      assert_includes 2, primary_keys
    end

  end

end
