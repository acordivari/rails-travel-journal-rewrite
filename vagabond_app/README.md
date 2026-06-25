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

## Architecture

Vagabond is a server-rendered **MVC monolith** on Rails 8. HTML is generated on
the server; Hotwire (Turbo + Stimulus) layers in SPA-like interactivity without a
separate frontend app or build step.

### Domain model

Four ActiveRecord models with straightforward relationships:

```
User ──< Post >── City
 │        │
 │        └──< Comment
 └──────────────┘
```

- A **City** has many posts and a cover image (Active Storage).
- A **User** authors many posts and comments (`has_secure_password`), and has an optional avatar.
- A **Post** belongs to a user and a city, has many comments, and an optional photo.
- A **Comment** belongs to a user and a post.

Referential integrity is enforced at the database level (`NOT NULL` foreign keys),
and `dependent: :destroy` keeps deletes consistent.

### Request flow

```
Browser → Routes → Controller (+ before_action filters) → Model → View / Turbo Stream
                          │
                          ├─ Authentication concern  (current_user, require_login, require_admin)
                          ├─ Service object          (CityImageLookup)
                          └─ Background job           (AttachCityImageJob)
```

- **Routing** (`config/routes.rb`) is RESTful with shallow nesting
  (`cities → posts → comments`). The root path is a dedicated landing page
  (`HomeController#index`) — a hero, featured destinations, and the latest
  stories — distinct from the full `/cities` browse grid.
- **Controllers** stay thin: load records, enforce authorization via the
  `Authentication` concern, and render. Cross-cutting auth/authorization logic
  lives in `app/controllers/concerns/authentication.rb` rather than being
  duplicated per action.
- **Models** hold validations, associations, scopes, and small domain methods
  (e.g. `City#attach_stock_image!`, `Post#excerpt`).
- **Service objects** (`app/services/`) encapsulate logic that doesn't belong in
  a model or controller — currently `CityImageLookup`, the keyless stock-photo
  finder.
- **Background jobs** (`app/jobs/`, Active Job) move slow work off the request
  cycle — `AttachCityImageJob` fetches a city photo after creation.

### View & frontend layer

- **Views** are ERB with heavy use of partials (`app/views/shared/` for the
  navbar, flash, and form errors; `_post_card`, `_city_card`, `_comment`).
- **Turbo** handles navigation and form submissions; comments are added/removed
  via **Turbo Streams** (`app/views/comments/*.turbo_stream.erb`) without a full
  page reload.
- **Stimulus** controllers (`app/javascript/controllers/`) cover small bits of
  client behavior (flash auto-dismiss, image upload preview), loaded over
  **importmap** — no bundler/Node toolchain.
- **Styling** is **Tailwind CSS v4** compiled by `tailwindcss-rails` and served
  through the **Propshaft** pipeline; reusable component classes live in
  `app/assets/tailwind/application.css`.

### Storage & infrastructure

- **PostgreSQL** is the primary datastore (with the `citext` extension for
  case-insensitive email uniqueness).
- **Active Storage** manages uploaded/looked-up images (local disk in
  development; configurable per environment), with on-demand image variants via
  ImageMagick.
- Rails 8's **Solid** stack (Solid Queue/Cache/Cable) is available for
  jobs/cache/websockets in production without extra infrastructure.

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

## City stock images

Cities can carry a cover photo via Active Storage. When an admin creates a city
without uploading one, `AttachCityImageJob` looks up a stock photo by name using
`CityImageLookup` (`app/services/city_image_lookup.rb`) — no API key required:

1. **Wikipedia** REST page summary — the city's lead photo (flags, seals, maps and
   SVG icons are rejected so e.g. Gibraltar gets a view, not its flag).
2. **Openverse** — top openly-licensed photo for the city name.
3. **Picsum** — a deterministic fallback so an image always resolves.

Backfill any cities missing an image:

```bash
bin/rails cities:backfill_images        # only cities without an image
bin/rails cities:backfill_images FORCE=1 # re-fetch all
```

> Active Storage variants use ImageMagick (`mini_magick`); install ImageMagick (or
> switch `config.active_storage.variant_processor` to `:vips` and install libvips).

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
- `app/controllers/home_controller.rb` — landing page (hero, featured cities, latest posts)
- `db/seeds.rb` — 50 top tourism cities (images pulled by name), sample users, posts, and comments
  (set `SKIP_CITY_IMAGES=1` to seed names only and skip the ~50 image lookups)
