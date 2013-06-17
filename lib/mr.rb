require 'active_record'

require 'mr/version'
require 'mr/model'
require 'mr/query'
require 'mr/read_model'
require 'mr/record'

module MR

  class InvalidRecordError < RuntimeError
    def initialize(record)
      super "The passed record is not a kind of MR::Record: #{record.inspect}"
    end
  end

end
