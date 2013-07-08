require 'assert'
require 'mr/read_model'

require 'test/support/models/fake_user_record'

module MR::ReadModel

  class MyModel
    include MR::ReadModel

    def area_id
      super.to_i
    end
  end

  class BaseTests < Assert::Context
    desc "MR::ReadModel"
    setup do
      @record = FakeUserRecord.new({
        :name   => 'Joe Test',
        :active => true,
        :area_id => '1'
      })
      @read_model = MyModel.new(@record)
    end
    subject{ @read_model }

    should have_cmeths :read_model_interface_module

    should "include MR::ReadModel and it's interface module" do
      modules = MyModel.included_modules
      assert_includes MR::ReadModel::InstanceMethods, modules
      assert_includes MyModel.read_model_interface_module, modules
    end

    should "raise an InvalidRecordError when built without a record" do
      assert_raises MR::InvalidRecordError do
        MyModel.new('test')
      end
    end

    should "respond to it's record's attributes" do
      assert subject.respond_to?(:name)
      assert subject.respond_to?(:active)
      assert_equal 'Joe Test', subject.name
      assert_equal true,       subject.active
    end

  end

  class FromHashTests < BaseTests
    desc "build from a hash"
    setup do
      @read_model = MyModel.new({ :name => 'Joe Test', :active => true })
    end

    should "use the hash to build it's attributes" do
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
