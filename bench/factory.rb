require 'bench/setup'

profiler = Bench::Profiler.new("bench/results/factory.txt")
profiler.run("MR::Factory") do
  MR::Factory.type_converter # memoize this

  benchmark("primary_key new provider") do |n|
    MR::Factory.primary_key("bench script #{n}")
  end
  MR::Factory.primary_key('bench script')
  benchmark("primary_key existing provider") do |n|
    MR::Factory.primary_key('bench script')
  end

  benchmark("integer") do
    MR::Factory.integer
  end
  benchmark("float") do
    MR::Factory.float
  end
  benchmark("decimal") do
    MR::Factory.decimal
  end

  benchmark("date new") do
    MR::Factory.date
    MR::Factory.instance_variable_set("@date", nil)
  end
  MR::Factory.date
  benchmark("date existing") do
    MR::Factory.date
  end

  benchmark("datetime new") do
    MR::Factory.datetime
    MR::Factory.instance_variable_set("@datetime", nil)
  end
  MR::Factory.datetime
  benchmark("datetime existing") do
    MR::Factory.datetime
  end

  benchmark("time new") do
    MR::Factory.time
    MR::Factory.instance_variable_set("@time", nil)
  end
  MR::Factory.time
  benchmark("time existing") do
    MR::Factory.time
  end

  benchmark("timestamp new") do
    MR::Factory.timestamp
    MR::Factory.instance_variable_set("@timestamp", nil)
  end
  MR::Factory.timestamp
  benchmark("timestamp existing") do
    MR::Factory.timestamp
  end

  benchmark("string") do
    MR::Factory.string
  end
  benchmark("text") do
    MR::Factory.text
  end
  benchmark("slug") do
    MR::Factory.slug
  end
  benchmark("hex") do
    MR::Factory.slug
  end
  benchmark("binary") do
    MR::Factory.binary
  end

  benchmark("boolean") do
    MR::Factory.boolean
  end

end
