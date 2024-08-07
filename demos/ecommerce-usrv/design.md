# Referential

referential.Countries | needs to be referenced for legal reasons
  CountryId bigint pk
  Code varchar
  Name varchar
  CreatedAt timestamp
  DeletedAt timestamp nullable

referential.States | used for auto-competes
  StateId bigint pk
  CountryId bigint fk referential.Countries.CountryId
  Code varchar
  Name varchar
  CreatedAt timestamp
  DeletedAt timestamp nullable

referential.Cities | used for auto-competes
  CityId bigint pk
  StateId bigint fk referential.States.StateId
  Name varchar
  CreatedAt timestamp
  DeletedAt timestamp nullable

# Identity

identity.Users
  id bigint pk
  first_name varchar index=name
  last_name varchar index=name
  username varchar unique
  email varchar unique
  settings json
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

identity.Credentials
  user_id bigint pk fk identity.Users.id
  provider auth_provider(password, google, linkedin, facebook, twitter) pk | the used provider
  provider_id varchar pk | the user id from the provider, in case of password, stores the hashed password with the salt
  provider_data json nullable
  used_last timestamp
  used_count int
  created_at timestamp
  updated_at timestamp | for password change mostly

identity.PasswordResets
  id bigint pk
  email varchar index
  token varchar index | the key sent by email to allow to change the password without being logged
  requested_at timestamp
  expire_at timestamp
  used_at timestamp nullable

identity.Devices | a device is a browser tagged by a random id in its session
  id bigint pk
  sid uuid unique | a unique id stored in the browser to track it when not logged
  user_agent varchar
  created_at timestamp | first time this device is seen

identity.UserDevices | created on user login to know which users are using which devices
  user_id bigint pk fk identity.Users.id
  device_id bigint pk fk identity.Devices.id
  linked_at timestamp | on login
  unlinked_at timestamp nullable | on logout

identity.AuthLogs
  id bigint pk
  user_id bigint nullable fk identity.Users.id
  email varchar nullable
  event auth_event(signup, login_success, login_failure, password_reset_asked, password_reset_used)
  ip varchar
  ip_location geography nullable
  user_agent varchar
  device_id bigint fk identity.Devices.id
  created_at timestamp

identity.TrustedDevices | users can add a device to their trusted ones, so they will have longer session and less security validations
  user_id bigint pk fk identity.Users.id
  device_id bigint fk identity.Devices.id
  name varchar nullable
  kind device_kind(desktop, tablet, phone) nullable
  usage device_usage(perso, pro) nullable
  used_last timestamp
  created_at timestamp
  deleted_at timestamp nullable index

# Inventory

inventory.Brands
  id bigint pk
  slug varchar unique | ex: "google"
  name varchar unique | ex: "Google"
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

inventory.Products
  id bigint pk
  slug varchar unique | ex: "pixel-8-pro"
  name varchar unique | ex: "Pixel 8 Pro"
  brand bigint nullable fk inventory.Brands.id
  category varchar nullable | ex: "Phones"
  subcategory varchar nullable | ex: "Smartphones"
  width float | typical width of the product, see Products for the real one
  length float | typical length of the product, see Products for the real one
  height float | typical height of the product, see Products for the real one
  weight float | typical weight of the product, see Products for the real one
  remarks text nullable | ex: fragile
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

inventory.ProductVersions
  id bigint pk
  product_id bigint fk inventory.Products.id
  sku varchar(12) unique | internal id
  ean varchar(13) unique | european id
  name varchar unique | ex: "Pixel 8 Pro Menthe 128 Go"
  specs json | specificities of this version, ex: `{color: "Menthe", storage: 128}`
  width float
  length float
  height float
  weight float
  remarks text nullable
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

inventory.PhysicalProducts
  id bigint pk
  product_version_id bigint fk inventory.ProductVersions.id
  snid varchar(12) unique | serial number of this product
  expiration timestamp nullable | when Product has an expiration date, null otherwise
  remarks text nullable
  stored bigint nullable fk inventory.ShelfPositions.id
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

inventory.Employees
  id bigint pk
  first_name varchar index=name
  last_name varchar index=name
  email varchar nullable index
  phone varchar nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.Suppliers
  id bigint pk
  name varchar index
  level int | the lower, the more priority is given to this supplier
  currency global_currency(EUR, USD)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

inventory.SupplierPrices
  supplier_id bigint pk fk inventory.Suppliers.id
  product_version_id bigint pk fk inventory.ProductVersions.id
  price double
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

