module Mcfly
  module Controller

    def self.included(base)
      base.before_filter :set_mcfly_whodunnit
    end

    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    #
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_mcfly
      current_user rescue nil
    end

    # Tells Mcfly who is responsible for any changes that occur.
    def set_mcfly_whodunnit
      ::Mcfly.whodunnit = user_for_mcfly
    end

  end
end
