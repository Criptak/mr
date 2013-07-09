require 'mr/stack/record'

module MR; end
module MR::Stack

  class RecordStack
    attr_reader :record

    def initialize(record_class)
      @stack_record = Record.new(record_class)
      @dependency_lookup    = {}
      @dependency_tree_root = TreeNode.new(@stack_record, @dependency_lookup)
      @record = @stack_record.instance
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
        @lookup[association.key] ||= Record.new(association.record_class)
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

end
