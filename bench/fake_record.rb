require 'bench/setup'

profiler = Bench::Profiler.new("bench/results/fake_record.txt")
profiler.run("MR::FakeRecord") do

  section "Initialization" do
    benchmark("initialize with no arguments") do |n|
      FakeAreaRecord.new
    end
    benchmark("initialize with a hash") do |n|
      FakeAreaRecord.new({
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
    end
  end

  section "Comparison" do
    first_fake_record  = FakeAreaRecord.new.tap{ |fr| fr.save! }
    second_fake_record = FakeAreaRecord.new.tap{ |fr| fr.save! }
    equal_fake_record  = FakeAreaRecord.new(first_fake_record.attributes)

    benchmark("== unequal") do |n|
      first_fake_record == second_fake_record
    end
    benchmark("== equal") do |n|
      first_fake_record == equal_fake_record
    end
  end

  section "Attributes" do
    fake_record_class = Class.new{ include MR::FakeRecord::Attributes }

    benchmark("attribute") do |n|
      fake_record_class.attribute "accessor_#{n}", :string
    end

    # TODO - replace with FakeAreaRecord when Attributes is part of FakeRecord
    fake_record_class = Class.new do
      include MR::FakeRecord::Attributes

      attribute :name,        :string
      attribute :active,      :boolean
      attribute :description, :text

      def initialize(values = nil)
        self.attributes = values || {}
      end
    end

    fake_area_record = fake_record_class.new({
      :name        => 'Name',
      :active      => true,
      :description => 'description'
    })

    benchmark("read single attribute") do |n|
      fake_area_record.name
    end
    benchmark("write single attribute") do |n|
      fake_area_record.name = "Name #{n}"
    end
    benchmark("single attribute changed?") do |n|
      fake_area_record.name_changed?
    end
    benchmark("attributes") do |n|
      fake_area_record.attributes
    end
    benchmark("attributes=") do |n|
      fake_area_record.attributes = {
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      }
    end

    benchmark("columns") do |n|
      fake_record_class.columns
    end
  end

  section "Associations" do
    fake_record_class = Class.new{ include MR::FakeRecord::Associations }

    benchmark("belongs_to") do |n|
      fake_record_class.belongs_to "belongs_to_#{n}", 'FakeAreaRecord'
    end
    benchmark("has_many") do |n|
      fake_record_class.has_many "has_many_#{n}", 'FakeAreaRecord'
    end
    benchmark("has_one") do |n|
      fake_record_class.has_one "has_one_#{n}", 'FakeAreaRecord'
    end
    benchmark("polymorphic_belongs_to") do |n|
      fake_record_class.polymorphic_belongs_to "polymorphic_belongs_to_#{n}"
    end

    # TODO - replace these when Associations is part of FakeRecord
    fake_area_record_class = Class.new do
      include MR::FakeRecord::Associations
      attribute :id, :primary_key
      has_many :users, 'FakeUserRecord'

      def save!
        self.id ||= MR::Factory.primary_key(self.class)
      end
    end
    fake_user_record_class = Class.new do
      include MR::FakeRecord::Associations
      attribute :id,       :primary_key
      attribute :area_id,  :integer
      attribute :image_id, :integer
      belongs_to :area, 'FakeAreaRecord'
      has_one :image, 'FakeImageRecord'
      has_many :comments, 'FakeCommentRecord'

      def save!
        self.id ||= MR::Factory.primary_key(self.class)
      end
    end
    fake_image_record_class = Class.new do
      include MR::FakeRecord::Associations
      attribute :id,      :primary_key
      attribute :user_id, :integer
      belongs_to :user, 'FakeUserRecord'

      def save!
        self.id ||= MR::Factory.primary_key(self.class)
      end
    end
    fake_comment_record_class = Class.new do
      include MR::FakeRecord::Associations
      attribute :id,            :primary_key
      attribute :parent_type,   :string
      attribute :parent_id,     :integer
      attribute :created_by_id, :integer
      polymorphic_belongs_to :parent
      belongs_to :created_by, 'FakeUserRecord'

      def save!
        self.id ||= MR::Factory.primary_key(self.class)
      end
    end

    first_area_record   = fake_area_record_class.new.tap{ |a| a.save! }
    second_area_record  = fake_area_record_class.new.tap{ |a| a.save! }
    first_user_record   = fake_user_record_class.new.tap{ |u| u.save! }
    second_user_record  = fake_user_record_class.new.tap{ |u| u.save! }
    first_image_record  = fake_image_record_class.new.tap{ |i| i.save! }
    second_image_record = fake_image_record_class.new.tap{ |i| i.save! }

    first_user_record.area  = first_area_record
    first_user_record.image = first_image_record
    first_user_record.save!
    comment_record = fake_comment_record_class.new.tap do |c|
      c.parent = first_user_record
      c.save!
    end

    benchmark("read belongs to") do |n|
      first_user_record.area
    end
    benchmark("write belongs to") do |n|
      first_user_record.area = (n % 2 == 0) ? second_area_record : first_area_record
    end
    benchmark("read has many") do |n|
      first_area_record.users
    end
    benchmark("write has many") do |n|
      first_area_record.users = if n % 2 == 0
        [ first_user_record, second_user_record ]
      else
        [ first_user_record ]
      end
    end
    benchmark("read has one") do |n|
      first_user_record.image
    end
    benchmark("write has one") do |n|
      first_user_record.image = (n % 2 == 0) ? second_image_record : first_image_record
    end
    benchmark("read polymorphic belongs to") do |n|
      comment_record.parent
    end
    benchmark("write polymorphic belongs to") do |n|
      comment_record.parent = (n % 2 == 0) ? second_user_record : first_user_record
    end

    fake_area_record = fake_area_record_class.new

    benchmark("reflect_on_all_associations") do
      fake_area_record_class.reflect_on_all_associations
    end
    benchmark("association") do |n|
      fake_area_record.association(:users)
    end
  end

  section "Persistence" do
    benchmark("save!") do |n|
      fake_area_record = FakeAreaRecord.new({
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
      fake_area_record.save!
    end

    fake_area_records = [*1..10000].map do |n|
      fake_area_record = FakeAreaRecord.new({
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
      fake_area_record.save!
      fake_area_record
    end
    benchmark("destroy") do |n|
      fake_area_records[n].destroy
    end

    benchmark("valid? and errors") do |n|
      fake_area_record = FakeAreaRecord.new
      fake_area_record.errors.add(:name, "can't be blank")
      fake_area_record.valid?
      fake_area_record.errors
    end
  end

end
