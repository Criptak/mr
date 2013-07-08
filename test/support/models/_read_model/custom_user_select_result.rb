

class CustomUserSelectResult
  include MR::ReadModel

  def user_id
    super.to_i
  end

end
