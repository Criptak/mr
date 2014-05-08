require 'mr'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/user'

class SubqueryData
  include MR::ReadModel

  field :area_id,    :primary_key, 'areas.id'
  field :user_id,    :primary_key, 'my_users.id'
  field :comment_id, :primary_key, 'my_comments.id'

  from AreaRecord

  inner_join_subquery do
    read_model do
      from UserRecord
      where{ |args| UserRecord.where(:started_on => args[:started_on]) }
    end
    as 'my_users'
    on 'my_users.area_id = areas.id'
  end
  left_join_subquery do
    read_model do
      from CommentRecord
      where CommentRecord.where(:parent_type => UserRecord.to_s)
    end
    as 'my_comments'
    on "my_comments.parent_type = '#{UserRecord}' AND " \
       "my_comments.parent_id = my_users.id"
  end

end
