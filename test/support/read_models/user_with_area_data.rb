require 'mr'
require 'test/support/models/user'

class UserWithAreaData
  include MR::ReadModel

  field :user_id,   :primary_key, 'users.id'
  field :user_name, :string,      'users.name'
  field :area_id,   :primary_key, 'areas.id'
  field :area_name, :string,      'areas.name'
  from UserRecord
  joins :area
  where do |area_id|
    [ "areas.id = ?", area_id ]
  end

end
