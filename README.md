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

Strongbolt has been made to be used with the least configuration possible. If given a tenant, it will traverse the graph of dependencies on this tenant to try to configure all the tenant dependent models authorization check ups. However, some models may be totally independant or not belong to (directly or indirectly) to a tenant. You may also have no tenant at all. In these cases, some or all of your models won't be discovered by Strongbolt when running your app.
To avoid eager loading the whole application to automatically get the list of models, you can specify in the initializer the models of your application.
This list is prefilled when running the install generator.

### Controllers

Strongbolt perform high level authorization on controllers, to avoid testing more granular authorization and increase the performance. For instance, if an user cannot find any Movies, he certainly won't be able to find the movie with the specific id 5.

#### Custom controller actions

Strongbolt relies on the usual Rails restful actions to guess the corresponding model action (edit requires update authorization, new requires create authorization, etc.). However, you will sometimes create other custom actions. In that case, you must specify in the controller how to map these custom controller actions to one of the 4 model actions using:

```ruby
authorize_as_find :action1, :action2
authorize_as_create :action, :action2
authorize_as_update :action, :action2
authorize_as_destroy :action, :action2
```

#### Skipping authorization

You can disable the controller-level authorization checks by using in the controllers:

```ruby
skip_controller_authorization,
skip_controller_authorization, only: [:index]
skip_controller_authorization, except: [:update]
```

You can also specify a list of controllers in the initializer `config/initializers/strongbolt.rb`. It is useful for third-party controllers, like devise for instance. The syntax is:

```ruby
config.skip_controller_authorization_for "Devise::SessionsController", "Devise::RegistrationsController"
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

#### Controller not derived from a Model

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

### Troubleshooting

#### Strongbolt::ModelNotFound

This means Strongbolt is trying to perform some controller-level authorizations but cannot infer the model from the controller name. In that case you must use in this controller:

```ruby
self.model_for_authorization = "Movie"
```

Or skip controller authorizations when it cannot be related to a model or it is not useful (like for Devise controllers), using either one of the methods described in *Skipping Authorization*.

#### Strongbolt::ActionNotConfigured

This happens when a controller is using a custom action which is not one of the 6 usual restful Rails actions (index, new, create, sho, edit, update, destroy). Refer to *Custom controller actions* to fix this.


## Contributing

1. Fork it ( http://github.com/<my-github-username>/strongbolt/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
