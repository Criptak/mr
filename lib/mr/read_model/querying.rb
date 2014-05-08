require 'mr/read_model/query_expression'
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

      def find(id, args = nil)
        self.new(self.relation.build_for_find(args || {}).find(id))
      end

      def query(args = nil)
        MR::Query.new(self, self.relation.build_for_all(args || {}))
      end

      def select(*args, &block)
        add_query_expression(:select, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def from(record_class)
        raise ArgumentError, "must be a MR::Record" unless record_class < MR::Record
        relation.record_class = record_class
      end

      def joins(*args, &block)
        add_query_expression(:joins, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def inner_join_subquery(&block)
        add_subquery_expression(:joins, :inner, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def left_outer_join_subquery(&block)
        add_subquery_expression(:joins, :left, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end
      alias :left_join_subquery :left_outer_join_subquery

      def right_outer_join_subquery(&block)
        add_subquery_expression(:joins, :right, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end
      alias :right_join_subquery :right_outer_join_subquery

      def full_outer_join_subquery(&block)
        add_subquery_expression(:joins, :full, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end
      alias :full_join_subquery :full_outer_join_subquery

      def where(*args, &block)
        add_merge_query_expression(:where, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def order(*args, &block)
        add_merge_query_expression(:order, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def group(*args, &block)
        add_query_expression(:group, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def having(*args, &block)
        add_query_expression(:having, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def limit(*args, &block)
        add_query_expression(:limit, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def offset(*args, &block)
        add_query_expression(:offset, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      def merge(*args, &block)
        add_merge_query_expression(:merge, *args, &block)
      rescue InvalidQueryExpressionError, ArgumentError => exception
        raise ArgumentError, exception.message, caller
      end

      private

      def add_query_expression(type, *args, &block)
        QueryExpression.new(type, *args, &block).tap do |expression|
          relation.expressions << expression
        end
      end

      def add_merge_query_expression(type, *args, &block)
        MergeQueryExpression.new(type, *args, &block).tap do |expression|
          relation.expressions << expression
        end
      end

      def add_subquery_expression(type, *args, &block)
        SubQueryExpression.new(type, *args, &block).tap do |expression|
          relation.expressions << expression
        end
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

    FIND_EXCLUDED_TYPES = [ :where, :order, :limit, :offset ].freeze
    def build_for_find(args = nil)
      expressions = @expressions.reject{ |e| FIND_EXCLUDED_TYPES.include?(e.type) }
      build(expressions, args)
    end

    def build_for_all(args = nil)
      build(@expressions, args)
    end

    private

    def build(expressions, args = nil)
      raise NoRecordClassError if !@record_class
      expressions.inject(@record_class.scoped) do |relation, expression|
        expression.apply_to(relation, args)
      end
    end
  end

  class NoRecordClassError < RuntimeError
    def initialize
      super "a record class hasn't been set - set one using `from`"
    end
  end

end
