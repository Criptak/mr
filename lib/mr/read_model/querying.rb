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
        add_query_expression(:select, *args, &block)
      end

      def from(record_class)
        raise ArgumentError, "must be a MR::Record" unless record_class < MR::Record
        relation.record_class = record_class
      end

      def joins(*args, &block)
        add_query_expression(:joins, *args, &block)
      end

      def where(*args, &block)
        add_query_expression(:where, *args, &block)
      end

      def order(*args, &block)
        add_query_expression(:order, *args, &block)
      end

      def group(*args, &block)
        add_query_expression(:group, *args, &block)
      end

      def having(*args, &block)
        add_query_expression(:having, *args, &block)
      end

      def limit(*args, &block)
        add_query_expression(:limit, *args, &block)
      end

      def offset(*args, &block)
        add_query_expression(:offset, *args, &block)
      end

      def merge(*args, &block)
        add_query_expression(:merge, *args, &block)
      end

      private

      def add_query_expression(type, *args, &block)
        relation.expressions << QueryExpression.new(type, *args, &block)
      rescue InvalidQueryExpression => exception
        error = ArgumentError.new(exception.message)
        error.set_backtrace(caller)
        raise error
      end

    end

  end

  class Relation
    attr_accessor :record_class
    attr_reader :expressions

    def initialize
      @record_class = nil
      @expressions  = []
    end

    def build(args = nil)
      raise NoRecordClassError if !@record_class
      @expressions.inject(@record_class.scoped) do |relation, expression|
        expression.apply_to(relation, args)
      end
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
