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

  task "require", ['version'] do |_, args|
    version = args['version']
    files = []
    spec = helper.spec_path
    content = File.read(spec)
    if content.sub!(/\.required_ruby_version *= *Gem::Requirement.new\(">=\s*\K.*(?="\))/) do
         [$&, version].max
       end
      File.write(spec, content)
      files << spec
    end
    min_version = Gem::Version.new(version).segments[0, 2].join(".")
    Dir.glob(".github/workflows/*.yml") do |yml|
      content = File.read(yml)
      if content.sub!(/^( +)ruby-versions:\n(?:(?:\1 +.*)?\n)*?\1 +min_version: \K.*/) do
           [$&, min_version].max
         end
        File.write(yml, content)
        files << yml
      end
    end
    sh(*%w[git commit -m],
       "Update minimum required version to #{version}",
       *files)
  end
end
