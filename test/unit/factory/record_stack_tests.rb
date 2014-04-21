require 'assert'
require 'mr/factory/record_stack'

require 'mr/fake_record'

class MR::Factory::RecordStack

  class UnitTests < Assert::Context
    desc "MR::Factory::RecordStack"
    setup do
      @record = TestFakeRecord.new
    end

  end

  class RecordStackTests < UnitTests
    setup do
      @stack_record_spy = StackRecordSpy.new
      MR::Factory::Record.stubs(:new).tap do |s|
        s.with(@record)
        s.returns(@stack_record_spy)
      end

      @tree_node_spy = TreeNodeSpy.new
      MR::Factory::TreeNode.stubs(:new).tap do |s|
        s.with(@stack_record_spy, {})
        s.returns(@tree_node_spy)
      end

      @record_stack = MR::Factory::RecordStack.new(@record)
    end
    teardown do
      MR::Factory::TreeNode.unstub(:new)
      MR::Factory::Record.unstub(:new)
    end
    subject{ @record_stack }

    should have_readers :record, :dependency_lookup
    should have_imeths :create, :destroy
    should have_imeths :create_dependencies, :destroy_dependencies

    should "call create on its tree node using `create`" do
      subject.create
      assert_true @tree_node_spy.create_called
    end

    should "call destroy on its tree node using `destroy`" do
      subject.destroy
      assert_true @tree_node_spy.destroy_called
    end

    should "call create children on its tree node using `create_dependencies`" do
      subject.create_dependencies
      assert_true @tree_node_spy.create_children_called
    end

    should "call destroy children on its tree node using `destroy_dependencies`" do
      subject.destroy_dependencies
      assert_true @tree_node_spy.destroy_children_called
    end

  end

  class WithPresetAssociationsTests < UnitTests
    desc "with preset associations"
    setup do
      @another_record = AnotherFakeRecord.new.tap(&:save!)
      @record.another = @another_record

      @other_record = OtherFakeRecord.new.tap(&:save!)
      @another_record.other = @other_record

      @record_stack = MR::Factory::RecordStack.new(@record)
    end
    subject{ @record_stack }

    should "build out its dependency lookup using preset associations" do
      lookup = subject.dependency_lookup[@another_record.class.to_s]
      assert_equal @another_record, lookup.instance
      lookup = subject.dependency_lookup[@other_record.class.to_s]
      assert_equal @other_record, lookup.instance
    end

  end

  class TreeNodeTests < UnitTests
    desc "TreeNode"
    setup do
      @stack_record = MR::Factory::Record.new(@record)
      @dependency_lookup = {}
      @tree_node = MR::Factory::TreeNode.new(@stack_record, @dependency_lookup)
    end
    subject{ @tree_node }

    should have_readers :stack_record, :children
    should have_imeths :create, :create_children
    should have_imeths :destroy, :destroy_children

    should "know its stack record" do
      assert_equal @stack_record, subject.stack_record
    end

    should "build associated tree nodes as its children" do
      assert_equal 2, subject.children.size
      subject.children.each{ |c| assert_instance_of MR::Factory::TreeNode, c }
      record_classes = subject.children.map{ |c| c.stack_record.instance.class }
      assert_equal [ AnotherFakeRecord, OtherFakeRecord ], record_classes
    end

    should "build new associated records for associations that aren't preset" do
      subject.children.each do |c|
        assert_true c.stack_record.instance.new_record?
      end
    end

    should "set associations on the record as it builds child tree nodes" do
      assert_instance_of OtherFakeRecord,   @record.other
      assert_instance_of AnotherFakeRecord, @record.another
      assert_instance_of OtherFakeRecord,   @record.another.other
    end

    should "reuse associated records that are built for associations" do
      prefix = 'MR::Factory::RecordStack'
      other_stack_record   = @dependency_lookup["#{prefix}::OtherFakeRecord"]
      another_stack_record = @dependency_lookup["#{prefix}::AnotherFakeRecord"]
      assert_same other_stack_record.instance,   @record.other
      assert_same another_stack_record.instance, @record.another
      assert_same other_stack_record.instance,   @record.another.other
    end

  end

  class TreeNodeActionTests < TreeNodeTests
    setup do
      @stack_record_spy = StackRecordSpy.new
      @tree_node.stubs(:stack_record).returns(@stack_record_spy)
      @tree_node_spy = TreeNodeSpy.new
      @tree_node.stubs(:children).returns([ @tree_node_spy ])
    end

    should "create its children, refresh its stack record associations and " \
           "then create its stack record using `create`" do
      subject.create

      assert_true @tree_node_spy.create_called
      assert_true @stack_record_spy.refresh_associations_called
      assert_true @stack_record_spy.create_called

      called_before = @tree_node_spy.create_called_at <
                      @stack_record_spy.refresh_associations_called_at
      assert_true called_before

      called_before = @stack_record_spy.refresh_associations_called_at <
                      @stack_record_spy.create_called_at
      assert_true called_before
    end

    should "create its children and refresh its stack record associations " \
           "using `create_children`" do
      subject.create_children

      assert_true @tree_node_spy.create_called
      assert_true @stack_record_spy.refresh_associations_called
      assert_false @stack_record_spy.create_called

      called_before = @tree_node_spy.create_called_at <
                      @stack_record_spy.refresh_associations_called_at
      assert_true called_before
    end

    should "destroy its stack record and then its children using `destroy`" do
      subject.destroy

      assert_true @stack_record_spy.destroy_called
      assert_true @tree_node_spy.destroy_called

      called_before = @stack_record_spy.destroy_called_at <
                      @tree_node_spy.destroy_called_at
      assert_true called_before
    end

    should "destroy its children using `destroy_children`" do
      subject.destroy_children

      assert_true @tree_node_spy.destroy_called
    end

  end

  class TreeNodeWithPresetAssociationsTests < UnitTests
    desc "TreeNode with preset associations"
    setup do
      @another_record = AnotherFakeRecord.new.tap(&:save!)
      @record.another = @another_record

      @other_record = OtherFakeRecord.new.tap(&:save!)
      @record.other = @other_record

      @lookup_record = OtherFakeRecord.new.tap(&:save!)
      @lookup_stack_record = MR::Factory::Record.new(@lookup_record)

      @stack_record = MR::Factory::Record.new(@record)
      @dependency_lookup = { OtherFakeRecord.to_s => @lookup_stack_record }
      @tree_node = MR::Factory::TreeNode.new(@stack_record, @dependency_lookup)
    end
    subject{ @tree_node }

    should "not override preset associations with new records" do
      assert_same @record.another, @another_record
    end

    should "not override preset associations with records in the lookup" do
      assert_same @record.other, @other_record
    end

    should "use records in the lookup to different associations " \
           "of the same record class" do
      assert_same @lookup_record, @record.another.other
    end

  end

  class StackRecordTests < UnitTests
    desc "Record"
    setup do
      @stack_record = MR::Factory::Record.new(@record)
    end
    subject{ @stack_record }

    should have_readers :instance, :associations
    should have_imeths :create, :destroy
    should have_imeths :set_association, :refresh_associations

    should "know its record instance" do
      assert_equal @record, subject.instance
    end

    should "build stack associations from it's record's required associations" do
      assert_equal 2, subject.associations.size
      subject.associations.each do |association|
        assert_instance_of MR::Factory::Record::Association, association
      end
      association_names = subject.associations.map(&:name)
      assert_equal [ :another, :other ], association_names
      assert_not_includes :not_required, association_names
    end

    should "save a record using `create` if its a new record" do
      assert_true @record.new_record?
      subject.create
      assert_false @record.new_record?
      @record.stubs(:save!).raises("shouldn't be called")
      assert_nothing_raised{ subject.create }
    end

    should "reset a fake records save called flag using `create`" do
      assert_false @record.save_called
      subject.create
      assert_false @record.save_called
    end

    should "set an association from a stack record using `set_association`" do
      another_record = AnotherFakeRecord.new.tap(&:save!)
      another_stack_record = MR::Factory::Record.new(another_record)
      subject.set_association(:another, another_stack_record)
      assert_equal another_record, @record.another
    end

    should "reset associations, properly setting foreign keys, " \
           "using `refresh_associations`" do
      another_record = AnotherFakeRecord.new
      @record.another = another_record
      another_record.save!
      assert_nil @record.another_id
      subject.refresh_associations
      assert_equal another_record.id, @record.another_id
    end

  end

  class StackRecordAssociationTests < UnitTests
    desc "Record::Association"
    setup do
      @associated_record = AnotherFakeRecord.new
      @record.another = @associated_record
      @association = @record.association(:another)

      @stack_association_class = MR::Factory::Record::Association
      @stack_association = @stack_association_class.new(@record, @association)

      @factory = MR::Factory::RecordFactory.new(@stack_association.record_class)
      @factory_record = @stack_association.record_class.new
      MR::Factory::RecordFactory.stubs(:new).tap do |s|
        s.with(@stack_association.record_class)
        s.returns(@factory)
      end
      @factory.stubs(:instance).returns(@factory_record)
    end
    teardown do
      MR::Factory::RecordFactory.unstub(:new)
    end
    subject{ @stack_association }

    should have_readers :name, :record_class, :key, :preset_record
    should have_imeths :preset?, :required?, :build_record

    should "know its attributes" do
      assert_equal @association.reflection.name, subject.name
      assert_equal @association.klass,           subject.record_class
      assert_equal @association.klass.to_s,      subject.key
      assert_equal @record.another,              subject.preset_record
    end

    should "know if it was preset or not" do
      @record.another = @associated_record
      sa = @stack_association_class.new(@record, @association)
      assert_true sa.preset?

      @record.another = nil
      sa = @stack_association_class.new(@record, @association)
      assert_false sa.preset?
    end

    should "be required if it is preset" do
      associated_record = OtherFakeRecord.new
      association = @record.association(:not_required)

      @record.not_required = nil
      sa = @stack_association_class.new(@record, association)
      assert_false sa.required?

      @record.not_required = associated_record
      sa = @stack_association_class.new(@record, association)
      assert_true sa.required?
    end

    should "be required if its columns are required" do
      record = FakePolyRequiredKeyRecord.new(:parent_type => @record.class.to_s)
      association = record.association(:parent)
      sa = @stack_association_class.new(record, association)
      assert_true sa.required?

      record = FakePolyRequiredTypeRecord.new(:parent_type => @record.class.to_s)
      association = record.association(:parent)
      sa = @stack_association_class.new(record, association)
      assert_true sa.required?

      record = FakePolyNoRequiredRecord.new(:parent_type => @record.class.to_s)
      association = record.association(:parent)
      sa = @stack_association_class.new(record, association)
      assert_false sa.required?
    end

    should "use a record factory to build a new instance using `build_record`" do
      assert_equal @factory_record, subject.build_record
    end

    should "be sortable" do
      other_association   = @record.association(:other)
      another_association = @record.association(:another)
      associations = [
        @stack_association_class.new(@record, other_association),
        @stack_association_class.new(@record, another_association)
      ].sort
      assert_equal [ :another, :other ], associations.map(&:name)
    end

    should "raise a no record class error when an association's record class " \
           "can't be determined" do
      exception = nil
      record = FakePolyNoRequiredRecord.new
      association = record.association(:parent)
      begin
        @stack_association_class.new(record, association)
      rescue StandardError => exception
      end
      expected = MR::Factory::Record::Association::NoRecordClassError
      assert_instance_of expected, exception
      expected = "a record class couldn't be determined for the 'parent' " \
                 "association -- its 'parent_type' attribute should be set"
      assert_equal expected, exception.message
    end

  end

  class TestFakeRecord
    include MR::FakeRecord

    attribute :id,              :primary_key
    attribute :other_id,        :integer,     :null => false
    attribute :another_id,      :integer,     :null => false
    attribute :not_required_id, :integer,     :null => true

    belongs_to :other,        'MR::Factory::RecordStack::OtherFakeRecord'
    belongs_to :another,      'MR::Factory::RecordStack::AnotherFakeRecord'
    belongs_to :not_required, 'MR::Factory::RecordStack::OtherFakeRecord'
  end

  class OtherFakeRecord
    include MR::FakeRecord

    attribute :id, :primary_key
  end

  class AnotherFakeRecord
    include MR::FakeRecord

    attribute :id,       :primary_key
    attribute :other_id, :integer,     :null => false

    belongs_to :other, 'MR::Factory::RecordStack::OtherFakeRecord'
  end

  class FakePolyRequiredKeyRecord
    include MR::FakeRecord

    attribute :id,          :primary_key
    attribute :parent_type, :string,      :null => true
    attribute :parent_id,   :integer,     :null => false

    polymorphic_belongs_to :parent
  end

  class FakePolyRequiredTypeRecord
    include MR::FakeRecord

    attribute :id,          :primary_key
    attribute :parent_type, :string,      :null => false
    attribute :parent_id,   :integer,     :null => true

    polymorphic_belongs_to :parent
  end


  class FakePolyNoRequiredRecord
    include MR::FakeRecord

    attribute :id,          :primary_key
    attribute :parent_type, :string,      :null => true
    attribute :parent_id,   :integer,     :null => true

    polymorphic_belongs_to :parent
  end

  class TreeNodeSpy
    attr_reader :create_called, :create_called_at
    attr_reader :create_children_called
    attr_reader :destroy_called, :destroy_called_at
    attr_reader :destroy_children_called

    def initialize
      @create_called = false
      @create_called_at = nil
      @create_children_called = false
      @destroy_called = false
      @destroy_called_at = nil
      @destroy_children_called = false
    end

    def create
      @create_called = true
      @create_called_at = Time.now
    end

    def create_children
      @create_children_called = true
    end

    def destroy
      @destroy_called = true
      @destroy_called_at = Time.now
    end

    def destroy_children
      @destroy_children_called = true
    end
  end

  class StackRecordSpy
    attr_reader :associations
    attr_reader :create_called, :create_called_at
    attr_reader :destroy_called, :destroy_called_at
    attr_reader :refresh_associations_called, :refresh_associations_called_at

    def initialize
      @associations = []
      @create_called = false
      @create_called_at = nil
      @destroy_called = false
      @destroy_called_at = nil
      @refresh_associations_called = false
      @refresh_associations_called_at = nil
    end

    def create
      @create_called = true
      @create_called_at = Time.now
    end

    def destroy
      @destroy_called = true
      @destroy_called_at = Time.now
    end

    def refresh_associations
      @refresh_associations_called = true
      @refresh_associations_called_at = Time.now
    end
  end

end
