# frozen_string_literal: true

require 'simplecov'

module SimpleCovHelper
  def self.configure_profile
    SimpleCov.configure do
      # Needed in order to not track installed bundle files in CI
      add_filter '/vendor/ruby/'

      add_group 'Library', 'lib'
      add_group 'Specs', 'spec'
    end
  end

  def self.start!
    return unless ENV['COVERAGE'] == 'true'

    configure_profile

    puts 'Starting SimpleCov...'
    SimpleCov.start
  end
end

SimpleCovHelper.start!