inventory.SupplierEmployees
  supplier_id bigint pk fk inventory.Suppliers.id
  employee_id bigint pk fk inventory.Employees.id
  role supplier_role(delivery, sale)
  start timestamp nullable
  end timestamp nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.PurchaseOrders
  id bigint pk
  supplier_id bigint fk inventory.Suppliers.id
  price double | total price, computed from items price x quantity
  currency global_currency(EUR, USD)
  details text nullable | additional text for the supplier
  notes text nullable | internal text for employees
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  sent_at timestamp nullable | can't be updated once sent
  sent_by bigint nullable fk identity.Users.id
  paid_at timestamp nullable
  delivered_at timestamp nullable
  validated_at timestamp nullable
  validated_by bigint nullable fk identity.Users.id

inventory.PurchaseOrderItems
  purchase_order_id bigint pk fk inventory.PurchaseOrders.id
  product_version_id bigint pk fk inventory.ProductVersions.id
  quantity int
  price double
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id

inventory.Warehouses
  id bigint pk
  name varchar unique
  address global_address
  manager bigint fk inventory.Employees.id
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.Halls
  id bigint pk
  warehouse_id bigint fk inventory.Warehouses.id
  name varchar index
  manager bigint fk inventory.Employees.id
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.Aisles
  id bigint pk
  hall_id bigint fk inventory.Halls.id
  name varchar index
  manager bigint fk inventory.Employees.id
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.Racks
  id bigint pk
  aisle_id bigint fk inventory.Aisles.id
  name varchar index
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.Shelves
  id bigint pk
  rack_id bigint fk inventory.Racks.id
  name varchar index
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.ShelfPositions
  id bigint pk
  shelf_id bigint fk inventory.Shelves.id
  name varchar index
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.WarehouseEmployees
  warehouse_id bigint pk fk inventory.Warehouses.id
  employee_id bigint pk fk inventory.Employees.id
  role warehouse_role(manager, stocker, loader, receiver)
  start timestamp nullable
  end timestamp nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

inventory.WarehouseIdentityProofs | how to check the employee is identified, can be several
  warehouse_id bigint pk fk inventory.Warehouses.id
  employees_id bigint pk fk inventory.Employees.id
  kind identity_proof_kind(name, cni, badge) pk
  value varchar
  expire timestamp nullable
  created_at timestamp
  created_by bigint fk identity.Users.id

inventory.Deliveries
  id bigint pk
  reason delivery_reason(supplier_delivery, customer_return, other)
  accepted boolean
  purchase_order_id bigint nullable fk inventory.PurchaseOrders.id
  warehouse_id bigint fk inventory.WarehouseEmployees.warehouse_id
  warehouse_employee_id bigint fk inventory.WarehouseEmployees.employee_id
  supplier_id bigint fk inventory.SupplierEmployees.supplier_id
  supplier_employee_id bigint fk inventory.SupplierEmployees.employee_id
  delivered_at timestamp

inventory.DeliveryItems
  delivery_id bigint pk fk inventory.Deliveries.id
  physical_product_id bigint pk fk inventory.PhysicalProducts.id

inventory.Pickups
  id bigint pk
  reason pickup_reason(customer_delivery, supplier_return, other)
  accepted boolean
  warehouse_id bigint fk inventory.WarehouseEmployees.warehouse_id
  warehouse_employee_id bigint fk inventory.WarehouseEmployees.employee_id
  supplier_id bigint fk inventory.SupplierEmployees.supplier_id
  supplier_employee_id bigint fk inventory.SupplierEmployees.employee_id
  delivered_at timestamp

inventory.PickupItems
  pickup_id bigint pk fk inventory.Pickups.id
  physical_product_id bigint pk fk inventory.PhysicalProducts.id

inventory.Inventories
  id bigint pk
  name varchar
  warehouse_id bigint fk inventory.Warehouses.id
  hall_id bigint nullable fk inventory.Halls.id
  aisle_id bigint nullable fk inventory.Aisles.id
  planned timestamp nullable
  finished timestamp nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id

inventory.InventoryMembers
  inventory_id bigint pk fk inventory.Inventories.id
  warehouse_id bigint pk fk inventory.WarehouseEmployees.warehouse_id
  employee_id bigint pk fk inventory.WarehouseEmployees.employee_id

inventory.InventoryObservations
  id bigint pk
  inventory_id bigint nullable fk inventory.Inventories.id
  physical_product_id bigint fk inventory.PhysicalProducts.id
  status inventory_status(missing, broken, degraded)
  message text nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

# Catalog

