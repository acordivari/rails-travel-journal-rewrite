# Vagabond

A travel-journaling web app: members write **posts** (travel stories) about **cities**, and discuss them in **comments**. Rebuilt on a modern Rails 8 stack.

> This is a ground-up modernization of the original **[andrewdc92/Vagabond](https://github.com/andrewdc92/Vagabond)** (Rails 5.0 / Ruby 2.3). The rewrite upgrades to Rails 8 / Ruby 3.3, adds Hotwire, Tailwind, Active Storage, comments, server-side authorization, and a full RSpec suite. See [andrewdc92/Vagabond](https://github.com/andrewdc92/Vagabond) for the original.

## Stack

- **Ruby** 3.3 / **Rails** 8.0
- **PostgreSQL** (with the `citext` extension for case-insensitive emails)
- **Hotwire** (Turbo + Stimulus) over **importmap** — no Node build step
- **Propshaft** asset pipeline + **Tailwind CSS v4**
- **Active Storage** for city/post/avatar image uploads
- **RSpec** + **FactoryBot** for tests; **RuboCop** (omakase) + **Brakeman** for quality/security

## Getting started

Requires Ruby 3.3.0 and a running PostgreSQL server.

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev          # starts Rails + the Tailwind watcher (see Procfile.dev)
```

Then visit http://localhost:3000.

The seed data creates three users. Demo login:

| Email               | Password   | Role  |
| ------------------- | ---------- | ----- |
| `alex@example.com`  | `password` | admin |
| `mai@example.com`   | `password` | user  |
| `sam@example.com`   | `password` | user  |

> `bin/dev` runs the Tailwind watcher. If you only run `bin/rails server`, build the
> stylesheet once with `bin/rails tailwindcss:build`.

## Authorization model

- **Guests** can browse cities, posts, and profiles.
- **Members** can create posts and comments, and edit/delete their own.
- **Admins** can additionally add/delete cities and remove any user, post, or comment.

Authorization is enforced in controllers via `before_action` filters
(`app/controllers/concerns/authentication.rb`), not just hidden in views.

## Tests & checks

```bash
bundle exec rspec       # full test suite
bundle exec rubocop     # style
bundle exec brakeman    # security scan
```

## Project layout highlights

- `app/models/` — `User`, `City`, `Post`, `Comment` with validations, associations, and attachments
- `app/controllers/concerns/authentication.rb` — session auth + authorization helpers
- `app/views/shared/` — layout partials (`navbar`, `flash`, `form_errors`)
- `app/javascript/controllers/` — Stimulus controllers (`flash`, `preview`)
- `db/seeds.rb` — sample users, cities (with images), posts, and comments
