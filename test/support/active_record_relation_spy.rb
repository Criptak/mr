class ActiveRecordRelationSpy
  attr_reader :applied
  attr_accessor :results

  def initialize
    @applied = []
    @results = []
    @limit  = nil
    @offset = 0
  end

  [ :select,
    :joins,
    :where,
    :order,
    :group, :having,
    :merge
  ].each do |type|

    define_method(type) do |*args|
      @applied << AppliedExpression.new(type, args)
      self
    end

  end

  def limit(value)
    @limit = value.to_i
    @applied << AppliedExpression.new(:limit, [ value ])
    self
  end

  def offset(value)
    @offset = value.to_i
    @applied << AppliedExpression.new(:offset, [ value ])
    self
  end

  def all
    @results[@offset, (@limit || @results.size)] || []
  end

  def count
    all.size
  end

  def limit_value
    @limit
  end

  def offset_value
    @offset
  end

  def ==(other)
    @applied == other.applied
  end

  AppliedExpression = Struct.new(:type, :args)
end
