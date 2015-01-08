require 'git'
require 'highline/import'

module Skyed
  module Init
    extend self

    def execute(global_options)
      puts 'Initializing...' if !global_options[:quiet]
      repo = get_repo()
      puts repo_path repo
    end

    def get_repo(agree = '.', ask = true)
      repo = is_repo(agree)
      if not repo then
        say("ERROR: #{agree} is not a repository")
        agree = ask("Which is your CM repository? ")
        repo = get_repo(agree, false)
      elsif ask then
        agree = ask("Which is your CM repository? ") { |q| q.default = repo_path(repo).to_s }
        repo = get_repo(agree) if agree != repo_path(repo).to_s
      end
      repo
    end

    def repo_path(repo)
      Pathname.new(repo.repo.path).dirname
    end

    def is_repo(path)
      Git.open(path)
    rescue ArgumentError
      return false
    end
  end
end
