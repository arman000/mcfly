# frozen_string_literal: true

require 'active_support/deprecation'
require 'delorean_lang'

module Mcfly
  INFINITIES = Set[Float::INFINITY, 'infinity', 'Infinity'].freeze

  # Mcfly special columns -- FIXME: should "id" be here?
  COLUMNS = Set[
                'id',
                'group_id',
                'user_id',
                'created_dt',
                'obsoleted_dt',
                'o_user_id',
               ].freeze

  HasMcflyDeprecator = ActiveSupport::Deprecation.new('1.1.0', 'Mcfly')

  def self.infinity?(pt)
    Mcfly::INFINITIES.member? pt
  end
  singleton_class.send(:alias_method, :is_infinity, :infinity?)

  def self.normalize_infinity(pt)
    Mcfly::INFINITIES.member?(pt) ? 'infinity' : pt
  end

  def self.mcfly?(klass)
    # check if a class is mcfly enabled -- FIXME: currently this is
    # checked using MCFLY_UNIQUENESS which is somewhat hacky.
    klass.const_defined? :MCFLY_UNIQUENESS
  end

  def self.has_mcfly?(klass) # rubocop:todo Naming/PredicateName
    mcfly?(klass)
  end
  deprecate has_mcfly?: :mcfly?, deprecator: HasMcflyDeprecator

  def self.mcfly_uniqueness(klass)
    # return uniqueness keys
    klass.const_get :MCFLY_UNIQUENESS
  end

  module Model
    class AssociationValidator < ActiveModel::Validator
      VALSET = Set[nil, Float::INFINITY, 'infinity']

      def validate(entry)
        raise 'need field option' unless options[:field]

        field = options[:field].to_sym
        value = entry.send(field)

        return if value.nil?
        return if VALSET.member?(value.obsoleted_dt)

        entry.errors[field] << "Obsoleted association value of #{field} for #{entry}!"
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_mcfly(options = {}) # rubocop:todo Naming/PredicateName
        mcfly(options)
      end
      deprecate has_mcfly: :mcfly, deprecator: HasMcflyDeprecator

      def mcfly(options = {})
        send :include, InstanceMethods

        before_validation :record_validation
        before_destroy    :allow_destroy if options[:append_only]

        # FIXME: :created_dt should also be readonly.  However, we set
        # it for debugging purposes.  Should consider making this
        # readonly once we're in production.  Also, :user_id should be
        # read-only.  We should only set whodunnit and let PostgreSQL
        # set it.
        attr_readonly :group_id, :obsoleted_dt, :o_user_id # , :user_id
      end

      def mcfly_lookup(name, options = {})
        delorean_fn(name, options) do |ts, *args|
          raise 'time cannot be nil' if ts.nil?

          ts = Mcfly.normalize_infinity(ts)

          where("#{table_name}.obsoleted_dt >= ? AND " \
                     "#{table_name}.created_dt < ?",
                ts,
                ts,
               ).scoping do
            yield(ts, *args)
          end
        end
      end

      def mcfly_validates_uniqueness_of(*attr_names)
        # FIXME: this all looks somewhat hacky since it makes
        # assumptions about the shape of attr_names.  Should, at
        # least, add some assertions here to check the assumptions.

        # Set MCFLY_UNIQUENESS class constant to the args passed.
        # This is useful for introspection.  FIXME: won't work if
        # mcfly_validates_uniqueness_of is called multiple times on
        # the same class.
        attr_list = if attr_names.last.is_a?(Hash)
                      attr_names[0..-2] + (attr_names.last[:scope] || [])
                    else
                      attr_names.clone
                    end
        const_set(:MCFLY_UNIQUENESS, attr_list.freeze)

        # start building arguments to validates_uniqueness_of
        attr_names << {} unless attr_names.last.is_a?(Hash)

        attr_names.last[:scope] ||= []

        # add :obsoleted_dt to the uniqueness scope
        attr_names.last[:scope] << :obsoleted_dt

        # Set uniqueness error message if not set.  FIXME: need to
        # figure out how to change the base message.  It still
        # prepends the pluralized main attr.
        attr_names.last[:message] ||= '- record must be unique'

        validates_uniqueness_of(*attr_names)
      end

      def mcfly_belongs_to(name, options = {})
        validates_with Mcfly::Model::AssociationValidator, field: name
        belongs_to(name, **options)

        # Store child associations for the parent category
        # e.g. if HedgeCost is adding a belong_to assoc to HedgeCostCategory
        # then add HedgeCost and FK to the @@associations array
        reflect_on_all_associations.each do |a|
          next unless a.name == name

          a.klass.class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            @@associations ||= []
            @@associations << [a.active_record, a.foreign_key]
          RUBY
        end
      end

      # Consider having two models: A mcfly_belongs_to B. When A is initialized,
      # model B would have @@associations array, which is used in allow_destroy
      # callback to prevent deletion. But if model A is not initialized
      # (For example with autoloading enabled in dev env) then
      # records from B can be destroyed even if there are some records in A
      # associated with them.
      # That can be fixed by setting mcfly_has_many associations, which would
      # load associated classes right away.
      def mcfly_has_many(name, scope = nil, **options, &extension)
        scope ||= -> { where('obsoleted_dt = ?', 'infinity') }

        has_many(name, scope, **options, &extension).tap do |assoc_list|
          new_assoc = assoc_list[name.to_s]
          new_assoc.klass if new_assoc.respond_to?(:klass)
        end
      end
    end

    module InstanceMethods
      def record_validation
        return unless changed?

        self.user_id = begin
          Mcfly.whodunnit[:id]
        rescue StandardError
          nil
        end

        self.obsoleted_dt ||= 'infinity'
      end

      def allow_destroy
        # checks against registered associations
        if self.class.class_variable_defined?(:@@associations)
          self.class.class_variable_get(:@@associations).each do |klass, fk|
            next unless klass.exists?([
                                        "obsoleted_dt = ? AND #{fk} = ?",
                                        'infinity',
                                        id,
                                      ],
                                     )

            errors.add(:base,
                       "#{self.class.name.demodulize} can't be deleted "\
                       "because #{klass.name.demodulize} records exist",
                      )
            throw :abort
          end
        end

        errors.blank?
      end
    end
  end
end
