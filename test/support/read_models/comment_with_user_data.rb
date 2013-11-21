require 'mr'
require 'test/support/models/comment'
require 'test/support/models/user'

class CommentWithUserData
  include MR::ReadModel

  field :comment_id,         :primary_key, 'comments.id'
  field :comment_created_at, :datetime,    'comments.created_at'
  field :user_name,          :string,      'users.name'
  field :user_number,        :integer,     'users.number'
  field :user_salary,        :decimal,     'users.salary'
  field :user_started_on,    :date,        'users.started_on'
  field :user_dob,           :timestamp,   'users.dob'
  field :image_data,         :binary,      'images.data'
  field :area_active,        :boolean,     'areas.active'
  field :area_meeting_time,  :time,        'areas.meeting_time'
  field :area_description,   :text,        'areas.description'
  field :area_percentage,    :float,       'areas.percentage'
  from CommentRecord
  joins "INNER JOIN users ON " \
          "'#{UserRecord}' = comments.parent_type AND " \
          "users.id = comments.parent_id " \
        "INNER JOIN images ON images.user_id = users.id " \
        "INNER JOIN areas ON areas.id = users.area_id"

end
