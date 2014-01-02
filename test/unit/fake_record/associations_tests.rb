require 'assert'
require 'mr/fake_record/associations'

require 'mr/fake_record'

module MR::FakeRecord::Associations

  class UnitTests < Assert::Context
    desc "MR::FakeRecord::Associations"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord::Associations
        attribute :test_id,     :integer
        attribute :parent_type, :string
        attribute :parent_id,   :integer
      end
    end
    subject{ @fake_record_class }

    should have_imeths :reflections, :reflect_on_all_associations
    should have_imeths :belongs_to, :polymorphic_belongs_to
    should have_imeths :has_one, :has_many

    should "include FakeRecord Attributes mixin" do
      assert_includes MR::FakeRecord::Attributes, subject
    end

    should "return an instance of a ReflectionSet using `reflections`" do
      reflections = subject.reflections
      assert_instance_of MR::FakeRecord::ReflectionSet, reflections
      assert_same reflections, subject.reflections
    end

    should "add belongs to methods using `belongs_to`" do
      subject.belongs_to :test, FakeTestRecord.to_s
      fake_record = subject.new

      assert_respond_to :test,  fake_record
      assert_respond_to :test=, fake_record
      fake_test_record = FakeTestRecord.new.tap(&:save!)
      fake_record.test = fake_test_record
      assert_equal fake_test_record, fake_record.test
    end

    should "add polymorphic belongs to methods using `polymorphic_belongs_to`" do
      subject.polymorphic_belongs_to :parent
      fake_record = subject.new

      assert_respond_to :parent,  fake_record
      assert_respond_to :parent=, fake_record
      fake_test_record = FakeTestRecord.new.tap(&:save!)
      fake_record.parent = fake_test_record
      assert_equal fake_test_record, fake_record.parent
    end

    should "add has one methods using `has_one`" do
      subject.has_one :test, FakeTestRecord.to_s
      fake_record = subject.new

      assert_respond_to :test,  fake_record
      assert_respond_to :test=, fake_record
      fake_test_record = FakeTestRecord.new.tap(&:save!)
      fake_record.test = fake_test_record
      assert_equal fake_test_record, fake_record.test
    end

    should "add has many methods using `has_many`" do
      subject.has_many :tests, FakeTestRecord.to_s
      fake_record = subject.new

      assert_respond_to :tests,  fake_record
      assert_respond_to :tests=, fake_record
      fake_test_record = FakeTestRecord.new.tap(&:save!)
      fake_record.tests = [ fake_test_record ]
      assert_equal [ fake_test_record ], fake_record.tests
    end

  end

  class WithAssociationsTests < UnitTests
    desc "with associations"
    setup do
      @fake_record_class.belongs_to :belongs_to_test, FakeTestRecord.to_s
      @fake_record_class.polymorphic_belongs_to :poly_test
      @fake_record_class.has_one :has_one_test, FakeTestRecord.to_s
      @fake_record_class.has_many :has_many_test, FakeTestRecord.to_s
    end

    should "return all reflections using `reflect_on_all_associations`" do
      reflections = subject.reflect_on_all_associations
      assert_equal 4, reflections.size
      reflections.each{ |r| assert_instance_of MR::FakeRecord::Reflection, r }
      expected = [ :belongs_to_test, :poly_test, :has_one_test, :has_many_test ]
      assert_equal expected, reflections.map(&:name)
    end

    should "only return specific kinds of reflections when a type is passed " \
           "to `reflect_on_all_associations`" do
      reflections = subject.reflect_on_all_associations(:belongs_to)
      assert_equal [ :belongs_to_test, :poly_test ], reflections.map(&:name)
      reflections = subject.reflect_on_all_associations(:has_many)
      assert_equal [ :has_many_test ], reflections.map(&:name)
      reflections = subject.reflect_on_all_associations(:has_one)
      assert_equal [ :has_one_test ], reflections.map(&:name)
    end

  end

  class InstanceTests < UnitTests
    desc "for a fake record instance"
    setup do
      @fake_record_class.belongs_to :test, FakeTestRecord.to_s
      @fake_record = @fake_record_class.new
    end
    subject{ @fake_record }

    should have_imeths :association

    should "return a matching association using `association`" do
      association = subject.association(:test)
      reflection  = @fake_record_class.reflections.find(:test)
      assert_equal reflection.macro, association.reflection.macro
      assert_equal reflection.name,  association.reflection.name
    end

  end

  class ReflectionSetTests < UnitTests
    desc "ReflectionSet"
    setup do
      @association_set = MR::FakeRecord::ReflectionSet.new
    end
    subject{ @association_set }

    should have_imeths :belongs_to, :has_one, :has_many
    should have_imeths :find, :all
    should have_imeths :add_belongs_to, :add_polymorphic_belongs_to
    should have_imeths :add_has_one, :add_has_many

    should "add a belongs to reflection using `add_belongs_to`" do
      subject.add_belongs_to :test, FakeTestRecord.to_s, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.belongs_to.size
      reflection = subject.belongs_to.first
      assert_instance_of MR::FakeRecord::Reflection, reflection
    end

    should "add a polymorphic belongs to reflection using `add_polymorphic_belongs_to`" do
      subject.add_polymorphic_belongs_to :test, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.belongs_to.size
      reflection = subject.belongs_to.first
      assert_instance_of MR::FakeRecord::Reflection, reflection
    end

    should "add a has one reflection using `add_has_one`" do
      subject.add_has_one :test, FakeTestRecord.to_s, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.has_one.size
      reflection = subject.has_one.first
      assert_instance_of MR::FakeRecord::Reflection, reflection
    end

    should "add a has many reflection using `add_has_many`" do
      subject.add_has_many :test, FakeTestRecord.to_s, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.has_many.size
      reflection = subject.has_many.first
      assert_instance_of MR::FakeRecord::Reflection, reflection
    end

  end

  class WithAssociationsOnReflectionSetTests < ReflectionSetTests
    desc "with associations"
    setup do
      args = [ FakeTestRecord.to_s, @fake_record_class ]
      @association_set.add_belongs_to :belongs_to_test, *args
      @association_set.add_has_one    :has_one_test,    *args
      @association_set.add_has_many   :has_many_test,   *args
      @association_set.add_polymorphic_belongs_to :poly_belongs_to_test, @fake_record_class
    end

    should "return all belongs to reflections sorted using `belongs_to`" do
      reflections = subject.belongs_to
      expected = [ :belongs_to_test, :poly_belongs_to_test ]
      assert_equal expected, reflections.map(&:name)
    end

    should "return all has one reflections sorted using `has_one`" do
      reflections = subject.has_one
      assert_equal [ :has_one_test ], reflections.map(&:name)
    end

    should "return all has many reflections sorted using `has_many`" do
      reflections = subject.has_many
      assert_equal [ :has_many_test ], reflections.map(&:name)
    end

    should "find an reflection using `find`" do
      reflection = subject.find(:belongs_to_test)
      assert_equal :belongs_to_test, reflection.name
      reflection = subject.find(:poly_belongs_to_test)
      assert_equal :poly_belongs_to_test, reflection.name
      reflection = subject.find(:has_one_test)
      assert_equal :has_one_test, reflection.name
      reflection = subject.find(:has_many_test)
      assert_equal :has_many_test, reflection.name

      assert_nil subject.find(:doesnt_exist)
    end

    should "return all reflections using `all`" do
      reflections = subject.all
      assert_equal 4, reflections.size
      expected = [ :belongs_to_test, :poly_belongs_to_test, :has_one_test, :has_many_test ]
      assert_equal expected, reflections.map(&:name)
    end

    should "return all matching reflections passing a type to `all`" do
      reflections = subject.all(:belongs_to)
      expected = [ :belongs_to_test, :poly_belongs_to_test ]
      assert_equal expected, reflections.map(&:name)
      reflections = subject.all(:has_many)
      assert_equal [ :has_many_test ], reflections.map(&:name)
      reflections = subject.all(:has_one)
      assert_equal [ :has_one_test ], reflections.map(&:name)
    end

  end

  class ReflectionTests < UnitTests
    desc "MR::FakeRecord::Reflection"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:belongs_to, :parent, {
        :class_name   => FakeTestRecord.to_s,
        :foreign_key  => 'parent_id',
        :foreign_type => 'parent_type'
      })
    end
    subject{ @reflection }

    should have_readers :reader_method_name, :writer_method_name
    should have_readers :name, :macro, :options
    should have_readers :foreign_key, :foreign_type
    should have_imeths :association_class, :klass, :define_accessor_on

    should "know it's method names" do
      assert_equal "parent",  subject.reader_method_name
      assert_equal "parent=", subject.writer_method_name
    end

    should "know it's attributes" do
      assert_equal :parent,       subject.name
      assert_equal :belongs_to,   subject.macro
      assert_equal 'parent_type', subject.foreign_type
      assert_equal 'parent_id',   subject.foreign_key
      expected = {
        :class_name   => FakeTestRecord.to_s,
        :foreign_key  => subject.foreign_key,
        :foreign_type => subject.foreign_type
      }
      assert_equal expected, subject.options
    end

    should "return it's association class using `association_class`" do
      reflection = MR::FakeRecord::Reflection.new(:belongs_to, :test)
      assert_equal MR::FakeRecord::BelongsToAssociation, reflection.association_class
      reflection = MR::FakeRecord::Reflection.new(:has_one, :test)
      assert_equal MR::FakeRecord::HasOneAssociation, reflection.association_class
      reflection = MR::FakeRecord::Reflection.new(:has_many, :test)
      assert_equal MR::FakeRecord::HasManyAssociation, reflection.association_class
      reflection = MR::FakeRecord::Reflection.new(:belongs_to, :test, {
        :polymorphic => true
      })
      assert_equal MR::FakeRecord::PolymorphicBelongsToAssociation, reflection.association_class
    end

    should "return it's class name's constantized with `klass`" do
      assert_equal FakeTestRecord, subject.klass
    end

    should "define accessor methods using `define_accessor_on`" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      assert_respond_to :parent,  fake_record
      assert_respond_to :parent=, fake_record
    end

    should "be sortable" do
      reflections = [
        MR::FakeRecord::Reflection.new(:has_one, :test),
        MR::FakeRecord::Reflection.new(:has_many, :test),
        MR::FakeRecord::Reflection.new(:belongs_to, :test)
      ].sort
      expected = [ :belongs_to, :has_many, :has_one ]
      assert_equal expected, reflections.map(&:macro)
    end

  end

  class WithFakeRecordTests < UnitTests
    setup do
      @fake_record_class.class_eval do
        attr_reader :test, :tests
        attr_accessor :parent_type, :parent_id
      end
      @fake_record = @fake_record_class.new
    end
    subject{ @association }

  end

  class AssociationTests < WithFakeRecordTests
    desc "Association"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:belongs_to, :test)
      @association = MR::FakeRecord::Association.new(@fake_record, @reflection)
    end

    should have_readers :reflection
    should have_imeths :read, :write, :klass

    should "return it's reflection's klass using `klass`" do
      assert_equal @reflection.klass, subject.klass
    end

    should "raise NotImplementedError using `read` and `write`" do
      assert_raises(NotImplementedError){ subject.read }
      assert_raises(NotImplementedError){ subject.write('test') }
    end

    should "be sortable" do
      reflections = [
        MR::FakeRecord::Reflection.new(:belongs_to, :belongs_to_test),
        MR::FakeRecord::Reflection.new(:has_many,   :has_many_test)
      ]
      associations = reflections.map do |reflection|
        MR::FakeRecord::Association.new(@fake_record, reflection)
      end
      association_names = associations.sort.map{ |a| a.reflection.name }
      assert_equal reflections.sort.map(&:name), association_names
    end

  end

  class OneToOneAssociationTests < WithFakeRecordTests
    desc "OneToOneAssociation"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:belongs_to, :test)
      @association = MR::FakeRecord::OneToOneAssociation.new(
        @fake_record,
        @reflection
      )
    end

    should "be a kind of association" do
      assert_kind_of MR::FakeRecord::Association, subject
    end

    should "read and write its value using `read` and `write`" do
      associated_record = FakeTestRecord.new
      subject.write(associated_record)
      assert_same associated_record, @fake_record.test
      assert_same @fake_record.test, subject.read
    end

  end

  class OneToManyAssociationTests < WithFakeRecordTests
    desc "OneToManyAssociation"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:has_many, :tests)
      @association = MR::FakeRecord::OneToManyAssociation.new(
        @fake_record,
        @reflection
      )
    end

    should "be a kind of association" do
      assert_kind_of MR::FakeRecord::Association, subject
    end

    should "return an empty array when the association hasn't been set using `read`" do
      assert_equal [], subject.read
    end

    should "read and write its value using `read` and `write`" do
      associated_records = [ FakeTestRecord.new ]
      subject.write(associated_records)
      assert_equal associated_records, @fake_record.tests
      assert_equal @fake_record.tests, subject.read
    end

    should "allow writing non-array values using `write`" do
      associated_record = FakeTestRecord.new
      subject.write(associated_record)
      assert_equal [ associated_record ], @fake_record.tests
    end

    should "allow writing nil values using `write`" do
      subject.write nil
      assert_equal [], @fake_record.tests
    end

  end

  class BelongsToAssociationTests < WithFakeRecordTests
    desc "BelongsToAssociation"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:belongs_to, :parent, {
        :foreign_key => 'parent_id'
      })
      @association = MR::FakeRecord::BelongsToAssociation.new(
        @fake_record,
        @reflection
      )
    end

    should "be a kind of one to one association" do
      assert_kind_of MR::FakeRecord::OneToOneAssociation, subject
    end

    should "write its foreign key using `write`" do
      associated_record = FakeTestRecord.new.tap(&:save!)
      subject.write(associated_record)
      assert_equal associated_record.id, @fake_record.parent_id
    end

    should "allow writing nil values using `write`" do
      subject.write nil
      assert_equal nil, @fake_record.parent_id
    end

  end

  class PolymorphicBelongsToAssociationTests < WithFakeRecordTests
    desc "PolymorphicBelongsToAssociation"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:belongs_to, :parent, {
        :foreign_type => 'parent_type',
        :foreign_key  => 'parent_id'
      })
      @association = MR::FakeRecord::PolymorphicBelongsToAssociation.new(
        @fake_record,
        @reflection
      )
    end

    should "be a kind of belongs to association" do
      assert_kind_of MR::FakeRecord::BelongsToAssociation, subject
    end

    should "constantize its foreign type using `klass`" do
      @fake_record.parent_type = FakeTestRecord.to_s
      assert_equal FakeTestRecord, subject.klass
    end

    should "return `nil` if its foreign type isn't set using `klass`" do
      assert_nil subject.klass
    end

    should "write its foreign type using `write`" do
      associated_record = FakeTestRecord.new.tap(&:save!)
      subject.write(associated_record)
      assert_equal FakeTestRecord.to_s, @fake_record.parent_type
    end

    should "allow writing nil values using `write`" do
      subject.write nil
      assert_equal nil, @fake_record.parent_type
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
  end

end
