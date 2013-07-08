class FakeActiveRecordRelation
  attr_reader :results

  def initialize
    @results = []
    @offset = 0
    @limit = nil
  end

  def offset(value)
    @offset = value.to_i
    self
  end

  def limit(value)
    @limit = value.to_i
    self
  end

  def all
    @results[@offset, (@limit || @results.size)] || []
  end

  def count
    all.size
  end

  def results=(value)
    @results = [*value].compact
  end

  def offset_value
    @offset
  end

  def limit_value
    @limit
  end

end
