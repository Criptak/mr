require 'assert'
require 'mr/type_converter'

class MR::TypeConverter

  class UnitTests < Assert::Context
    desc "MR::TypeConverter"
    setup do
      @type_converter = MR::TypeConverter.new
    end
    subject{ @type_converter }

    should have_imeths :convert
    should have_cmeths :valid?

    should "return whether a type is true or false" do
      assert_equal true,  MR::TypeConverter.valid?(:string)
      assert_equal false, MR::TypeConverter.valid?(:invalid)
    end

    should "return `nil` when `convert` is passed a `nil` value" do
      assert_nil subject.convert(nil, :string)
    end

    should "properly type cast boolean values using `convert`" do
      assert_equal true,  subject.convert('true', :boolean)
      assert_equal true,  subject.convert('1', :boolean)
      assert_equal true,  subject.convert('t', :boolean)
      assert_equal true,  subject.convert('T', :boolean)

      assert_equal false, subject.convert('false', :boolean)
      assert_equal false, subject.convert('0', :boolean)
      assert_equal false, subject.convert('f', :boolean)
      assert_equal false, subject.convert('F', :boolean)
    end

    should "properly type cast binary values using `convert`" do
      binary_string = "\000\001\002\003\004"
      assert_equal binary_string, subject.convert(binary_string, :binary)
    end

    should "properly type cast date values using `convert`" do
      expected = Date.parse('2013-11-18')
      assert_equal expected, subject.convert('2013-11-18', :date)
    end

    should "properly type cast datetime values using `convert`" do
      expected = Time.parse('2013-11-18 21:29:10')
      assert_equal expected, subject.convert('2013-11-18 21:29:10', :datetime)
    end

    should "properly type cast decimal values using `convert`" do
      expected = BigDecimal.new('33.4755926134924')
      assert_equal expected, subject.convert('33.4755926134924', :decimal)
    end

    should "properly type cast float values using `convert`" do
      assert_equal 6.1374, subject.convert('6.1374', :float)
    end

    should "properly type cast integer values using `convert`" do
      assert_equal 100, subject.convert('100', :integer)
    end

    should "properly type cast primary key values using `convert`" do
      assert_equal 100, subject.convert('100', :primary_key)
    end

    should "properly type cast string values using `convert`" do
      assert_equal 'string', subject.convert('string', :string)
    end

    should "properly type cast text values using `convert`" do
      assert_equal 'text', subject.convert('text', :text)
    end

    should "properly type cast time values using `read`" do
      expected = Time.parse('2000-01-01 21:29:10.905011')
      assert_equal expected, subject.convert('21:29:10.905011', :time)
    end

    should "properly type cast timestamp values using `read`" do
      expected = Time.parse('2013-11-18 22:10:36.660846')
      assert_equal expected, subject.convert('2013-11-18 22:10:36.660846', :timestamp)
    end

    should "allow using a custom ActiveRecord column class" do
      type_converter = MR::TypeConverter.new(FakeARColumn)
      assert_equal 'test',           type_converter.convert('test', :string)
      assert_equal 'fake-ar-column', type_converter.convert('test', :datetime)
    end

    should "raise an ArgumentError when passed an invalid type" do
      assert_raises(ArgumentError){ subject.convert('test', :invalid) }
    end

  end

  module FakeARColumn
    def self.method_missing(method, *args, &block)
      'fake-ar-column'
    end
  end

end
