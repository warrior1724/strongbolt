# Strongbolt

RBAC framework for model-level authorization gem with very granular control on permissions, using Capabilities, Roles and UserGroups.

Only works with Rails 4.

## Installation

Add this line to your application's Gemfile:

    gem 'grant', '>= 2.2', git: "git@github.com:AnalyticsMediaGroup/grant.git"
    gem 'strongbolt', git: "git@github.com:AnalyticsMediaGroup/strongbolt.git"

And then execute:

    $ bundle

## Getting Started

To creates the required migrations, run:

    $ rails g strongbolt:install && rake db:migrate

To create a Role and User Group that has full access and assign the group to all users (this allow to get started using StrongBolt), run:

    $ rake strongbolt:seed

## Usage

### Configuration

The initializer of strongbolt, `config/initializers/strongbolt.rb` has some included documentation to help you with configuring the little you need to for Strongbolt to work.

By default, the user class is `User` and there is no tenant set.

#### A note on the list of models

Strongbolt has been made to be used with the least configuration possible. If given a tenant, it will traverse the graph of dependencies on this tenant to try to find the models of your application. However, some models may be totally independant or not belong to (directly or indirectly) to a tenant. You may also have no tenant at all.
In that case, you should list all the models used by your application as Strongbolt as there's no sure way to automatically get the list of them (if you're using third-party gem with models included for instance).
This can be done in the initializer of stronbolt.

### Controllers

Strongbolt perform high level authorization on controllers, to avoid testing more granular authorization and increase the performance. For instance, if an user cannot find any Movies, he certainly won't be able to find the movie with the specific id 5.

You can disable the high level authorization checks by using:

```ruby
skip_controller_authorization,
skip_controller_authorization, only: [:index]
skip_controller_authorization, except: [:update]
```

You can also skip ALL authorization checks (BAD IDEA) using:

```ruby
skip_all_authorization
skip_all_authorization, only: [:index]
skip_all_authorization, except: [:update]
```

Sometimes you may want to render the views without checking again every single instance you're displaying (for the list of movies for instance, if the user can find ALL movies no need to test separatly each of them). You can skip the authorization checks when rendering pages by using:

```ruby
render_without_authorization :index, :show
```

Be careful when using one of this skipping authorization check as it may result in leaked data.

Usually most of your controllers, in a RestFUL design, are backed by a specific model, derived from the name of the controller. In that case Strongbolt will know what model authorization it should test against. Otherwise, it will raise an error unless you specify the model for authorization:

```ruby
self.model_for_authorization = "Movie"
```

### Models

Usually you will never need to configure anything on the models. In some cases though, to simplify the roles and permissions, you may want to authorize some models as if they were other models (in nested models, sometimes it is safe to assume that the lower level model should have the same permissions than its parent)>
To achieve this, use the following within your model:

```ruby
authorize_as "Movie"
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/strongbolt/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
