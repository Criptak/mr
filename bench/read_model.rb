$LOAD_PATH.push File.expand_path('../..', __FILE__)
require 'bench/setup'

profiler = Bench::Profiler.new("bench/results/read_model.txt")
profiler.run("MR::ReadModel") do

  section "Fields" do
    read_model_class = Class.new{ include MR::ReadModel }

    benchmark("field") do |n|
      read_model_class.field "field_#{n}", :string
    end
    benchmark("field with select args") do |n|
      read_model_class.field "field_args_#{n}", :string, "column_#{n}"
    end
    benchmark("field with select block") do |n|
      read_model_class.field("field_block_#{n}", :string){ |c| "table.#{c}" }
    end

    read_model_class = Class.new do
      include MR::ReadModel
      field :string,      :string
      field :text,        :text
      field :binary,      :binary
      field :integer,     :integer
      field :primary_key, :primary_key
      field :float,       :float
      field :decimal,     :decimal
      field :datetime,    :datetime
      field :timestamp,   :timestamp
      field :time,        :time
      field :date,        :date
      field :boolean,     :boolean
    end

    benchmark("typecast string") do |n|
      read_model = read_model_class.new('string' => 'String')
      read_model.string
    end
    benchmark("typecast text") do |n|
      read_model = read_model_class.new('text' => 'Text')
      read_model.text
    end
    benchmark("typecast binary") do |n|
      read_model = read_model_class.new('binary' => "\000\001\002\003\004")
      read_model.binary
    end
    benchmark("typecast integer") do |n|
      read_model = read_model_class.new('integer' => '100')
      read_model.integer
    end
    benchmark("typecast primary key") do |n|
      read_model = read_model_class.new('primary_key' => '125')
      read_model.primary_key
    end
    benchmark("typecast float") do |n|
      read_model = read_model_class.new('float' => '6.1370')
      read_model.float
    end
    benchmark("typecast decimal") do |n|
      read_model = read_model_class.new('decimal' => '33.4755926134924')
      read_model.decimal
    end
    benchmark("typecast datetime") do |n|
      read_model = read_model_class.new('datetime' => '2013-11-18 21:29:10')
      read_model.datetime
    end
    benchmark("typecast timestamp") do |n|
      read_model = read_model_class.new('timestamp' => '2013-11-18 22:10:36.660846')
      read_model.timestamp
    end
    benchmark("typecast time") do |n|
      read_model = read_model_class.new('time' => '21:29:10.905011')
      read_model.time
    end
    benchmark("typecast date") do |n|
      read_model = read_model_class.new('date' => '2013-11-18')
      read_model.date
    end
    benchmark("typecast boolean") do |n|
      read_model = read_model_class.new('boolean' => 't')
      read_model.boolean
    end

  end

  section "Querying" do
    read_model_class = Class.new{ include MR::ReadModel }

    benchmark("select") do |n|
      read_model_class.select "column_#{n}"
    end
    benchmark("select with block") do |n|
      read_model_class.select{ |column| "table.#{column}" }
    end
    benchmark("from") do |n|
      read_model_class.from((n % 2 == 0) ? UserRecord : AreaRecord)
    end
    benchmark("joins") do |n|
      read_model_class.joins "table_#{n}"
    end
    benchmark("joins with block") do |n|
      read_model_class.joins{ |table| table }
    end
    benchmark("where") do |n|
      read_model_class.where :column => n
    end
    benchmark("where with block") do |n|
      read_model_class.where{ |value| { :column => value } }
    end
    benchmark("order") do |n|
      read_model_class.order "column_#{n}"
    end
    benchmark("order with block") do |n|
      read_model_class.order{ |column| "table.#{column}" }
    end
    benchmark("group") do |n|
      read_model_class.group "column_#{n}"
    end
    benchmark("group with block") do |n|
      read_model_class.group{ |column| "table.#{column}" }
    end
    benchmark("having") do |n|
      read_model_class.having "COUNT(column_#{n})"
    end
    benchmark("having with block") do |n|
      read_model_class.having{ |column| "COUNT(table.#{column})" }
    end
    benchmark("limit") do |n|
      read_model_class.limit n
    end
    benchmark("limit with block") do |n|
      read_model_class.limit{ |count| count }
    end
    benchmark("offset") do |n|
      read_model_class.offset n
    end
    benchmark("offset with block") do |n|
      read_model_class.offset{ |count| count }
    end
    benchmark("merge") do |n|
      read_model_class.merge((n % 2 == 0) ? UserRecord.scoped : AreaRecord.scoped)
    end
    benchmark("merge with block") do |n|
      read_model_class.merge{ |value| AreaRecord.scoped }
    end

    first_area  = AreaRecord.new(:name => 'Area1').tap{ |a| a.save }
    second_area = AreaRecord.new(:name => 'Area2').tap{ |a| a.save }
    first_user  = UserRecord.new(:name => 'User1').tap do |u|
      u.area = first_area
      u.save
    end
    second_user = UserRecord.new(:name => 'User2').tap do |u|
      u.area = second_area
      u.save
    end

    benchmark("query") do
      UserWithAreaData.query.results
    end
  end

end