catalog.Categories
  id bigint pk
  parent bigint nullable fk catalog.Categories.id
  depth int | easily accessible information of number of parents
  slug varchar unique
  name varchar
  description text nullable
  description_html text nullable
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.Products
  id bigint pk fk inventory.Products.id
  slug varchar unique
  name varchar
  category_id bigint fk catalog.Categories.id
  description text nullable | TODO: handle i18n
  description_html text nullable
  versions json | ex: `[{key: "color", label: "Couleur", values: [{name: "Bleu Azur", value: "#95bbe2"}]}, {key: "storage", name: "Taille", values: [{name: "128GB", value: 128}]}]`
  attributes json | ex: `[{key: "Marque", value: "Google"}]`
  stock int | informative stock, may not be accurate
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.ProductVersions
  id bigint pk fk inventory.ProductVersions.id
  product_id bigint fk catalog.Products.id
  name varchar
  specs json | ex: `{color: "Bleu Azur", storage: 128}`
  price double
  stock int | informative stock, may not be accurate
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.ProductCrossSellOptions
  product_id bigint pk fk catalog.Products.id
  product_version_id bigint pk fk catalog.ProductVersions.id
  label varchar
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.ProductAlternatives
  product_id bigint pk fk catalog.Products.id
  alternative_product_id bigint pk fk catalog.Products.id
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.Assets
  id bigint pk
  kind asset_kind(picture, video, embed)
  format asset_format(1:1, 16:9)
  size asset_size(low, medium, high, retina)
  path varchar
  alt varchar
  width int
  height int
  weight int
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.CategoryAssets
  category_id bigint pk fk catalog.Categories.id
  asset_id bigint pk fk catalog.Assets.id
  placement category_asset_placement(banner, icon)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.ProductAssets
  product_id bigint pk fk catalog.Products.id
  asset_id bigint pk fk catalog.Assets.id
  placement category_asset_placement(banner, icon)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.ProductVersionAssets
  product_version_id bigint pk fk catalog.ProductVersions.id
  asset_id bigint pk fk catalog.Assets.id
  placement category_asset_placement(banner, icon)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.ProductReviews
  id bigint pk
  product_id bigint fk catalog.Products.id
  product_version_id bigint nullable fk catalog.ProductVersions.id
  invoice_id bigint nullable fk billing.Invoices.id
  physical_product_id bigint nullable fk inventory.PhysicalProducts.id
  rating int
  review text nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

catalog.ProductReviewAssets
  product_review_id bigint pk fk catalog.ProductReviews.id
  asset_id bigint pk fk catalog.Assets.id
  created_at timestamp
  created_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

catalog.ProductReviewFeedbacks
  product_review_id bigint pk fk catalog.ProductReviews.id
  kind feedback_kind(like, report)
  created_at timestamp
  created_by bigint pk fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

# Shopping

shopping.Carts
  id bigint pk
  owner_kind cart_owner(identity.Devices, identity.Users) | Devices are used for anonymous carts, otherwise it's Users
  owner_id bigint
  expire_at timestamp
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index
fk shopping.Carts.owner_id -> identity.Devices.id
fk shopping.Carts.owner_id -> identity.Users.id

shopping.CartItems
  cart_id bigint pk fk shopping.Carts.id
  product_version_id bigint pk fk catalog.ProductVersions.id
  quantity int
  price double | at the time the product was added to the card, prevent price changes after a product has been added to a cart
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

shopping.Wishlists
  id bigint pk
  name varchar
  description text nullable
  public boolean
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

shopping.WishlistItems
  wishlist_id bigint pk fk shopping.Wishlists.id
  product_id bigint pk fk catalog.Products.id
  specs json nullable | if the user saved specific configuration
  created_at timestamp
  created_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

shopping.WishlistMembers
  wishlist_id bigint pk fk shopping.Wishlists.id
  user_id bigint pk fk identity.Users.id
  rights wishlist_rights(edit, comment, view)
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

# Billing

billing.Customers
  id bigint pk
  name varchar
  billing_address bigint nullable fk billing.CustomerAddresses.id
  siret varchar nullable
  tva varchar nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

billing.CustomerMembers
  customer_id bigint pk fk billing.Customers.id
  user_id bigint pk fk identity.Users.id
  can_edit boolean
  can_invite boolean
  can_buy boolean
  budget_allowance int nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

billing.CustomerPaymentMethods
  id bigint pk
  customer_id bigint fk billing.Customers.id
  name varchar
  kind payment_kind(card, paypal)
  details json
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

billing.CustomerAddresses
  id bigint pk
  name varchar
  street varchar
  city varchar
  state varchar
  zipcode varchar
  country bigint fk referential.Countries.CountryId
  complements text nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

billing.Invoices
  id bigint pk
  reference varchar unique
  cart_id bigint nullable fk shopping.Carts.id
  customer_id bigint fk billing.Customers.id
  billing_address bigint fk billing.CustomerAddresses.id
  total_price double
  currency global_currency(EUR, USD)
  paid_at timestamp nullable
  created_at timestamp
  created_by bigint nullable fk identity.Users.id

