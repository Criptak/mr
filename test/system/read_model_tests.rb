require 'assert'
require 'mr/read_model'

require 'mr/factory'
require 'test/support/models/user_record'

module MR::ReadModel

  class SystemTests < Assert::Context
    setup do
      @user_factory = MR::Factory.new(UserRecord)
    end
  end

  class UserWithAreaDataQueryTests < SystemTests
    desc "UserWithAreaData query"
    setup do
      @matching_user_stack = @user_factory.instance_stack.tap{ |s| s.create }
      @matching_user = @matching_user_stack.record
      @not_matching_user_stack = @user_factory.instance_stack.tap{ |s| s.create }
      @not_matching_user = @not_matching_user_stack.record
      @query = UserWithAreaData.query(@matching_user.area_id)
    end
    teardown do
      @not_matching_user_stack.destroy
      @matching_user_stack.destroy
    end
    subject{ @query }

    should "return an MR::Query" do
      assert_instance_of MR::Query, subject
    end

    should "filter records based on the user's area" do
      results = subject.results
      assert_equal 1, results.size
      assert_equal @matching_user.id,      results.first.user_id
      assert_equal @matching_user.area_id, results.first.area_id
    end

  end

  class UserWithAreaDataFieldsTests < SystemTests
    desc "UserWithAreaData fields"
    setup do
      @user_stack = @user_factory.instance_stack.tap{ |s| s.create }
      @user       = @user_stack.record
      query = UserWithAreaData.query(@user.area_id)
      @user_with_area_data = query.results.first
    end
    teardown do
      @user_stack.destroy
    end
    subject{ @user_with_area_data }

    should have_readers :user_id, :user_name
    should have_readers :area_id, :area_name

    should "know it's user data" do
      assert_equal @user.id,        subject.user_id
      assert_equal @user.name,      subject.user_name
      assert_equal @user.area.id,   subject.area_id
      assert_equal @user.area.name, subject.area_name
    end

  end

  class UserWithAreaData
    include MR::ReadModel

    field :user_id,   :integer, 'users.id'
    field :user_name, :string,  'users.name'
    field :area_id,   :integer, 'areas.id'
    field :area_name, :string,  'areas.name'
    from UserRecord
    joins :area
    where do |area_id|
      [ "areas.id = ?", area_id ]
    end

  end

end
