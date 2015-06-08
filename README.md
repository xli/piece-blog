Piece Blog is an example application
==================

This application is an example to show how "Piece":https://github.com/ThoughtWorksStudios/piece works.

Basic Requirement
------------------

This is a blog application:

# Everyone can read any blog post.
# Everyone can register as author to write and publish blog post.
# To keep it simple, everyone can also register user as admin role.

Roles and permissions:

# There are three types user: admin, author, anonymous
# Admin user can do everything in application
# Author can create, edit and delete blog post, but can't view/edit/delete user.
# Anonymous user can read blog post and register new user.

Models and controllers:

# We have 2 models and controllers: users and posts
# Posts controller:
    # Blog post CRUD
# Users controller is controlling user
    # User CRUD
    # Login & logout user

Role based user privileges defined by rules
----------------

First, we need to design rules for privileges. In this application, we
can use role based access control to meet our goal.

Anonymous role is straightforward:

    anonymous:
      users: [login, logout, new, create]
      posts: [index, show]

Basically, we just specify what anonymous user can do using controller
name and action name.

To define author role, we'll define another role named 'writer' first:

    writer:
      posts: '*'

('*' is wildcard char in Piece. It means matching everything.)

Then we can combine writer and anonymous role to get author role:

    author: writer + anonymous

Admin role is also simple:

    admin: '*'

In the above example, we used "*" to match all actions in posts
controller. Here we use it to match all controllers and their actions.

Done. Combine them all together:

    writer:
      posts: '*'
    admin: '*'
    author: writer + anonymous
    anonymous:
      users: [login, logout, new, create]
      posts: [index, show]

See config/privileges.yml

User role
------------------

Add role attribute to User model. We use string in this application,
and set it when created user. Then in application we can get user role
by:

    user.role

Authentication
------------------

Piece does not handle authentication. In this application we simply
set session[:current_user_id] when user types in correct user name.
And define current_user helper method in application_controller.rb:

    def current_user
      User.find_by_id(session[:current_user_id])
    end

Authorization
------------------

We can initialize Piece in config/application.rb

    config.privileges_yml = File.read(Rails.root.join('config', 'privileges.yml'))
    config.privileges = Piece.load(config.privileges_yml)

So in ApplicationController, we add:

    before_action :authorize

    ...

    private
    def authorize
      seq = Rails.configuration.privileges[current_action]
      if seq.last == :mismatch
        flash.now[:error] = "You're not authorized to do this action."
        render "layouts/401", status: :unauthorized
      end
    end


The current_action definition is simple and related to how we define rules:

    def current_action
      [current_user.try(:role) || 'anonymous', controller_name, action_name]
    end

This method returns an Array with three elements matching to the
levels we defined in privileges YAML. First one is user role name, we
set it  as 'anonymous' if there is no user logged in. Then second and
third elements are controller name and action name.

Then when you call `Rails.configuration.privileges[current_action]`,
it returns you an array of matching sequence to explain why the
current_action matches or mismatches the rules we defined in
privileges.yml.
The last element in matching sequence is either `:match` or
`:mismatch`. You can also print out the sequence like
app/view/layouts/_matching.html.erb did.
