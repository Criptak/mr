require 'mr'
require 'test/support/models/area_record'

class Area
  include MR::Model

  record_class AreaRecord

  field_reader :id
  field_accessor :name

end
