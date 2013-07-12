require 'mr/factory'

module MR; end
module MR::Stack

  class RecordStack
    attr_reader :record

    def initialize(record)
      @record       = record
      @stack_record = Record.new(@record)
      @dependency_lookup    = {}
      @dependency_tree_root = TreeNode.new(@stack_record, @dependency_lookup)
    end

    def create
      @dependency_tree_root.create
      true
    end

    def destroy
      @dependency_tree_root.destroy
      true
    end

    def create_dependencies
      @dependency_tree_root.create_children
      true
    end

    def destroy_dependencies
      @dependency_tree_root.destroy_children
      true
    end

  end

  class TreeNode
    attr_reader :stack_record, :children
    def initialize(stack_record, lookup)
      @stack_record = stack_record
      @lookup       = lookup
      @children = @stack_record.associations.map do |association|
        @lookup[association.key] ||= Record.new(association.get_record)
        association_stack_record = @lookup[association.key]
        @stack_record.set_association(association.name, association_stack_record)
        TreeNode.new(association_stack_record, @lookup)
      end
    end

    def create
      create_children
      @stack_record.create
    end

    def create_children
      @children.each(&:create)
      refresh_associations
    end

    def destroy
      @stack_record.destroy
      destroy_children
    end

    def destroy_children
      @children.each(&:destroy)
    end

    private

    # to make sure record's have their dependencies ids set, it's necessary to
    # "refresh" the associations for this node's stack_record.
    def refresh_associations
      @stack_record.associations.each do |association|
        @stack_record.set_association(association.name, @lookup[association.key])
      end
    end
  end

  class Record

    attr_reader :instance, :associations

    def initialize(record)
      @instance = record
      @associations = belongs_to_associations(@instance)
    end

    def set_association(name, stack_record)
      @instance.send("#{name}=", stack_record.instance)
    end

    def create
      @instance.save!
    end

    def destroy
      @instance.destroy
    end

    private

    def belongs_to_associations(record)
      record.class.reflect_on_all_associations.map do |reflection|
        next unless reflection.belongs_to?
        Association.new(record, record.association(reflection.name))
      end.compact
    end

    class Association
      attr_reader :name, :record_class, :key
      def initialize(record, association)
        @owner_record = record
        @name         = association.reflection.name
        @record_class = association.klass
        @key          = @record_class.to_s
      end

      def get_record
        record = @owner_record.send(@name)
        record || MR::Factory::RecordFactory.new(@record_class).instance
      end
    end

  end

end
