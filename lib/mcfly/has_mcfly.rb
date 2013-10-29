require 'delorean_lang'

module Mcfly
  module Model
    INFINITIES = Set[Float::INFINITY, 'infinity', 'Infinity']

    class AssociationValidator < ActiveModel::Validator
      VALSET = Set[nil, Float::INFINITY, 'infinity']

      def validate(entry)
        raise "need field option" unless options[:field]
        field = options[:field].to_sym
        value = entry.send(field)

        return if value.nil?

        unless VALSET.member?(value.obsoleted_dt)
          entry.errors[field] = "Obsoleted association value!"
        end
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_mcfly(options = {})
        send :include, InstanceMethods

        before_validation :record_validation
        before_destroy    :allow_destroy if options[:append_only]

        # FIXME: :created_dt should also be readonly.  However, we set
        # it for debugging purposes.  Should consider making this
        # readonly once we're in production.  Also, :user_id should be
        # read-only.  We should only set whodunnit and let PostgreSQL
        # set it.
        attr_readonly :group_id, :obsoleted_dt, :o_user_id #, :user_id
      end

      def mcfly_lookup(name, options = {}, &block)
        delorean_fn(name, options) do |ts, *args|
          raise "time cannot be nil" if ts.nil?

          # normalize infinity
          ts = 'infinity' if Mcfly::Model::INFINITIES.member? ts

          self.where("#{table_name}.obsoleted_dt >= ? AND " +
                     "#{table_name}.created_dt < ?", ts, ts).scoping do
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

      def mcfly_belongs_to(name, options = {})
        validates_with Mcfly::Model::AssociationValidator, field: name
        belongs_to(name, options)

        # Store child associations for the parent category
        # e.g. if HedgeCost is adding a belong_to assoc to HedgeCostCategory
        # then add HedgeCost and FK to the @@associations array
        self.reflect_on_all_associations.each do |a|
          if a.name == name
            a.klass.class_variable_set(:@@associations, []) unless
              a.klass.class_variable_defined?(:@@associations)

            a.klass.class_variable_get(:@@associations) <<
              [a.active_record, a.foreign_key]
          end
        end
      end

    end

    module InstanceMethods
      def record_validation
        if self.changed?
          self.user_id = Mcfly.whodunnit.try(:id)
          self.obsoleted_dt ||= 'infinity'
        end
      end

      def allow_destroy
        # checks against registered associations
        if self.class.class_variable_defined?(:@@associations)
          self.class.class_variable_get(:@@associations).each do |klass, fk|
            self.errors.add :base,
            "#{self.class.name.demodulize} cannot be deleted " +
            "because #{klass.name.demodulize} records exist" if
              klass.where("obsoleted_dt = 'infinity' and
                                     #{fk} = ?", self.id).count > 0
          end
        end

        self.errors.blank?
      end

    end

  end
end
