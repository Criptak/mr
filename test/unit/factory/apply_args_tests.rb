require 'assert'
require 'mr/factory/apply_args'

module MR::Factory::ApplyArgs

  class UnitTests < Assert::Context
    desc "MR::Factory::ApplyArgs"
    setup do
      @class = Class.new do
        include MR::Factory::ApplyArgs
        public :hash_key?, :deep_merge, :stringify_hash
      end
      @instance = @class.new
    end
    subject{ @instance }

    should have_imeths :apply_args

    should "raise a not implemented error unless " \
           "`apply_args_to_associations!` is overwritten" do
      assert_raises(NotImplementedError){ subject.apply_args('object') }
    end

    should "return if a value in a hash is a `Hash` using `hash_key?`" do
      args = { 'is-a-hash' => {}, 'isnt-a-hash' => 'nope'  }
      assert_true  subject.hash_key?(args, 'is-a-hash')
      assert_false subject.hash_key?(args, 'isnt-a-hash')
    end

    should "deep merge two hashes using `deep_merge`" do
      hash1 = {
        :bool => true,
        :int  => 1,
        :hash => { :a => 1 }
      }
      hash2 = {
        :str  => 'test',
        :int  => 2,
        :hash => { :b => 2 }
      }
      merged_hash = subject.deep_merge(hash1, hash2)
      expected = {
        :bool => true,
        :str  => 'test',
        :int  => 2,
        :hash => { :a => 1, :b => 2 }
      }
      assert_equal expected, merged_hash
    end

    should "stringify a hash using `stringify_hash`" do
      hash = {
        :str  => 'test',
        :hash => { :a => 1, :b => 2 }
      }
      expected = {
        'str'  => 'test',
        'hash' => { 'a' => 1, 'b' => 2 }
      }
      assert_equal expected, subject.stringify_hash(hash)
    end

    should "raise an argument error if `stringify_hash` isn't passed a hash" do
      assert_raises(ArgumentError){ subject.stringify_hash('test') }
    end

  end

  class WithApplyArgsToAssociationsTests < UnitTests
    desc "with `apply_args_to_associations!` defined"
    setup do
      @class.class_eval do

        attr_reader :apply_to_associations_calls

        def apply_args_to_associations!(object, args)
          @apply_to_associations_calls ||= []
          @apply_to_associations_calls << Call.new(object, args)
        end

      end
      @object = TestObject.new
    end

    should "write a hash's values to an object using `apply_args`" do
      subject.apply_args(@object, :name => 'Test', :active => true)
      assert_equal 'Test', @object.name
      assert_equal true,   @object.active
    end

    should "allow passing proc values in the hash using `apply_args`" do
      object = TestObject.new
      subject.apply_args(@object, :name => proc{ 'Test' })
      assert_equal 'Test', @object.name
    end

    should "call `apply_args_to_associations!` with " \
           "the object and args using `apply_args`" do
      args = { :name => 'Test' }
      subject.apply_args(@object, args)
      call = subject.apply_to_associations_calls.first
      assert_equal @object, call.object
      assert_equal args,    call.args
    end

  end

  class WithDestructiveApplyArgsToAssociationsTests < UnitTests
    desc "with desctructive `apply_args_to_associations!`"
    setup do
      @class.class_eval do

        def apply_args_to_associations!(object, args)
          args.clear
        end

      end
      @object = TestObject.new
    end

    should "not modify hashes passed to `apply_args`" do
      args = { :name => 'Test' }
      subject.apply_args(@object, args)
      assert_not_empty args
      assert_not_equal 'Test', @object.name
    end

  end

  TestObject = Struct.new(:name, :active)

  Call = Struct.new(:object, :args)

end
