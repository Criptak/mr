require 'assert'
require 'mr/read_model'

module MR::ReadModel

  class MyModel
    include MR::ReadModel
  end

  class BaseTests < Assert::Context
    desc "MR::ReadModel"
    setup do
      @record = FakeUserRecord.new({
        :name   => 'Joe Test',
        :active => true
      })
      @read_model = MyModel.new(@record)
    end
    subject{ @read_model }

    should "include MR::ReadModel" do
      assert_includes MR::ReadModel, MyModel.included_modules
    end

    should "raise an InvalidRecordError when built without a record" do
      assert_raises MR::InvalidRecordError do
        MyModel.new({ :name => 'test' })
      end
    end

    should "respond to it's record's attributes" do
      assert subject.respond_to?(:name)
      assert subject.respond_to?(:active)
      assert_equal 'Joe Test', subject.name
      assert_equal true,       subject.active
    end

  end

  class GeneratorTests < BaseTests
    desc "generator"
    setup do
      @read_model_class = MR::ReadModel.new
    end
    subject{ @read_model_class }

    should "generate a class that includes MR::ReadModel" do
      assert_kind_of Class, subject
      assert_includes MR::ReadModel, subject.included_modules
    end

  end

end
