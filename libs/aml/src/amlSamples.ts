const header = `#
# Sample AML
# learn more at https://azimutt.app/aml
#
`

export const samples = {
    empty: {name: 'Empty', content: ''},
    blogBasic: {name: 'Blog', content: `${header}
users
  id uuid pk
  name varchar
  email varchar

posts
  id uuid pk
  title varchar
  content text
  author uuid -> users(id)
  created_at timestamp=\`now()\`

comments
  id uuid pk
  post_id uuid -> posts(id)
  content text
  author uuid -> users(id)
  created_at timestamp=\`now()\`
`},
    blogFull: {name: 'Blog detailed', content: `${header}
users
  id uuid pk
  name varchar index
  email varchar unique
  role user_role(admin, guest)=guest

posts | store all posts
  id uuid pk
  title varchar
  content text | allow markdown formatting
  author uuid -> users(id) # inline relation
  created_at timestamp=\`now()\`

comments
  id uuid pk
  post_id uuid -> posts(id)
  content text
  author uuid -> users(id)
  created_at timestamp=\`now()\`
`},
    ecommerce: {name: 'E-commerce', content: `${header}
identity.users
  id uuid pk
  name varchar index
  email varchar unique
  role user_role(guest, admin)
  created_at timestamp=\`now()\`

identity.credentials
  provider_id provider(email, google, facebook) pk
  provider_key varchar | password for email, user_id for oauth providers
  user_id uuid -> identity.users(id)
  salt varchar nullable | in case of password

catalog.categories
  id uuid pk
  parent_category_id uuid -> catalog.categories(id)
  name varchar
  created_at timestamp=\`now()\`
  created_by uuid -> identity.users(id)

catalog.products
  id uuid pk
  category_id uuid -> catalog.categories(id)
  name varchar index
  description text
  price double
  created_at timestamp=\`now()\`
  created_by uuid -> identity.users(id)

shopping.carts
  id uuid pk
  created_at timestamp=\`now()\`
  created_by uuid -> identity.users(id)

shopping.cart_items
  cart_id uuid pk -> shopping.carts(id)
  product_id uuid pk -> catalog.products(id)
  price double
  quantity int check(\`quantity > 0\`)
  created_at timestamp=\`now()\`
  created_by uuid -> identity.users(id)

billing.orders
  id uuid pk
  created_at timestamp=\`now()\`
  created_by uuid -> identity.users(id)

billing.order_lines
  order_id uuid pk -> billing.orders(id)
  product_id uuid pk -> catalog.products(id)
  price double
  quantity int check(\`quantity > 0\`)

support.reviews
  id uuid pk
  user_id uuid -> identity.users(id)
  product_id uuid -> catalog.products(id)
  rating int | between 1 and 5
  comment text
  created_at timestamp=\`now()\`

tracking.events
  id uuid pk
  item_id uuid
  item_kind varchar

rel tracking.events(item_id) -item_kind=users> identity.users(id)
rel tracking.events(item_id) -item_kind=products> catalog.products(id)
`},
    exhaustive: {name: 'All features', content: `${header}
# a schema using ALL the AML features, not really a meaningful one ^^

type nid bigint # type alias (numeric id)
type user_role (admin, guest) # standalone enum
type position {lat double, lng double} # type struct
type float8_range \`RANGE (subtype = float8, subtype_diff = float8mi)\` # type custom (pg)
type cms.post_status (draft, published) {tags: [seo], deprecated} | state of a post # type with scope, props and doc

users
  id nid pk {autoIncrement}
  name varchar index # single column index
  email varchar unique # single column unique
  role user_role=guest # default value
  settings json nullable # nullable

admins {view: "SELECT id, name, email FROM users WHERE role = 'admin';"} # view entity
  id nid
  name varchar
  email varchar

cms.posts {color: blue, owner: team1, tags: [cms, seo], position: [50, 50], priority: 3} | store all posts # entity props and doc
  id uuid pk
  title varchar(50) check(\`lenght(title) > 10\`) # type with precision, check
  content text {tags: [richText]} | handles markdown # attribute props and doc
  status post_status # FIXME: can't use scoped types :/
  tags "varchar[]"="[]" # type array with default value
  created_by nid -> users(id) # inline relation
  created_at timestamp=\`now()\` # default value as expression

cms.comments {color: blue, deprecated}
  id uuid pk
  content text
  created_by nid

rel cms.comments(created_by) -> users(id) {onDelete: "set null"} | store comment author # standalone relation, relation props and doc

projects
  id uuid pk <> users # inline many-to-many relation with default target attribute
  name varchar index

ax.core.src.events # entity with all scopes (database, catalog and schema)
  id uuid pk
  name varchar
  item_kind event_kind(posts, comments) index=event_item_idx # inline enum, composite index
  item_id uuid index=event_item_idx -item_kind=posts> cms.posts(id) -item_kind=comments> cms.comments(id) # inline polymorphic relation

ax.core.src."events details" as details # special name, entity alias
  id uuid pk -- ax.core.src.events(id) # inline ont-to-one relation
  payload json="{}" # default value for json
    url string # nested attribute
    entities json
      users "json[]"
        id string -> ax.core.src.entities(id) # inline relation from nested field
        name string
        email string
      posts "json[]"
        id string
        name string

rel details(payload.entities.posts.id) -> ax.core.src.entities(id) # standalone relation from nested field

namespace ax.core.src # default scopes for following entities

entities # entity in ax.core.src (inherited from namespace)
  id uuid pk
  name varchar
  details json # deeply nested attributes
    email string
    address object
      street string
      city string
      country string
      pos position
    source string

namespace pro # override previous namespace

organizations
  id bigint pk {autoIncrement}
  name varchar

organization_members
  organization_id bigint pk -> pro.organizations(id) # composite primary key
  user_id bigint pk -> users(id)

member_roles |||
  Multi-line entity doc
  Link to organization_members
|||
  organization_id bigint unique=member_role_id
  user_id bigint unique=member_role_id
  role user_role |||
    attribute multi line doc
    user role for the organization
  |||

rel member_roles(organization_id, user_id) -> pro.organization_members(organization_id, user_id) # composite relation

comments # same entity name, but different schema
  id uuid pk
  content varchar
`},
}
