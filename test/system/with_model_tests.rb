require 'assert'
require 'mr'

require 'test/support/setup_test_db'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/custom_user'
require 'test/support/models/user'
require 'test/support/models/user_record'

class WithModelTests < Assert::Context
  desc "MR with an ActiveRecord model"
  setup do
    @user = User.new({ :name => "Joe Test" })
  end
  teardown do
    @user.destroy rescue nil
  end
  subject{ @user }

  should "allow accessing the record's attributes" do
    assert_nothing_raised do
      subject.name   = 'Joe Test'
      subject.email  = 'joe.test@example.com'
      subject.active = true
    end

    # check that the attributes were set
    record = subject.send(:record)
    assert_equal 'Joe Test',             record.name
    assert_equal 'joe.test@example.com', record.email
    assert_equal true,                   record.active

    # check that we can read the attributes
    assert_equal 'Joe Test',             subject.name
    assert_equal 'joe.test@example.com', subject.email
    assert_equal true,                   subject.active
  end

  should "allow mass setting and reading the record's attributes" do
    assert_nothing_raised do
      subject.fields = {
        :name   => 'Joe Test',
        :email  => 'joe.test@example.com',
        :active => true
      }
    end

    # check that the attributes were set
    record = subject.send(:record)
    assert_equal 'Joe Test',             record.name
    assert_equal 'joe.test@example.com', record.email
    assert_equal true,                   record.active

    expected = {
      :id         => nil,
      :name       => 'Joe Test',
      :email      => 'joe.test@example.com',
      :active     => true,
      :area_id    => nil,
      :created_at => nil,
      :updated_at => nil
    }
    assert_equal expected, subject.fields
  end

  should "be able to save and destroy the model" do
    assert_nothing_raised do
      subject.save({
        :name   => 'Joe Test',
        :email  => 'joe.test@example.com',
        :active => true
      })
    end
    assert_not subject.destroyed?
    assert UserRecord.exists?(subject.id)

    assert_nothing_raised do
      subject.destroy
    end
    assert subject.destroyed?
    assert_not UserRecord.exists?(subject.id)
  end

end

class DetectChangedFieldsTests < WithModelTests
  setup do
    @user = User.new
  end

  should "detect when it's fields have changed" do
    assert subject.new?
    assert_not subject.name_changed?
    subject.name = 'Test'
    assert subject.name_changed?

    subject.save
    assert_not subject.new?
    assert_not subject.name_changed?
    subject.name = 'New Test'
    assert subject.name_changed?
  end

end

class BelongsToTests < WithModelTests
  desc "using a belongs to association"
  setup do
    @area = Area.new({ :name => 'Alpha' })
    @area.save
  end
  teardown do
    @area.destroy
  end

  should "be able to read it and write to it" do
    assert_nil subject.area

    assert_nothing_raised do
      subject.area = @area
    end

    assert_equal @area,    subject.area
    assert_equal @area.id, subject.area_id
  end

end

class HasManyTests < WithModelTests
  desc "using a has many association"
  setup do
    @user.save
    @comment = Comment.new({ :message => "Test", :user => @user })
  end
  teardown do
    @comment.destroy
    @user.destroy
  end

  should "be able to read it" do
    @comment.save

    assert_equal [ @comment ], subject.comments
  end

end

class HasOneTests < WithModelTests
  desc "using a has one association"
  setup do
    @user.save
    @comment = Comment.new({ :message => "Test", :favorite => true, :user => @user })
  end
  teardown do
    @comment.destroy
    @user.destroy
  end

  should "be able to read it" do
    @comment.save

    assert_equal @comment, subject.favorite_comment
  end

end

class PolymorphicBelongsToTests < WithModelTests
  desc "using a polymorphic belongs to association"
  setup do
    @user.save
    @area = Area.new(:name => 'Alpha')
    @area.save
    @comment = Comment.new(:message => "Test")
  end
  teardown do
    @comment.destroy
    @area.destroy
    @user.destroy
  end
  subject{ @comment }

  should "be able to read it and write to it" do
    assert_nil subject.parent

    assert_nothing_raised do
      subject.parent = @area
    end
    assert_equal @area,        subject.parent
    assert_equal @area.id,     subject.parent_id
    assert_equal 'AreaRecord', subject.parent_type

    assert_nothing_raised do
      subject.parent = @user
    end
    assert_equal @user,        subject.parent
    assert_equal @user.id,     subject.parent_id
    assert_equal 'UserRecord', subject.parent_type
  end

end

class QueryTests < WithModelTests
  desc "using a MR::Query"
  setup do
    @users = [*(0..4)].map do |i|
      User.new({ :name => "test #{i}" }).tap{|u| u.save }
    end
    @query = User.all_of_em_query
  end
  teardown do
    @users.each(&:destroy)
  end
  subject{ @query }

  should "allow fetching the models with #models" do
    assert_equal @users, subject.models
  end

  should "allow counting the models with #count" do
    assert_equal 5, subject.count
  end

end

class PagedQueryTests < QueryTests
  setup do
    @paged_query = @query.paged(1, 3)
  end
  subject{ @paged_query }

  should "allow fetching the models paged with #models" do
    assert_equal @users[0, 3], subject.models

    paged_query = @query.paged(2, 3)
    assert_equal @users[3, 2], paged_query.models
  end

  should "allow fetching the models paged with #models" do
    assert_equal 3, subject.count

    paged_query = @query.paged(2, 3)
    assert_equal 2, paged_query.count
  end

  should "allow counting the total number of models with #total_count" do
    assert_equal 5, subject.total_count
  end

end

class FinderTests < WithModelTests
  setup do
    @users = [*(1..3)].map do |i|
      record = UserRecord.new({ :name => "test #{i}" }).tap do |u|
        u.id = i
        u.save!
      end
      User.new(record)
    end
  end
  teardown do
    @users.each(&:destroy)
  end

  should "allow fetching a single user with find" do
    assert_equal @users[0], User.find(1)

    assert_raises(ActiveRecord::RecordNotFound) do
      User.find(1000)
    end
  end

  should "allow fetching a all users with all" do
    assert_equal @users, User.all
  end

end

class InvalidTests < WithModelTests
  desc "when saving an invalid model"
  setup do
    @user = User.new
  end

  should "raise a InvalidModel exception with the ActiveRecord error messages" do
    exception = nil
    begin
      subject.save
    rescue Exception => exception
    end

    assert_instance_of MR::Model::InvalidError, exception
    assert_equal [ "can't be blank" ], exception.errors[:name]
    assert_includes ":name can't be blank", exception.message
  end

  should "return the ActiveRecord's error messages with errors" do
    subject.valid?

    assert_equal [ "can't be blank" ], subject.errors[:name]
  end

end

class SuperFieldAndAssociationTests < WithModelTests
  desc "when overwriting field or association methods defined by model"
  setup do
    @user = CustomUser.new
  end

  should "allow supering to the original method defined by MR::Model" do
    assert_not_nil subject.created_at
    area = subject.area
    assert_instance_of Area, area
    assert area.new?
  end

end

class SuperReadModelFieldsTests < WithModelTests
  desc "when overwriting a method defined by read model"
  setup do
    record = UserRecord.new({ :name => 'test' }).tap do |u|
      u.id = 1
      u.save!
    end
    @user = User.new(record)
    @query = CustomUser.custom_all_of_em_query
  end
  teardown do
    @user.destroy
  end
  subject{ @query }

  should "allow supering to the original method defined by MR::ReadModel" do
    read_model = @query.models.first
    assert_instance_of Fixnum, read_model.user_id
    assert_equal @user.id, read_model.user_id
  end

end
