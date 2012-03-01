#
# Copyright 2010 Proofpoint, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'rubygems'
require 'bundler'

# This is required because Bundler memoizes its initial configuration,
# which is all fine and dandy for normal operation, but plays hell when
# you want to use it twice within a single ruby invocation for testing.
module Bundler
  class << self
    def reset
      @configured = nil
    end
  end
end

module Proofpoint
  module GemToJarPackager
    class GemRepositoryBuilder
      def build_repository_using_bundler(work_dir, target_dir, gemfile_name, gemfile_lock_name)
        gemfile = Pathname.new(gemfile_name).expand_path

        root = gemfile.dirname

        gemfile_lock = Pathname.new(gemfile_lock_name).expand_path

        ENV['BUNDLE_GEMFILE'] = gemfile

        ENV['BUNDLE_APP_CONFIG'] = work_dir

        Bundler.settings[:path] = target_dir
        Bundler.settings[:disable_shared_gems] = 1

        Bundler.configure

        definition = Bundler::Definition.build(gemfile, gemfile_lock, nil)

        Bundler::Installer::install(root, definition, {})

        gem_repository_location = "#{target_dir}/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}"

        install_gem(gem_repository_location, 'bundler')

        gem_repository_location
      end

      def install_gem(install_dir, gem_name)
        spec, source_uri = Gem::SpecFetcher.fetcher.fetch(Gem::Dependency.new(gem_name)).last

        gem = Gem::RemoteFetcher.new.download(spec, source_uri, install_dir)

        Gem::Installer.new(gem, :force => true, :install_dir => install_dir).install
      end
    end
  end
end
