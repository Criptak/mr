require 'assert'
require 'mr/read_model'

require 'mr/fake_record'

module MR::ReadModel

  class UnitTests < Assert::Context
    desc "MR::ReadModel"
    setup do
      @read_model_class = Class.new do
        include MR::ReadModel
        field :name, :string
      end
    end
    subject{ @read_model_class }

    should "default it's data when initialized" do
      read_model = subject.new
      assert_nil read_model.name
    end

    should "include the Data, Fields and Querying mixins" do
      assert_includes MR::ReadModel::Data, subject
      assert_includes MR::ReadModel::Fields, subject
      assert_includes MR::ReadModel::Querying, subject
    end

  end

  class InstanceTests < UnitTests
    desc "instance"
    setup do
      @data = { 'name' => 'Name' }
      @read_model = @read_model_class.new(@data)
    end
    subject{ @read_model }

    should "set it's data and allow reading from it" do
      assert_equal @data['name'], subject.name
    end

    should "be comparable" do
      equal_read_model = @read_model_class.new({ 'name' => 'Name' })
      assert_equal equal_read_model, subject
      not_equal_read_model = @read_model_class.new({ 'name' => 'Test' })
      assert_not_equal not_equal_read_model, subject
    end

    should "have a readable inspect" do
      object_hex = (subject.object_id << 1).to_s(16)
      values_inspect = @read_model_class.fields.map do |field|
        "#{field.ivar_name}=#{field.read(@data).inspect}"
      end.join(' ')
      expected = "#<#{@read_model_class}:0x#{object_hex} #{values_inspect}>"
      assert_equal expected, subject.inspect
    end

  end

  class FakeRecordTests < InstanceTests
    desc "with a fake record as data"
    setup do
      @fake_record = FakeTestRecord.new(:name => 'Name')
      @read_model = @read_model_class.new(@fake_record)
    end

    should "set allow reading from the fake record" do
      assert_equal @data['name'], subject.name
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
    attribute :name, :string

    def [](attribute_name); self.send(attribute_name); end
  end

end
