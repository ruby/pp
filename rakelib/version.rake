class << (helper = Bundler::GemHelper.instance)
  SOURCE_PATH = "lib/pp.rb"
  VERSION_PATTERN = /^\s*VERSION\s*=\s*(["'])\K.*?(?=\1)/

  def update_source_version(path = SOURCE_PATH, pattern = VERSION_PATTERN)
    File.open(path, "r+b") do |f|
      d = f.read
      if d.sub!(pattern) {version.to_s}
        f.rewind
        f.truncate(0)
        f.print(d)
      end
    end
  end

  def commit_bump
    sh(%W[git commit -m Bump\ up\ to\ #{gemspec.version}
          #{SOURCE_PATH}])
  end

  def version=(v)
    gemspec.version = v
    update_source_version
    commit_bump
  end
end

major, minor, teeny, dev = helper.gemspec.version.segments

namespace :dev do
  task "bump:teeny", ['dev'] do |_, args|
    dev = args[:dev] and dev = ".#{dev}"
    helper.version = Gem::Version.new("#{major}.#{minor}.#{teeny+1}#{dev}")
  end

  task "bump:minor", ['dev'] do |_, args|
    dev = args[:dev] and dev = ".#{dev}"
    helper.version = Gem::Version.new("#{major}.#{minor+1}.0#{dev}")
  end

  task "bump:major", ['dev'] do |_, args|
    dev = args[:dev] and dev = ".#{dev}"
    helper.version = Gem::Version.new("#{major+1}.0.0#{dev}")
  end

  task "bump" => "bump:teeny"

  task "tag" do
    helper.__send__(:tag_version)
  end
end
