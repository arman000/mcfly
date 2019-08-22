# frozen_string_literal: true

require 'mcfly/migration'
require 'mcfly/has_mcfly'
require 'mcfly/controller'
require 'mcfly/version'
require 'active_support'

module Mcfly
  # ATTRIBUTION: some of the code in this project has been shamelessly
  # lifted form paper_trail.

  # Sets who is responsible for any changes that occur.  You would
  # normally use this in a migration or on the console, when working
  # with models directly.
  def self.whodunnit=(value)
    mcfly_store[:whodunnit] = value
    sval = begin
             value[:id]
           rescue StandardError
             -1
           end
    ActiveRecord::Base.connection.execute("SET mcfly.whodunnit = #{sval};")
  end

  def self.whodunnit
    mcfly_store[:whodunnit]
  end

  private

  # Thread-safe hash to hold Mcfly's data.
  def self.mcfly_store
    Thread.current[:mcfly] ||= {}
  end
end

ActiveSupport.on_load(:active_record) do
  include Delorean::Model
  include Mcfly::Model
end

ActiveSupport.on_load(:action_controller) do
  include Mcfly::Controller
end
