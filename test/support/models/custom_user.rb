require 'mr'
require 'test/support/models/area'
require 'test/support/models/user_record'

class CustomUser
  include MR::Model

  record_class CustomUserRecord

  field_reader :created_at

  belongs_to :area, 'Area'

  def area
    value = super
    self.area = value = Area.new if !value
    value
  end

  def created_at
    super || Time.now
  end

end
