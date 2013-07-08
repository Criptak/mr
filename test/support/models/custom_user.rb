require 'mr'
require 'test/support/models/_read_model/custom_user_select_result'
require 'test/support/models/area'
require 'test/support/models/user_record'

class CustomUser
  include MR::Model

  record_class UserRecord

  field_reader :created_at

  belongs_to :area, 'Area'

  def self.custom_all_of_em_query
    scope = UserRecord.select("users.id AS user_id")
    MR::Query.new(CustomUserSelectResult, scope)
  end

  def area
    value = super
    self.area = value = Area.new if !value
    value
  end

  def created_at
    super || Time.now
  end

end
