# Strongbolt

RBAC framework for model-level authorization gem with very granular control on permissions, using Capabilities, Roles and UserGroups.

Only works with Rails 4.

## Installation

Add this line to your application's Gemfile:

    gem 'grant', '>= 2.2', git: "git@github.com:AnalyticsMediaGroup/grant.git"
    gem 'strongbolt', git: "git@github.com:AnalyticsMediaGroup/strongbolt.git"

And then execute:

    $ bundle

## Usage

To creates the required migrations, run:

    $ rails g strongbolt:install && rake db:migrate

## Contributing

1. Fork it ( http://github.com/<my-github-username>/strongbolt/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
