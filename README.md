# Kanri

Kanri (lit. management) is a minimalist authorization framework inspired by
others such as Kan and Pundit. It aims to accomplish most basic authorization
tasks in as simple a manner as possible, without sacrificing functionality.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kanri', git: 'https://github.com/Co-Chu/Kanri'
```

And then execute:

    $ bundle

## Usage

Kanri authorizes actions based on roles defined in a class. For example:

```ruby
class SomeClass
    include Kanri

    role :admin do
        detect { |user, _| user.admin? }
        can :edit, Object
    end
    role :anyone do
        can :read, Object
    end
end

some_obj = SomeClass.new
some_obj.can?(:edit, some_object, user: some_admin) # => true
```

Role names are not currently used for anything in particular other than adding a
readable tag to the permissions group.

## Contributing

Bug reports and pull requests are welcome at [Kanri on GitHub][github]. This
project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor Covenant][covenant] code
of conduct.

## License

The gem is available as open source under the terms of the
[MIT License][license].

## Code of Conduct

Everyone interacting in the Kanri project’s codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of conduct][conduct].

[github]: https://github.com/Co-Chu/Kanri
[covenant]: http://contributor-covenant.org
[license]: https://github.com/Co-Chu/Kanri/blob/master/LICENSE.md
[conduct]: https://github.com/Co-Chu/Kanri/blob/master/CODE_OF_CONDUCT.md
