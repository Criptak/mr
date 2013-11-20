require 'bench/setup'

profiler = Bench::Profiler.new("bench/results/read_model.txt")
profiler.run("MR::ReadModel") do

  section "Querying" do
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
