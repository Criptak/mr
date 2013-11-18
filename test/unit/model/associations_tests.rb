require 'assert'
require 'mr/model/associations'

require 'mr/fake_record'
require 'mr/model'

module MR::Model::Associations

  class UnitTests < Assert::Context
    desc "MR::Model::Associations"
    setup do
      @model_class = Class.new do
        include MR::Model::Associations
        record_class FakeRecordWithAssociations
        def initialize(record); set_record record; end
      end
      @record = FakeRecordWithAssociations.new
    end
    subject{ @model_class }

    should have_imeths :associations
    should have_imeths :belongs_to, :polymorphic_belongs_to
    should have_imeths :has_one, :has_many

    should "include Model::Configuration mixin" do
      assert_includes MR::Model::Configuration, subject.included_modules
    end

    should "return an instance of a AssociationSet using `associations`" do
      associations = subject.associations
      assert_instance_of MR::Model::AssociationSet, associations
      assert_same associations, subject.associations
    end

    should "add accessors methods for a belongs to association using `belongs_to`" do
      subject.belongs_to :area
      model = subject.new(@record)
      new_record = FakeTestRecord.new
      new_model  = FakeTestModel.new(new_record)

      assert_respond_to :area, model
      assert_respond_to :area=, model
      model.area = new_model
      assert_instance_of FakeTestModel, model.area
      assert_equal new_record, @record.area
    end

    should "add accessors methods for a polymorphic belongs to association " \
           "using `polymorphic_belongs_to`" do
      subject.polymorphic_belongs_to :parent
      model = subject.new(@record)
      new_record = FakeTestRecord.new
      new_model  = FakeTestModel.new(new_record)

      assert_respond_to :parent, model
      assert_respond_to :parent=, model
      model.parent = new_model
      assert_instance_of FakeTestModel, model.parent
      assert_equal new_record, @record.parent
    end

    should "add accessors methods for a has one association using `has_one`" do
      subject.has_one :image
      model = subject.new(@record)
      new_record = FakeTestRecord.new
      new_model  = FakeTestModel.new(new_record)

      assert_respond_to :image, model
      assert_respond_to :image=, model
      model.image = new_model
      assert_instance_of FakeTestModel, model.image
      assert_equal new_record, @record.image
    end

    should "add accessors methods for a has many association using `has_many`" do
      subject.has_many :comments
      model = subject.new(@record)
      first_record  = FakeTestRecord.new
      first_model   = FakeTestModel.new(first_record)
      second_record = FakeTestRecord.new
      second_model  = FakeTestModel.new(second_record)

      assert_respond_to :comments, model
      assert_respond_to :comments=, model
      model.comments = [ first_model, second_model ]
      assert_instance_of Array, model.comments
      assert_includes first_record,  @record.comments
      assert_includes second_record, @record.comments
    end

  end

  class InstanceTests < UnitTests
    desc "for a model instance"
    setup do
      @model_class.class_eval do
        belongs_to :area
        polymorphic_belongs_to :parent
        has_one :image
        has_many :comments
      end
      @model = @model_class.new(@record)
    end
    subject{ @model }

    should "raise an ArgumentError if writing non MR::Model values to associations" do
      assert_raises(ArgumentError){ subject.area = 'test' }
      assert_raises(ArgumentError){ subject.parent = 'test' }
      assert_raises(ArgumentError){ subject.image = 'test' }
      assert_raises(ArgumentError){ subject.comments = [ 'test' ] }
    end

  end

  class AssociationSetTests < UnitTests
    desc "AssociationSet"
    setup do
      @association_set = MR::Model::AssociationSet.new
    end
    subject{ @association_set }

    should have_readers :belongs_to, :polymorphic_belongs_to
    should have_readers :has_one, :has_many
    should have_imeths :add_belongs_to, :add_polymorphic_belongs_to
    should have_imeths :add_has_one, :add_has_many

  end

  class AssociationTests < UnitTests
    desc "Association"
    setup do
      @association = MR::Model::Association.new(:test)
    end
    subject{ @association }

    should have_readers :name
    should have_readers :reader_method_name, :writer_method_name

    should "know it's name and method names" do
      assert_equal 'test',  subject.name
      assert_equal 'test',  subject.reader_method_name
      assert_equal 'test=', subject.writer_method_name
    end

  end

  class OneToOneAssociationTests < UnitTests
    desc "OneToOneAssociation"
    setup do
      @test_record  = FakeTestRecord.new.tap{ |r| r.save! }
      @test_model   = FakeTestModel.new(@test_record)
      @other_record = FakeTestRecord.new.tap{ |r| r.save! }
      @other_model  = FakeTestModel.new(@other_record)

      @association  = MR::Model::OneToOneAssociation.new(:area)
    end
    subject{ @association }

    should have_imeths :read, :write

    should "be a kind of Association" do
      assert_kind_of MR::Model::Association, subject
    end

    should "allow reading the record's association using `read`" do
      @test_record.area = @other_record
      assert_equal @other_model, subject.read(@test_record)
    end

    should "allow reading `nil` values for the record's association using `read`" do
      @test_record.area = nil
      assert_nil subject.read(@test_record)
    end

    should "allow writing the record's association using `write`" do
      record  = @other_record
      yielded = nil
      result = subject.write(@other_model, @test_model, @test_record) do |object|
        yielded = object; record
      end

      assert_equal @other_model,  yielded
      assert_equal @other_record, @test_record.area
      assert_equal @test_model.send(subject.name), result
    end

    should "allow writing `nil` values to the record's association using `write`" do
      subject.write(nil, @test_model, @test_record){ raise 'test' }
      assert_nil @test_record.area
    end

    should "raise a bad association value error when writing a non MR::Model" do
      assert_raises(MR::Model::BadAssociationValueError) do
        subject.write('test', @test_model, @test_record){ }
      end
    end

  end

  class OneToManyAssociationTests < UnitTests
    desc "OneToManyAssociation"
    setup do
      @test_record   = FakeTestRecord.new.tap{ |r| r.save! }
      @test_model    = FakeTestModel.new(@test_record)
      @first_record  = FakeTestRecord.new.tap{ |r| r.save! }
      @first_model   = FakeTestModel.new(@first_record)
      @second_record = FakeTestRecord.new.tap{ |r| r.save! }
      @second_model  = FakeTestModel.new(@second_record)

      @association   = MR::Model::OneToManyAssociation.new(:comments)
    end
    subject{ @association }

    should have_imeths :read, :write

    should "be a kind of Association" do
      assert_kind_of MR::Model::Association, subject
    end

    should "allow reading the record's association using `read`" do
      @test_record.comments = [ @first_record ]
      expected = [ @first_model ]
      assert_equal expected, subject.read(@test_record)
    end

    should "allow reading `nil` values for the record's association using `read`" do
      @test_record.comments = []
      assert_equal [], subject.read(@test_record)
    end

    should "allow writing the record's association using `write`" do
      models  = [ @first_model, @second_model ]
      yielded = []
      results = subject.write(models, @test_model, @test_record) do |object|
        yielded << object; object.send(:record)
      end

      assert_equal models,  yielded
      records = [ @first_record, @second_record ]
      assert_equal records, @test_record.comments
      assert_equal @test_model.send(subject.name), results
    end

    should "allow writing a single value to the record's association using `write`" do
      subject.write(@second_model, @test_model, @test_record) do |object|
        object.send(:record)
      end
      assert_equal [ @second_record ], @test_record.comments
    end

    should "allow writing `nil` values to the record's association using `write`" do
      subject.write(nil, @test_model, @test_record){ raise 'test' }
      assert_equal [], @test_record.comments
    end

    should "raise a bad association value error when writing a non MR::Model" do
      assert_raises(MR::Model::BadAssociationValueError) do
        subject.write('test', @test_model, @test_record){ }
      end
    end

  end

  class BelongsToAssociationTests < UnitTests
    desc "BelongsToAssociation"
    setup do
      @association = MR::Model::BelongsToAssociation.new(:test)
    end
    subject{ @association }

    should "be a kind of OneToOneAssociation" do
      assert_kind_of MR::Model::OneToOneAssociation, subject
    end

  end

  class HasOneAssociationTests < UnitTests
    desc "HasOneAssociation"
    setup do
      @association = MR::Model::HasOneAssociation.new(:test)
    end
    subject{ @association }

    should "be a kind of OneToOneAssociation" do
      assert_kind_of MR::Model::OneToOneAssociation, subject
    end

  end

  class HasManyAssociationTests < UnitTests
    desc "HasManyAssociation"
    setup do
      @association = MR::Model::HasManyAssociation.new(:test)
    end
    subject{ @association }

    should "be a kind of OneToManyAssociation" do
      assert_kind_of MR::Model::OneToManyAssociation, subject
    end

  end

  class PolymorphicBelongsToAssociationTests < UnitTests
    desc "PolymorphicBelongsToAssociation"
    setup do
      @association = MR::Model::PolymorphicBelongsToAssociation.new(:test)
    end
    subject{ @association }

    should "be a kind of BelongsToAssociation" do
      assert_kind_of MR::Model::BelongsToAssociation, subject
    end

  end

  class FakeRecordWithAssociations
    include MR::FakeRecord
    belongs_to :area, 'MR::Model::Associations::FakeRecordWithAssociations'
    polymorphic_belongs_to :parent
    has_one :image, 'MR::Model::Associations::FakeRecordWithAssociations'
    has_many :comments, 'MR::Model::Associations::FakeRecordWithAssociations'
  end

  class FakeTestRecord
    include MR::FakeRecord
    belongs_to :area, 'MR::Model::Associations::FakeTestRecord'
    has_many :comments, 'MR::Model::Associations::FakeTestRecord'
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
    belongs_to :area
    has_many :comments
  end

end
