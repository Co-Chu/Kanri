# frozen_string_literal: true

# Kanri Authorization Framework
#
# Kanri (lit. management) is a minimalist authorization framework inspired by
# others such as Kan and Pundit. It aims to accomplish most basic authorization
# tasks in as simple a manner as possible, without sacrificing functionality.
#
# @author Matthew Lanigan <rintaun@gmail.com>
# @since 1.0.0
# @example Simple role definition
#   class SomeClass
#       include Kanri
#
#       role :admin do
#           detect { |user, _| user.admin? }
#           can :edit, Object
#       end
#       role :anyone do
#           can :read, Object
#       end
#   end
#
#   some_obj = SomeClass.new
#   some_obj.can?(:edit, some_object, user: some_admin) # => true
module Kanri
    class << self
        # All defined roles.
        #
        # @!attribute [r] roles
        # @return [Array<Role>]
        def roles
            @roles ||= []
        end

        # Handle mixin inclusion
        #
        # Called when the Kanri module is included for the `#can?` instance
        # method mixin. Extends the other module to use the `Kanri::Roles`
        # singleton method mixin.
        #
        # @see Kanri::Roles
        def included(othermod)
            othermod.extend(Roles)
        end
    end

    # Determines if an `action` can be performed on the given `target` by the
    # `user`
    #
    # If the instance calling this method responds to the `#user` method, and no
    # `user` is explicitly passed, the output of the `#user` method will be used
    # instead.
    #
    # @api Authorization
    # @see Role#can?
    # @param action [Symbol] the action being performed
    # @param target [Object] the target of the action
    # @param user [Object, nil] the user performing the action or nil for
    #   delegated user determination
    # @return [Type] description_of_returned_object
    def can?(action, target, user: nil)
        user ||= respond_to?(:user) ? self.user : nil
        Kanri.roles
             .select { |role| role.include? user, target }
             .any? { |role| role.can? user, action, target }
    end

    # Singleton methods to be extended as a mixin
    module Roles
        # Defines a new role
        #
        # @api RoleDefinition
        # @see Role#initialize
        # @param name [Symbol] the name of the role
        # @param actions [Proc] actions to perform defining the role; passed to
        #   {Role#initialize}
        # @return [void]
        def role(name, &actions)
            role = Role.new(name, &actions)
            Kanri.roles.push role
        end
    end

    # Container for permissions
    #
    # @api private
    class Permissions
        # @param actions [Symbol...] one or more actions to allow
        # @yieldparam user [Object] the user performing the action
        # @yieldparam target [Object] the target of the action
        # @yieldreturn [Boolean] whether to grant permission for the action
        def initialize(*actions, &condition)
            @actions = actions
            @condition = condition || proc { true }
        end

        # Checks if the given `action` is included in the permission
        #
        # @param action [Symbol] the action being performed
        # @return [Boolean] whether the action is covered
        def has_action?(action)
            @actions.include? action
        end

        # Checks whether the specific permissions instance allows the user
        # to act on the target.
        #
        # @see #initialize
        # @param user [Object] the user performing the action
        # @param target [Object] the target of the action
        # @return [Boolean] whether permission is granted
        def allow?(user, target)
            @condition.call(user, target)
        end
    end

    # Container for role permissions
    #
    # @api private
    class Role
        # @return [Symbol] name of the role
        attr_reader :name

        # @param name [Symbol] the name of the role
        # @param actions [Proc] actions to perform defining the role
        def initialize(name, &actions)
            @name = name
            return if actions.nil?
            dsl = RoleDSL.new(&actions)
            RoleDSL.convert(dsl, self)
        end

        # Identifies if the role allows the given `user` to perform the
        # specified `action` on the given `target`.
        #
        # == Algorithm
        #
        # The order of operations is as follows:
        #
        #   1. Check if the target is a class for which the role has
        #      permissions.
        #   2. Check if the action is covered by permissions for the target
        #      class.
        #   3. Check if any of the matching permissions allow the given
        #      user to act on the specific target object.
        #
        # @param user [Object] the user performing the action
        # @param action [Symbol] the action being performed
        # @param target [Object] the target of the action
        # @return [Boolean] whether the `user` has permission to perform the
        #   `action` on the `target`
        def can?(user, action, target)
            @permissions.select { |klass, _| target.is_a? klass }
                        .collect { |_, perms| perms }
                        .flatten
                        .select { |perm| perm.has_action? action }
                        .any? { |perm| perm.allow? user, target }
        end

        # Determines whether the given user/target combination should be
        # considered a member of the role.
        #
        # == Usage
        #
        # If the first parameter is a symbol, it will be checked against the
        # `name` attribute; in this case, the second parameter is not
        # required.
        #
        # Otherwise, it us considered a `user` and passed to the `@detect`
        # proc.
        #
        # @param user [Object] the user performing the action
        # @param target [Object] the target of the action
        # @return [Boolean] whether the given user/target is considered a
        #   member of the role
        def include?(user, target)
            @detect.call(user, target)
        end
    end

    # DSL for defining roles
    #
    # @api private
    class RoleDSL
        class << self
            # Copies instance variables from the `dsl` to the `target`
            #
            # @param dsl [RoleDSL] the DSL to convert
            # @param target [Object] the target of the conversion
            # @return [void]
            def convert(dsl, target)
                dsl.instance_variables.each do |var|
                    val = dsl.instance_variable_get var
                    target.instance_variable_set var, val
                end
            end
        end

        # @param actions [Proc] actions to be performed in the dsl
        def initialize(&actions)
            @permissions = Hash.new { |h, k| h[k] = [] }
            @detect = proc { true }
            instance_eval(&actions)
        end

        # Sets the block used to determine members of the role.
        #
        # @api RoleDefinition
        # @see Role#include?
        # @yieldparam user [Object] the user performing the action
        # @yieldparam target [Object] the arget of the action
        # @return [void]
        def detect(&condition)
            @detect = condition
        end

        # Adds a permission to the role.
        #
        # @api RoleDefinition
        # @see Permissions#initialize
        # @param actions [Symbol...] one or more actions to allow
        # @param target [Class] the class of applicable targets
        # @yieldparam user [Object] the user performing the action
        # @yieldparam target [Object] the target of action
        # @yieldreturn [Boolean] whether or not to grant permission for the
        #   action
        # @return [void]
        def can(*actions, target, &condition)
            perm = Permissions.new(*actions, &condition)
            @permissions[target].push perm
        end
    end
end
