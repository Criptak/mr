require 'assert'
require 'mr/fake_record/associations'

require 'mr/fake_record'

module MR::FakeRecord::Associations

  class UnitTests < Assert::Context
    desc "MR::FakeRecord::Associations"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord::Associations
      end
    end
    subject{ @fake_record_class }

    should have_imeths :associations
    should have_imeths :belongs_to, :polymorphic_belongs_to
    should have_imeths :has_one, :has_many
    should have_imeths :reflect_on_all_associations

    should "include FakeRecord Attributes mixin" do
      assert_includes MR::FakeRecord::Attributes, subject
    end

    should "return an instance of a AssociationSet using `associations`" do
      associations = subject.associations
      assert_instance_of MR::FakeRecord::AssociationSet, associations
      assert_same associations, subject.associations
    end

    should "add belongs to methods using `belongs_to`" do
      subject.attribute :test_id, :integer
      subject.belongs_to :test, FakeTestRecord.to_s
      fake_record = subject.new

      assert_respond_to :test,  fake_record
      assert_respond_to :test=, fake_record
      fake_test_record = FakeTestRecord.new.tap(&:save!)
      fake_record.test = fake_test_record
      assert_equal fake_test_record, fake_record.test
    end

    should "add polymorphic belongs to methods using `polymorphic_belongs_to`" do
      subject.attribute :parent_type, :string
      subject.attribute :parent_id,   :integer
      subject.polymorphic_belongs_to :parent
      fake_record = subject.new

      assert_respond_to :parent,  fake_record
      assert_respond_to :parent=, fake_record
      fake_test_record = FakeTestRecord.new.tap(&:save!)
      fake_record.parent = fake_test_record
      assert_equal fake_test_record, fake_record.parent
    end

    should "add has one methods using `has_one`" do
      subject.attribute :test_id, :integer
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
      @fake_record_class.polymorphic_belongs_to :poly_belongs_to_test
      @fake_record_class.has_one :has_one_test, FakeTestRecord.to_s
      @fake_record_class.has_many :has_many_test, FakeTestRecord.to_s
    end

    should "return all reflections using `reflect_on_all_associations`" do
      reflections = subject.reflect_on_all_associations
      assert_equal 4, reflections.size
      reflections.each do |reflection|
        assert_instance_of MR::FakeRecord::Reflection, reflection
      end
      expected = [ :belongs_to_test, :poly_belongs_to_test, :has_one_test, :has_many_test ]
      assert_equal expected, reflections.map(&:name)
    end

    should "only return specific kinds of reflections when a type is passed " \
           "to `reflect_on_all_associations`" do
      reflections = subject.reflect_on_all_associations(:belongs_to)
      expected = [ :belongs_to_test, :poly_belongs_to_test ]
      assert_equal expected, reflections.map(&:name)
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
      assert_equal @fake_record_class.associations.find(:test), association
    end

  end

  class AssociationSetTests < UnitTests
    desc "AssociationSet"
    setup do
      @association_set = MR::FakeRecord::AssociationSet.new
    end
    subject{ @association_set }

    should have_imeths :belongs_to, :has_one, :has_many
    should have_imeths :find, :all
    should have_imeths :add_belongs_to, :add_polymorphic_belongs_to
    should have_imeths :add_has_one, :add_has_many

    should "add a belongs to association using `add_belongs_to`" do
      subject.add_belongs_to :test, FakeTestRecord.to_s, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.belongs_to.size
      association = subject.belongs_to.first
      assert_instance_of MR::FakeRecord::BelongsToAssociation, association
    end

    should "add a polymorphic belongs to association using `add_polymorphic_belongs_to`" do
      subject.add_polymorphic_belongs_to :test, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.belongs_to.size
      association = subject.belongs_to.first
      assert_instance_of MR::FakeRecord::PolymorphicBelongsToAssociation, association
    end

    should "add a has one association using `add_has_one`" do
      subject.add_has_one :test, FakeTestRecord.to_s, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.has_one.size
      association = subject.has_one.first
      assert_instance_of MR::FakeRecord::HasOneAssociation, association
    end

    should "add a has many association using `add_has_many`" do
      subject.add_has_many :test, FakeTestRecord.to_s, @fake_record_class
      fake_record = @fake_record_class.new
      assert_equal 1, subject.has_many.size
      association = subject.has_many.first
      assert_instance_of MR::FakeRecord::HasManyAssociation, association
    end

  end

  class WithAssociationsOnAssociationSetTests < AssociationSetTests
    desc "with associations"
    setup do
      args = [ FakeTestRecord.to_s, @fake_record_class ]
      @association_set.add_belongs_to :belongs_to_test, *args
      @association_set.add_has_one    :has_one_test,    *args
      @association_set.add_has_many   :has_many_test,   *args
      @association_set.add_polymorphic_belongs_to :poly_belongs_to_test, @fake_record_class
    end

    should "return all belongs to associations sorted using `belongs_to`" do
      associations = subject.belongs_to
      expected = [ :belongs_to_test, :poly_belongs_to_test ]
      assert_equal expected, associations.map{ |a| a.reflection.name }
    end

    should "return all has one associations sorted using `has_one`" do
      associations = subject.has_one
      assert_equal [ :has_one_test ], associations.map{ |a| a.reflection.name }
    end

    should "return all has many associations sorted using `has_many`" do
      associations = subject.has_many
      assert_equal [ :has_many_test ], associations.map{ |a| a.reflection.name }
    end

    should "find an association using `find`" do
      association = subject.find(:belongs_to_test)
      assert_equal :belongs_to_test, association.reflection.name
      association = subject.find(:poly_belongs_to_test)
      assert_equal :poly_belongs_to_test, association.reflection.name
      association = subject.find(:has_one_test)
      assert_equal :has_one_test, association.reflection.name
      association = subject.find(:has_many_test)
      assert_equal :has_many_test, association.reflection.name

      assert_nil subject.find(:doesnt_exist)
    end

    should "return all associations using `all`" do
      associations = subject.all
      assert_equal 4, associations.size
      expected = [ :belongs_to_test, :poly_belongs_to_test, :has_one_test, :has_many_test ]
      assert_equal expected, associations.map{ |a| a.reflection.name }
    end

    should "return all matching association passing a type to `all`" do
      associations = subject.all(:belongs_to)
      expected = [ :belongs_to_test, :poly_belongs_to_test ]
      assert_equal expected, associations.map{ |a| a.reflection.name }
      associations = subject.all(:has_many)
      assert_equal [ :has_many_test ], associations.map{ |a| a.reflection.name }
      associations = subject.all(:has_one)
      assert_equal [ :has_one_test ], associations.map{ |a| a.reflection.name }
    end

  end

  class AssociationTests < UnitTests
    desc "Association"
    setup do
      @association = MR::FakeRecord::Association.new(:test, {
        :class_name => FakeTestRecord.to_s
      })
    end
    subject{ @association }

    should have_readers :reader_method_name, :writer_method_name
    should have_readers :ivar_name
    should have_readers :reflection

    should "build a reflection with the options passed when initialized" do
      assert_instance_of MR::FakeRecord::Reflection, subject.reflection
      assert_equal :test, subject.reflection.name
      expected = { :class_name => FakeTestRecord.to_s }
      assert_equal expected, subject.reflection.options
    end

    should "return it's reflection's klass using `klass`" do
      assert_equal subject.reflection.klass, subject.klass
    end

    should "know it's method names and ivar name" do
      assert_equal "test",  subject.reader_method_name
      assert_equal "test=", subject.writer_method_name
      assert_equal "@test", subject.ivar_name
    end

    should "be sortable" do
      associations = [
        MR::FakeRecord::Association.new(:belongs_to_test, :type => :belongs_to),
        MR::FakeRecord::Association.new(:has_many_test, :type => :has_many)
      ]
      assert_equal associations.sort_by{ |a| a.reflection }, associations.sort
    end

  end

  class OneToOneAssociationTests < UnitTests
    desc "OneToOneAssociation"
    setup do
      @fake_record_class.attribute :test_id, :integer
      @association = MR::FakeRecord::OneToOneAssociation.new(:test, {
        :class_name => FakeTestRecord.to_s
      })
    end
    subject{ @association }

    should "be a kind of association" do
      assert_kind_of MR::FakeRecord::Association, subject
    end

    should "have set it's reflection's foreign key" do
      assert_equal "test_id", subject.reflection.foreign_key
    end

    should "write it's foreign key on a fake record using `write_attributes`" do
      fake_record = @fake_record_class.new
      association_record = FakeTestRecord.new.tap(&:save!)
      subject.write_attributes(association_record, fake_record)
      assert_equal association_record.id, fake_record.test_id
    end

    should "define accessor methods using `define_accessor_on`" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      association_record = FakeTestRecord.new.tap(&:save!)
      fake_record.test = association_record
      assert_equal association_record, fake_record.test
      assert_equal association_record.id, fake_record.test_id
    end

    should "allow writing `nil` values with it's accessor methods" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      fake_record.test = nil
      assert_nil fake_record.test
      assert_nil fake_record.test_id
    end

  end

  class OneToManyAssociationTests < UnitTests
    desc "OneToManyAssociation"
    setup do
      @association = MR::FakeRecord::OneToManyAssociation.new(:test, {
        :class_name => FakeTestRecord.to_s
      })
    end
    subject{ @association }

    should "be a kind of association" do
      assert_kind_of MR::FakeRecord::Association, subject
    end

    should "define accessor methods using `define_accessor_on`" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      association_record = FakeTestRecord.new.tap(&:save!)
      fake_record.test = [ association_record ]
      assert_equal [ association_record ], fake_record.test
    end

    should "default it's value to an empty array with it's accessor methods" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      assert_equal [], fake_record.test
    end

    should "allow writing non-array values with it's accessor methods" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      association_record = FakeTestRecord.new.tap(&:save!)
      fake_record.test = association_record
      assert_equal [ association_record ], fake_record.test
    end

    should "allow writing `nil` values with it's accessor methods" do
      subject.define_accessor_on(@fake_record_class)
      fake_record = @fake_record_class.new
      fake_record.test = nil
      assert_equal [], fake_record.test
    end

  end

  class BelongsToAssociationTests < UnitTests
    desc "BelongsToAssociation"
    setup do
      @association = MR::FakeRecord::BelongsToAssociation.new(:test, FakeTestRecord.to_s)
    end
    subject{ @association }

    should "be a kind of one to one association" do
      assert_kind_of MR::FakeRecord::OneToOneAssociation, subject
    end

    should "set it's reflection's macro and klass" do
      assert_equal :belongs_to,    subject.reflection.macro
      assert_equal FakeTestRecord, subject.reflection.klass
    end

  end

  class PolymorphicBelongsToAssociationTests < UnitTests
    desc "PolymorphicBelongsToAssociation"
    setup do
      @fake_record_class.attribute :parent_type, :string
      @fake_record_class.attribute :parent_id,   :integer
      @association = MR::FakeRecord::PolymorphicBelongsToAssociation.new(:parent)
    end
    subject{ @association }

    should "be a kind of belongs to association" do
      assert_kind_of MR::FakeRecord::BelongsToAssociation, subject
    end

    should "set it's reflection's foreign type and polymorphic option" do
      assert_equal 'parent_type', subject.reflection.foreign_type
      assert_equal true,          subject.reflection.options[:polymorphic]
    end

    should "write it's foreign type and key on a fake record using `write_attributes`" do
      fake_record = @fake_record_class.new
      association_record = FakeTestRecord.new.tap(&:save!)
      subject.write_attributes(association_record, fake_record)
      assert_equal FakeTestRecord.to_s,   fake_record.parent_type
      assert_equal association_record.id, fake_record.parent_id
    end

  end

  class HasOneAssociationTests < UnitTests
    desc "HasOneAssociation"
    setup do
      @association = MR::FakeRecord::HasOneAssociation.new(:test, FakeTestRecord.to_s)
    end
    subject{ @association }

    should "be a kind of one to one association" do
      assert_kind_of MR::FakeRecord::OneToOneAssociation, subject
    end

    should "set it's reflection's macro and klass" do
      assert_equal :has_one,       subject.reflection.macro
      assert_equal FakeTestRecord, subject.reflection.klass
    end

  end

  class HasManyAssociationTests < UnitTests
    desc "HasManyAssociation"
    setup do
      @association = MR::FakeRecord::HasManyAssociation.new(:test, FakeTestRecord.to_s)
    end
    subject{ @association }

    should "be a kind of one to many association" do
      assert_kind_of MR::FakeRecord::OneToManyAssociation, subject
    end

    should "set it's reflection's macro and klass" do
      assert_equal :has_many,      subject.reflection.macro
      assert_equal FakeTestRecord, subject.reflection.klass
    end

  end

  class ReflectionTests < UnitTests
    desc "MR::FakeRecord::Reflection"
    setup do
      @reflection = MR::FakeRecord::Reflection.new(:parent, {
        :type         => :belongs_to,
        :class_name   => FakeTestRecord.to_s,
        :foreign_key  => 'parent_id',
        :foreign_type => 'parent_type'
      })
    end
    subject{ @reflection }

    should have_readers :name, :macro, :options
    should have_readers :foreign_key, :foreign_type
    should have_imeths :klass

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

    should "return it's class name's constantized with `klass`" do
      assert_equal FakeTestRecord, subject.klass
    end

    should "be sortable" do
      reflections = [
        MR::FakeRecord::Reflection.new(:test, :type => :has_one),
        MR::FakeRecord::Reflection.new(:test, :type => :has_many),
        MR::FakeRecord::Reflection.new(:test, :type => :belongs_to)
      ].sort
      expected = [ :belongs_to, :has_many, :has_one ]
      assert_equal expected, reflections.map(&:macro)
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
  end

end
