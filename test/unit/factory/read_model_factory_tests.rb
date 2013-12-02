require 'assert'
require 'mr/factory/read_model_factory'

class MR::Factory::ReadModelFactory

  class UnitTests < Assert::Context
    desc "MR::Factory::ReadModelFactory"
    subject{ MR::Factory::ReadModelFactory }

    should "instance eval a block thats passed to it's `new`" do
      eval_scope = nil
      factory = subject.new(TestReadModel){ eval_scope = self }
      assert_equal factory, eval_scope
    end

    should "raise an ArgumentError if initialized without an MR::ReadModel" do
      assert_raises(ArgumentError){ subject.new('wrong') }
    end

  end

  class InstanceTests < UnitTests
    desc "instance"
    setup do
      @factory = MR::Factory::ReadModelFactory.new(TestReadModel)
    end
    subject{ @factory }

    should have_imeths :instance, :default_args

    should "allow reading and writing default args using `default_args`" do
      subject.default_args(:test => true)
      assert_equal({ 'test' => true }, subject.default_args)
    end

    should "return an instance of the read model using `instance`" do
      read_model = subject.instance
      assert_instance_of TestReadModel, read_model
      assert_kind_of String,    read_model.string
      assert_kind_of Integer,   read_model.integer
      assert_kind_of Float,     read_model.float
      assert_kind_of Time,      read_model.datetime
      assert_kind_of Time,      read_model.time
      assert_kind_of Date,      read_model.date
      assert_kind_of Integer,   read_model.primary_key
      assert_includes read_model.boolean.class, [ TrueClass, FalseClass ]
    end

    should "raise an ArgumentError if a non-Hash is passed to `default_args`" do
      assert_raises(ArgumentError){ subject.default_args('wrong') }
    end

  end

  class TestReadModel
    include MR::ReadModel

    field :string,      :string
    field :integer,     :integer
    field :float,       :float
    field :datetime,    :datetime
    field :time,        :time
    field :date,        :date
    field :boolean,     :boolean
    field :primary_key, :primary_key
  end

end
