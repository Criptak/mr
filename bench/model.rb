require 'bench/setup'

profiler = Bench::Profiler.new("bench/results/model.txt")
profiler.run("MR::Model") do

  section "Configuration" do
    model_class = Class.new do
      include MR::Model
      record_class AreaRecord
    end
    benchmark("record_class read") do
      model_class.record_class
    end
    benchmark("record_class write") do |n|
      model_class.record_class((n % 2 == 0) ? UserRecord : AreaRecord)
    end
  end

  section "Initialization" do
    record = AreaRecord.new

    benchmark("initialize with no arguments") do |n|
      Area.new
    end
    benchmark("initialize with a record") do |n|
      Area.new(record)
    end
    benchmark("initialize with a hash") do |n|
      Area.new({
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
    end
    benchmark("initialize with a record and hash") do |n|
      Area.new(record, {
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
    end
  end

  section "Comparison" do
    first_model  = Area.new.tap{ |m| m.save }
    second_model = Area.new.tap{ |m| m.save }
    same_model   = Area.find(second_model.id)

    benchmark("== unequal") do |n|
      first_model == second_model
    end
    benchmark("== equal") do |n|
      second_model == same_model
    end
  end

  section "Fields" do
    model_class = Class.new{ include MR::Model }

    benchmark("field_reader") do |n|
      model_class.field_reader "reader_#{n}"
    end
    benchmark("field_writer") do |n|
      model_class.field_writer "writer_#{n}"
    end
    benchmark("field_accessor") do |n|
      model_class.field_accessor "accessor_#{n}"
    end

    area = Area.new({
      :name        => 'Name',
      :active      => true,
      :description => 'description'
    })

    benchmark("read single field") do |n|
      area.name
    end
    benchmark("write single field") do |n|
      area.name = "Name #{n}"
    end
    benchmark("fields") do |n|
      area.fields
    end
    benchmark("fields=") do |n|
      area.fields = {
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      }
    end
  end

  section "Associations" do
    model_class = Class.new{ include MR::Model }

    benchmark("belongs_to") do |n|
      model_class.belongs_to "belongs_to_#{n}"
    end
    benchmark("has_many") do |n|
      model_class.has_many "has_many_#{n}"
    end
    benchmark("has_one") do |n|
      model_class.has_one "has_one_#{n}"
    end
    benchmark("polymorphic_belongs_to") do |n|
      model_class.polymorphic_belongs_to "polymorphic_belongs_to_#{n}"
    end

    first_area   = Area.new.tap{ |a| a.save }
    second_area  = Area.new.tap{ |a| a.save }
    first_user   = User.new.tap{ |u| u.save }
    second_user  = User.new.tap{ |u| u.save }
    first_image  = Image.new.tap{ |i| i.save }
    second_image = Image.new.tap{ |i| i.save }

    first_user.area  = first_area
    first_user.image = first_image
    first_user.save
    comment = Comment.new.tap do |c|
      c.parent = first_user
      c.save
    end

    benchmark("read belongs to") do |n|
      first_user.area
    end
    benchmark("write belongs to") do |n|
      first_user.area = (n % 2 == 0) ? second_area : first_area
    end
    benchmark("read has many") do |n|
      first_area.users
    end
    benchmark("write has many") do |n|
      first_area.users = (n % 2 == 0) ? [ first_user, second_user ] : [ first_user ]
    end
    benchmark("read has one") do |n|
      first_user.image
    end
    benchmark("write has one") do |n|
      first_user.image = (n % 2 == 0) ? second_image : first_image
    end
    benchmark("read polymorphic belongs to") do |n|
      comment.parent
    end
    benchmark("write polymorphic belongs to") do |n|
      comment.parent = (n % 2 == 0) ? second_user : first_user
    end
  end

  section "Persistence" do
    benchmark("save") do |n|
      area = Area.new({
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
      area.save
    end

    areas = [*1..10000].map do |n|
      area = Area.new({
        :name        => "Name #{n}",
        :active      => (n % 2 == 0),
        :description => "Description #{n}"
      })
      area.save
      area
    end
    benchmark("destroy") do |n|
      areas[n].destroy
    end

    benchmark("valid? and errors") do |n|
      area = Area.new(ValidAreaRecord.new)
      area.valid?
      area.errors
    end
  end

  section "Querying" do
    first_area  = Area.new.tap{ |m| m.save }
    second_area = Area.new.tap{ |m| m.save }

    benchmark("find") do
      Area.find(first_area.id)
    end
    benchmark("all") do
      Area.all
    end
  end

end
