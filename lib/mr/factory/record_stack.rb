require 'mr/factory'

module MR; end
module MR::Factory

  class RecordStack
    attr_reader :record, :dependency_lookup

    def initialize(record)
      @record       = record
      @stack_record = Record.new(@record)
      @dependency_lookup    = build_lookup(@stack_record)
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

    private

    def build_lookup(stack_record)
      load_preset_associations_into_lookup({}, stack_record)
    end

    def load_preset_associations_into_lookup(lookup, stack_record)
      stack_record.associations.select(&:preset?).each do |association|
        associated_stack_record = Record.new(association.preset_record)
        lookup[association.key] ||= associated_stack_record
        load_preset_associations_into_lookup(lookup, associated_stack_record)
      end
      lookup
    end

  end

  class TreeNode
    attr_reader :stack_record, :children
    def initialize(stack_record, lookup)
      @stack_record = stack_record
      @lookup       = lookup
      @children = self.stack_record.associations.map do |association|
        associated_stack_record = if association.preset?
          Record.new(association.preset_record)
        else
          @lookup[association.key] || Record.new(association.build_record)
        end
        @lookup[association.key] ||= associated_stack_record
        self.stack_record.set_association(association.name, associated_stack_record)
        TreeNode.new(associated_stack_record, @lookup)
      end
    end

    def create
      create_children
      self.stack_record.create
    end

    def create_children
      self.children.each(&:create)
      self.stack_record.refresh_associations
    end

    def destroy
      self.stack_record.destroy
      destroy_children
    end

    def destroy_children
      self.children.each(&:destroy)
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
      if @instance.new_record?
        @instance.save!
        @instance.reset_save_called if @instance.kind_of?(MR::FakeRecord)
      end
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
      record.class.reflect_on_all_associations(:belongs_to).map do |reflection|
        association = Association.new(record, record.association(reflection.name))
        association if association.required?
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
        @required = !!@preset_record ||
                    column_required?(association.reflection.foreign_key) ||
                    column_required?(association.reflection.foreign_type)
      end

      def preset?
        !!@preset_record
      end

      def required?
        @required
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

      private

      def column_required?(column_name)
        column = @owner_record.column_for_attribute(column_name)
        !!(column && !column.null)
      end
    end

  end

end
