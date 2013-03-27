require 'delorean_lang'

module McFly
  module Model
    
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_mcfly(options = {})
        # FIXME: this methods gets a append_only option sometimes.  It
        # needs to add model level validations which prevent update
        # when this option is present. Note that we need to allow
        # delete.  Deletion of McFly objects obsoletes them by setting
        # obsoleted_dt.

        send :include, InstanceMethods
        after_initialize :record_init
        # FIXME: :created_dt should also be readonly.  However, we set
        # it for debugging purposes.  Should consider making this
        # readonly once we're in production.
        attr_readonly :group_id, :obsoleted_dt, :user_id
      end

      def mcfly_lookup(name, options = {}, &block)
        delorean_fn(name, options) do |ts, *args|
          raise "time cannot be nil" if ts.nil?
          self.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts).scoping do
            block.call(ts, *args)
          end
        end
      end

      def mcfly_validates_uniqueness_of(*attr_names)
        # Set MCFLY_UNIQUENESS class constant to the args passed.
        # This is useful for introspection.  FIXME: won't work if
        # mcfly_validates_uniqueness_of is called multiple times on
        # the same class.
        self.const_set(:MCFLY_UNIQUENESS, attr_names)

        attr_names << {} unless attr_names.last.is_a?(Hash)

        attr_names.last[:scope] ||= []

        # add :obsoleted_dt to the uniqueness scope
        attr_names.last[:scope] << :obsoleted_dt
        
        # Set uniqueness error message if not set.  FIXME: need to
        # figure out how to change the base message.  It still
        # prepends the pluralized main attr.
        attr_names.last[:message] ||= "- record must be unique"

        validates_uniqueness_of(*attr_names)
      end
    end

    module InstanceMethods
      def record_init
        # Set obsoleted_dt to non NIL to ensure constraints are properly
        # constructed
        self.obsoleted_dt = 'infinity' unless self.obsoleted_dt
        self.user_id ||= Mcfly.whodunnit.try(:id)
      end
    end
    
  end
end