billing.InvoiceLines
  invoice_id bigint pk fk billing.Invoices.id
  index int pk
  product_version_id bigint nullable fk catalog.ProductVersions.id
  description text nullable
  price double
  quantity int

billing.Payments
  id bigint pk
  invoice_id bigint fk billing.Invoices.id
  payment_method_id bigint nullable fk billing.CustomerPaymentMethods.id
  amount double
  currency global_currency(EUR, USD)
  created_at timestamp

# Shipping

shipping.Carriers
  id bigint pk
  registration varchar
  cargo_width float
  cargo_length float
  cargo_height float
  cargo_weight float
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

shipping.Shipments
  id bigint pk
  carrier_id bigint nullable fk shipping.Carriers.id
  created_at timestamp
  collected_at timestamp nullable
  collected_by bigint nullable fk identity.Users.id
  packaged_at timestamp nullable
  packaged_by bigint nullable fk identity.Users.id
  loaded_at timestamp nullable
  loaded_by bigint nullable fk identity.Users.id
  delivered_at timestamp nullable
  delivered_by bigint nullable fk identity.Users.id

shipping.ShipmentItems
  shipment_id bigint pk fk shipping.Shipments.id
  physical_product_id bigint pk fk inventory.PhysicalProducts.id
  invoice_id bigint fk billing.InvoiceLines.invoice_id
  invoice_line int fk billing.InvoiceLines.index
  delivered_at timestamp nullable
  delivered_to bigint nullable fk identity.Users.id

# CRM

crm.People
  id bigint pk
  name varchar
  email varchar nullable
  phone varchar nullable
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

crm.Organizations
  id bigint pk
  name varchar
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

crm.OrganizationMembers
  person_id bigint pk fk crm.People.id
  organization_id bigint pk fk crm.Organizations.id
  role varchar
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

crm.SocialAccounts
  id bigint pk
  network social_network(twitter, linkedin, facebook, instagram, tiktok, snapchat)
  username varchar
  owner_kind social_account_owner_kind(crm.People, crm.Organizations) nullable
  owner_id bigint nullable
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id
fk crm.SocialAccounts.owner_id -> crm.People.id
fk crm.SocialAccounts.owner_id -> crm.Organizations.id

crm.Campaigns
  id bigint pk
  name varchar
  status campaign_status(draft, live, paused)
  starts timestamp nullable
  ends timestamp nullable
  kind campaign_kind(email, sms, push, twitter, linkedin, instagram, facebook)
  audience text | DSL for selecting the audience, from crm.People for email & sms or from crm.SocialAccounts for others
  subject varchar nullable
  message text nullable | HTML with templating using recipient info
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

crm.CampaignMessages
  id bigint pk
  campaign_id bigint fk crm.Campaigns.id
  contact_id bigint fk crm.People.id
  social_id bigint nullable fk crm.SocialAccounts.id
  sent_to varchar | can be email, phone number, social account... depending on campaign kind
  created_at timestamp
  sent_at timestamp nullable
  opened_at timestamp nullable
  clicked_at timestamp nullable

crm.Issues
  id bigint pk
  subject varchar
  created_at timestamp
  created_by bigint fk identity.Users.id
  closed_at timestamp nullable index
  closed_by bigint nullable fk identity.Users.id

crm.IssueMessages
  id bigint pk
  issue_id bigint fk crm.Issues.id
  content text
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id

crm.IssueMessageReactions
  id bigint pk
  message_id bigint fk crm.IssueMessages.id
  kind reaction_kind(like, dislike)
  created_at timestamp
  created_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

crm.Discounts
  id bigint pk
  name varchar
  description varchar
  kind discount_kind(percentage, amount)
  value double
  enable_at timestamp nullable
  expire_at timestamp nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp
  deleted_by bigint fk identity.Users.id

crm.Coupons
  id bigint pk
  discount_id bigint fk crm.Discounts.id
  code varchar unique | public code to use the discount
  expire_at timestamp nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp
  deleted_by bigint fk identity.Users.id

crm.ProductPicks
crm.LoyaltyCards

# Analytics

analytics.Events
  id uuid pk | UUIDv7 to be time ordered
  name string index | in form of `$context__$object__$action`
  source event_source(website, app, admin, job) | the name of the system which emitted this event
  details json | any additional info for the event
  entities json | {[kind: string]: {id: string, name: string}[]}
  created_at timestamp

analytics.Entities
  id string pk
  kind string
  name string
  properties json
  created_at timestamp
  updated_at timestamp
