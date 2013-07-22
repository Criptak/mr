require 'mr/factory'

module MR; end
module MR::Factory

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
      @children = associations_with_preset_first.map do |association|
        associated_stack_record = if association.preset?
          Record.new(association.preset_record)
        else
          @lookup[association.key] || Record.new(association.build_record)
        end
        @lookup[association.key] ||= associated_stack_record
        @stack_record.set_association(association.name, associated_stack_record)
        TreeNode.new(associated_stack_record, @lookup)
      end
    end

    def create
      create_children
      @stack_record.create
    end

    def create_children
      @children.each(&:create)
      @stack_record.refresh_associations
    end

    def destroy
      @stack_record.destroy
      destroy_children
    end

    def destroy_children
      @children.each(&:destroy)
    end

    private

    # preset associations are sorted first, these should be used first by stacks
    # so it will build
    def associations_with_preset_first
      @stack_record.associations.sort_by{ |a| a.preset? ? 1 : 2 }
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
      @instance.save! if @instance.new_record?
    end

    def destroy
      @instance.destroy unless @instance.destroyed?
    end

    # ensures record's have their dependencies ids set, this is done by
    # "resetting" the association to it's current value
    def refresh_associations
      @associations.each do |association|
        associated = @instance.send(association.name)
        @instance.send("#{association.name}=", associated)
      end
    end

    private

    def belongs_to_associations(record)
      record.class.reflect_on_all_associations.map do |reflection|
        next unless reflection.belongs_to?
        Association.new(record, record.association(reflection.name))
      end.compact.sort
    end

    class Association
      attr_reader :name, :record_class, :key, :preset_record
      def initialize(record, association)
        @owner_record = record
        @name         = association.reflection.name
        @record_class = association.klass
        @key          = @record_class.to_s

        @preset_record = @owner_record.send(@name)
      end

      def preset?
        !!@preset_record
      end

      def build_record
        MR::Factory::RecordFactory.new(@record_class).instance
      end

      def <=>(other)
        if other.kind_of?(self.class)
          self.name.to_s <=> other.name.to_s
        else
          super
        end
      end
    end

  end

end
