# frozen_string_literal: true

require 'spec_helper'
require 'kanri/kanri'

class User
    def initialize(id, is_admin = false)
        @id = id
        @admin = is_admin
    end

    def admin?
        @admin
    end

    attr_reader :id
end

class Controller
    include Kanri

    def initialize(user = nil)
        @user = user
    end

    attr_reader :user
end

RSpec.describe Kanri do
    before do
        Kanri.roles.clear
        Controller.role :admin do
            detect { |user, _| user&.admin? }
            can :edit, :delete, User
        end

        Controller.role :owner do
            detect { |user, target| user&.id == target.id }
            can :edit, User
        end

        Controller.role :anyone do
            can :read, User
        end
    end

    let(:user) { User.new(1) }
    let(:other_user) { User.new(2) }
    let(:admin) { User.new(3, true) }

    context 'with implicit' do
        context 'admin user' do
            subject { Controller.new(admin) }
            it 'can read the user' do
                expect(subject.can?(:read, user)).to be true
            end
            it 'can edit the user' do
                expect(subject.can?(:edit, user)).to be true
            end
            it 'can delete the user' do
                expect(subject.can?(:delete, user)).to be true
            end
        end

        context 'owner user' do
            subject { Controller.new(user) }
            it 'can read the user' do
                expect(subject.can?(:read, user)).to be true
            end
            it 'can edit the user' do
                expect(subject.can?(:edit, user)).to be true
            end
            it 'cannot delete the user' do
                expect(subject.can?(:delete, user)).to be false
            end
        end

        context 'unrelated user' do
            subject { Controller.new(other_user) }
            it 'can read the user' do
                expect(subject.can?(:read, user)).to be true
            end
            it 'cannot edit the user' do
                expect(subject.can?(:edit, user)).to be false
            end
            it 'cannot delete the user' do
                expect(subject.can?(:delete, user)).to be false
            end
        end
    end

    context 'with explicit' do
        subject { Controller.new }

        context 'admin user' do
            it 'can read the user' do
                expect(subject.can?(:read, user, user: admin)).to be true
            end
            it 'can edit the user' do
                expect(subject.can?(:edit, user, user: admin)).to be true
            end
            it 'can delete the user' do
                expect(subject.can?(:delete, user, user: admin)).to be true
            end
        end

        context 'owner user' do
            it 'can read the user' do
                expect(subject.can?(:read, user, user: user)).to be true
            end
            it 'can edit the user' do
                expect(subject.can?(:edit, user, user: user)).to be true
            end
            it 'cannot delete the user' do
                expect(subject.can?(:delete, user, user: user)).to be false
            end
        end

        context 'unrelated user' do
            it 'can read the user' do
                expect(subject.can?(:read, user, user: other_user)).to be true
            end
            it 'cannot edit the user' do
                expect(subject.can?(:edit, user, user: other_user)).to be false
            end
            it 'cannot delete the user' do
                expect(subject.can?(:delete, user, user: other_user))
                    .to be false
            end
        end
    end

    context 'with nil user' do
        subject { Controller.new }

        it 'can read the user' do
            expect(subject.can?(:read, user, user: nil)).to be true
        end
        it 'cannot edit the user' do
            expect(subject.can?(:edit, user, user: nil)).to be false
        end
        it 'cannot delete the user' do
            expect(subject.can?(:delete, user, user: nil))
                .to be false
        end
    end
end
