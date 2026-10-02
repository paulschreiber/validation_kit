# frozen_string_literal: true

require "bundler/gem_tasks"

# `rake release` pushes the current branch and then the version tag. main only
# changes through pull requests, and the commit being released is already on
# it, so push just the tag. Pushing main too made the release fail if main
# moved after the run started (e.g. a merge during the approval wait).
#
# Fails loudly if a Bundler upgrade renames git_push, rather than silently
# going back to pushing main.
unless Bundler::GemHelper.protected_method_defined?(:git_push)
  raise "Bundler::GemHelper#git_push is gone; update the Rakefile"
end

Bundler::GemHelper.prepend(Module.new do
  protected

  def git_push(remote = nil)
    remote ||= default_remote
    sh(%W[git push #{remote} refs/tags/#{version_tag}])
    Bundler.ui.confirm "Pushed release tag."
  end
end)

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
