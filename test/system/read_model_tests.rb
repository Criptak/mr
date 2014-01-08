require 'assert'
require 'mr/read_model'

require 'mr/factory'
require 'test/support/setup_test_db'
require 'test/support/factory/area'
require 'test/support/factory/comment'
require 'test/support/factory/image'
require 'test/support/factory/user'
require 'test/support/read_models/comment_with_user_data'
require 'test/support/read_models/user_with_area_data'

module MR::ReadModel

  class SystemTests < Assert::Context
    desc "MR::ReadModel"

  end

  class FieldsTests < SystemTests
    desc "fields"
    setup do
      @area    = Factory::Area.instance.tap(&:save)
      @user    = Factory::User.instance(:area => @area).tap(&:save)
      @image   = Factory::Image.instance(:user => @user).tap(&:save)
      @comment = Factory::Comment.instance(:parent => @user).tap(&:save)
      @comment_with_user_data = CommentWithUserData.query.results.first
    end
    teardown do
      @comment.destroy
      @image.destroy
      @user.destroy
      @area.destroy
    end
    subject{ @comment_with_user_data }

    should have_readers :comment_id, :comment_created_at
    should have_readers :user_name, :user_number, :user_salary, :user_started_on
    should have_readers :area_active, :area_meeting_time

    should "know it's different model's data" do
      # reload the comment/area -- force AR to type-cast it's columns, otherwise
      # comment has whatever fake data it was given, which may not match up
      # like Time != DateTime
      @comment = Comment.find(@comment.id)
      @image   = Image.find(@image.id)
      @user    = User.find(@user.id)
      @area    = Area.find(@area.id)
      assert_equal @comment.id,         subject.comment_id
      assert_equal @comment.created_at, subject.comment_created_at
      assert_equal @user.name,          subject.user_name
      assert_equal @user.number,        subject.user_number
      assert_equal @user.salary,        subject.user_salary
      assert_equal @user.started_on,    subject.user_started_on
      assert_equal @user.dob,           subject.user_dob
      assert_equal @image.data,         subject.image_data
      assert_equal @area.active,        subject.area_active
      assert_equal @area.meeting_time,  subject.area_meeting_time
      assert_equal @area.description,   subject.area_description
      assert_equal @area.percentage,    subject.area_percentage
    end

  end

  class QueryTests < SystemTests
    desc "query"
    setup do
      @matching_user_stack = Factory::User.instance_stack.tap(&:create)
      @matching_user = @matching_user_stack.model
      @not_matching_user_stack = Factory::User.instance_stack.tap(&:create)
      @not_matching_user = @not_matching_user_stack.model
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

  class FindTests < SystemTests
    desc "find"
    setup do
      @matching_user_stack = Factory::User.instance_stack.tap(&:create)
      @matching_user = @matching_user_stack.model
      @user_with_area_data = UserWithAreaData.find(@matching_user.id)
    end
    teardown do
      @matching_user_stack.destroy
    end
    subject{ @user_with_area_data }

    should "find a specific record by it's id" do
      assert_equal @matching_user.id, subject.user_id
    end

  end

end
