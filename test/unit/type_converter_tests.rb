require 'assert'
require 'mr/type_converter'

class MR::TypeConverter

  class UnitTests < Assert::Context
    desc "MR::TypeConverter"
    setup do
      @type_converter = MR::TypeConverter.new
    end
    subject{ @type_converter }

    should have_imeths :binary, :boolean
    should have_imeths :date, :datetime, :timestamp
    should have_imeths :decimal, :float
    should have_imeths :integer, :primary_key
    should have_imeths :string, :text, :slug, :hex, :file_name, :dir_path
    should have_imeths :file_path, :path, :url, :email
    should have_imeths :time
    should have_cmeths :valid?

    should "return whether a type is valid" do
      assert_equal true,  MR::TypeConverter.valid?(:string)
      assert_equal false, MR::TypeConverter.valid?(:invalid)
    end

    should "properly type cast binary values using `binary`" do
      binary_string = "\000\001\002\003\004"
      assert_equal binary_string, subject.binary(binary_string)
    end

    should "return `nil` when `binary` is passed a `nil` value" do
      assert_nil subject.binary(nil)
    end

    should "properly type cast boolean values using `boolean`" do
      assert_equal true,  subject.boolean('true')
      assert_equal true,  subject.boolean('1')
      assert_equal true,  subject.boolean('t')
      assert_equal true,  subject.boolean('T')

      assert_equal false, subject.boolean('false')
      assert_equal false, subject.boolean('0')
      assert_equal false, subject.boolean('f')
      assert_equal false, subject.boolean('F')
    end

    should "return `nil` when `boolean` is passed a `nil` value" do
      assert_nil subject.boolean(nil)
    end

    should "properly type cast date values using `date`" do
      expected = Date.parse('2013-11-18')
      assert_equal expected, subject.date('2013-11-18')
    end

    should "return `nil` when `date` is passed a `nil` value" do
      assert_nil subject.date(nil)
    end

    should "properly type cast datetime values using `datetime`" do
      expected = Time.parse('2013-11-18 21:29:10')
      assert_equal expected, subject.datetime('2013-11-18 21:29:10')
    end

    should "return `nil` when `datetime` is passed a `nil` value" do
      assert_nil subject.datetime(nil)
    end

    should "properly type cast decimal values using `decimal`" do
      expected = BigDecimal.new('33.4755926134924')
      assert_equal expected, subject.decimal('33.4755926134924')
    end

    should "return `nil` when `decimal` is passed a `nil` value" do
      assert_nil subject.decimal(nil)
    end

    should "properly type cast dir path values using `dir_path`" do
      assert_equal 'a/path', subject.dir_path('a/path')
    end

    should "return `nil` when `dir_path` is passed a `nil` value" do
      assert_nil subject.dir_path(nil)
    end

    should "properly type cast email values using `email`" do
      assert_equal 'email@example.com', subject.email('email@example.com')
    end

    should "return `nil` when `email` is passed a `nil` value" do
      assert_nil subject.email(nil)
    end

    should "properly type cast file name values using `file_name`" do
      assert_equal 'file.txt', subject.file_name('file.txt')
    end

    should "return `nil` when `file_name` is passed a `nil` value" do
      assert_nil subject.file_name(nil)
    end

    should "properly type cast float values using `float`" do
      assert_equal 6.1374, subject.float('6.1374')
    end

    should "return `nil` when `float` is passed a `nil` value" do
      assert_nil subject.float(nil)
    end

    should "properly type cast hex values using `hex`" do
      assert_equal '1a2b3c4d', subject.hex('1a2b3c4d')
    end

    should "return `nil` when `hex` is passed a `nil` value" do
      assert_nil subject.hex(nil)
    end

    should "properly type cast integer values using `integer`" do
      assert_equal 100, subject.integer('100')
    end

    should "return `nil` when `integer` is passed a `nil` value" do
      assert_nil subject.integer(nil)
    end

    should "properly type cast path values using `path`" do
      assert_equal 'a/path', subject.path('a/path')
    end

    should "return `nil` when `path` is passed a `nil` value" do
      assert_nil subject.path(nil)
    end

    should "properly type cast primary key values using `convert`" do
      assert_equal 100, subject.primary_key('100')
    end

    should "return `nil` when `primary_key` is passed a `nil` value" do
      assert_nil subject.primary_key(nil)
    end

    should "properly type cast slug values using `slug`" do
      assert_equal 'a-slug', subject.slug('a-slug')
    end

    should "return `nil` when `slug` is passed a `nil` value" do
      assert_nil subject.slug(nil)
    end

    should "properly type cast string values using `string`" do
      assert_equal 'string', subject.string('string')
    end

    should "return `nil` when `string` is passed a `nil` value" do
      assert_nil subject.string(nil)
    end

    should "properly type cast text values using `text`" do
      assert_equal 'text', subject.text('text')
    end

    should "return `nil` when `text` is passed a `nil` value" do
      assert_nil subject.text(nil)
    end

    should "properly type cast time values using `time`" do
      expected = Time.parse('2000-01-01 21:29:10.905011')
      assert_equal expected, subject.time('21:29:10.905011')
    end

    should "return `nil` when `time` is passed a `nil` value" do
      assert_nil subject.time(nil)
    end

    should "properly type cast timestamp values using `timestamp`" do
      expected = Time.parse('2013-11-18 22:10:36.660846')
      assert_equal expected, subject.timestamp('2013-11-18 22:10:36.660846')
    end

    should "return `nil` when `timestamp` is passed a `nil` value" do
      assert_nil subject.timestamp(nil)
    end

    should "properly type cast url values using `url`" do
      assert_equal 'http://example.com/url', subject.url('http://example.com/url')
    end

    should "return `nil` when `url` is passed a `nil` value" do
      assert_nil subject.url(nil)
    end

    should "allow using a custom ActiveRecord column class" do
      type_converter = MR::TypeConverter.new(FakeARColumn)
      assert_equal 'test',           type_converter.string('test')
      assert_equal 'fake-ar-column', type_converter.datetime('test')
    end

  end

  module FakeARColumn
    def self.method_missing(method, *args, &block)
      'fake-ar-column'
    end
  end

end
