require "challenger/version"
require "fileutils"
require "thor"
require "pry-byebug"

module Challenger
  class Builder < Thor::Group
    include Thor::Actions

    def initialize
      super
      puts "Project Name:"
      @project = gets.chomp
      gemspec = "#{@project}.gemspec"

      _run "bundle gem #{@project} --exe --coc --mit --test=rspec"

      FileUtils.cd(@project) do
        _run "sed -i .sav -e 's/TODO/WIP/g' #{gemspec}"
        File.open("Gemfile", "a") do |f|
          f.puts %{gem 'guard-rspec', require: false }
        end

        _run "rvm use ruby-2.3.1@#{@project}"
        _run "bundle"

        write_templates
        FileUtils.mkdir("spec/lib")
        FileUtils.mv("spec/#{@project}_spec.rb", "spec/lib")
        _run "guard"
      end

    end

    def self.source_root
      File.dirname(__FILE__)
    end

    def write_templates
      self.destination_root = "."
      template('challenger/templates/Guardfile.tt', "Guardfile")
      template('challenger/templates/.ruby-version.tt', ".ruby-version")
      template('challenger/templates/.ruby-gemset.tt',
               ".ruby-gemset",
               { name: @project }
              )
    end

    def _run(str)
      puts str
      IO.popen(str).each do |l|
        puts l.chomp
      end
    end
  end

  Builder.new
end
