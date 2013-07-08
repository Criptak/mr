require 'active_record'
require 'mr'

class AreaRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = "areas"
end
