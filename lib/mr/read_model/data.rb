module MR; end
module MR::ReadModel

  module Data

    # `MR::ReadModel::Data` is a mixin that provides helpers for setting and
    # accessing the "data" for a read model. These methods provide a strict
    # interface to avoid confusing errors and ensure that the data for a
    # read model should, as much as possible, work.
    #
    # * Use the `data` protected method to access the data object.
    # * Use the `set_data` private method to write a data object.

    protected

    def data
      @data || raise(NoDataError.new(caller))
    end

    private

    def set_data(data)
      raise InvalidDataError unless data.respond_to?(:[])
      @data = data
    end

  end

  InvalidDataError = Class.new(ArgumentError)

  class NoDataError < RuntimeError
    def initialize(called_from = nil)
      super "the read model's data hasn't been set"
      set_backtrace(called_from) if called_from
    end
  end

end
