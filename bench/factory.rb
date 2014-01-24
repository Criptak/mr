$LOAD_PATH.push File.expand_path('../..', __FILE__)
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

  benchmark("date") do
    MR::Factory.date
  end
  benchmark("datetime") do
    MR::Factory.datetime
  end
  benchmark("time") do
    MR::Factory.time
  end
  benchmark("timestamp") do
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
  benchmark("file_name") do
    MR::Factory.file_name
  end
  benchmark("dir_path") do
    MR::Factory.dir_path
  end
  benchmark("file_path") do
    MR::Factory.file_path
  end
  benchmark("binary") do
    MR::Factory.binary
  end

  benchmark("boolean") do
    MR::Factory.boolean
  end

end
