require 'mr/record'
require 'mr/query'

module MR; end
module MR::ReadModel

  module Querying

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods

      def relation
        @relation ||= Relation.new
      end

      def query(args = nil)
        args ||= {}
        MR::Query.new(self, relation.build(args))
      end

      def select(*args, &block)
        relation.add_select(*args, &block)
      rescue InvalidQueryExpression => e
        raise ArgumentError, e.message
      end

      def from(record_class)
        raise ArgumentError, "must be a MR::Record" unless record_class < MR::Record
        relation.record_class = record_class
      end

      def joins(*args, &block)
        relation.add_joins(*args, &block)
      rescue InvalidQueryExpression => e
        raise ArgumentError, e.message
      end

    end

  end

  class Relation
    attr_accessor :record_class
    attr_reader :selects, :joins

    def initialize
      @record_class = nil
      @selects = []
      @joins   = []
    end

    def add_select(*args, &block)
      @selects << QueryExpression.new(:select, *args, &block)
    end

    def add_joins(*args, &block)
      @joins << QueryExpression.new(:joins, *args, &block)
    end

    def build(args = nil)
      raise NoRecordClassError if !@record_class
      [ @joins, @selects ].inject(@record_class.scoped) do |relation, expressions|
        expressions.empty? ? relation : apply_all(expressions, relation, args)
      end
    end

    private

    def apply_all(expressions, relation, args)
      expressions.inject(relation){ |r, e| e.apply_to(r, args) }
    end

  end

  module QueryExpression

    def self.new(type, *args, &block)
      if !args.empty?
        Static.new(type, *args)
      elsif block
        Dynamic.new(type, &block)
      else
        raise InvalidQueryExpression
      end
    end

    class Static
      attr_reader :type, :args

      def initialize(type, *args)
        @type = type
        @args = args
      end

      # apply_to has to take a second arg that it ignores, this is so it has the
      # same interface as `Dynamic` (which actually needs the second arg)
      def apply_to(relation, ignored = nil)
        relation.send(@type, *@args)
      end
    end

    class Dynamic
      attr_reader :type, :block

      def initialize(type, &block)
        @type  = type
        @block = block
      end

      def apply_to(relation, args)
        relation.send(@type, @block.call(args))
      end
    end

  end

  class NoRecordClassError < RuntimeError
    def initialize
      super "a record class hasn't been set - set one using `from`"
    end
  end

  class InvalidQueryExpression < RuntimeError
    def initialize
      super "must be passed arguments or a block"
    end
  end

end
