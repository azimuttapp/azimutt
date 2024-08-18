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

C##INVENTORY.EMPLOYEES
  ID BIGINT pk
  FIRST_NAME VARCHAR index=name
  LAST_NAME VARCHAR index=name
  EMAIL VARCHAR nullable index
  PHONE VARCHAR nullable
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.WAREHOUSES
  ID BIGINT pk
  NAME VARCHAR unique
  ADDRESS GLOBAL_ADDRESS
  MANAGER BIGINT fk C##INVENTORY.EMPLOYEES.ID
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.HALLS
  ID BIGINT pk
  WAREHOUSE_ID BIGINT fk C##INVENTORY.WAREHOUSES.ID
  NAME VARCHAR index
  MANAGER BIGINT fk C##INVENTORY.EMPLOYEES.ID
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.AISLES
  ID BIGINT pk
  HALL_ID BIGINT fk C##INVENTORY.HALLS.ID
  NAME VARCHAR index
  MANAGER BIGINT fk C##INVENTORY.EMPLOYEES.ID
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.RACKS
  ID BIGINT pk
  AISLE_ID BIGINT fk C##INVENTORY.AISLES.ID
  NAME VARCHAR index
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.SHELVES
  ID BIGINT pk
  RACK_ID BIGINT fk C##INVENTORY.RACKS.ID
  NAME VARCHAR index
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.SHELF_POSITIONS
  ID BIGINT pk
  SHELF_ID BIGINT fk C##INVENTORY.SHELVES.ID
  NAME VARCHAR index
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.WAREHOUSE_EMPLOYEES
  WAREHOUSE_ID BIGINT pk fk C##INVENTORY.WAREHOUSES.ID
  EMPLOYEE_ID BIGINT pk fk C##INVENTORY.EMPLOYEES.ID
  ROLE warehouse_role(manager, stocker, loader, receiver)
  START TIMESTAMP nullable
  END TIMESTAMP nullable
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.WAREHOUSE_IDENTITY_PROOFS | how to check the employee is identified, can be several
  WAREHOUSE_ID BIGINT pk fk C##INVENTORY.WAREHOUSES.ID
  EMPLOYEES_ID BIGINT pk fk C##INVENTORY.EMPLOYEES.ID
  KIND identity_proof_kind(name, cni, badge) pk
  VALUE VARCHAR
  EXPIRE TIMESTAMP nullable
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id

C##INVENTORY.BRANDS
  ID BIGINT pk
  SLUG VARCHAR unique | ex: "google"
  NAME VARCHAR unique | ex: "Google"
  CREATED_AT TIMESTAMP
  UPDATED_AT TIMESTAMP
  DELETED_AT TIMESTAMP nullable index

C##INVENTORY.PRODUCTS
  ID BIGINT pk
  SLUG VARCHAR unique | ex: "pixel-8-pro"
  NAME VARCHAR unique | ex: "Pixel 8 Pro"
  BRAND BIGINT nullable fk C##INVENTORY.BRANDS.ID
  CATEGORY VARCHAR nullable | ex: "Phones"
  SUBCATEGORY VARCHAR nullable | ex: "Smartphones"
  WIDTH FLOAT | typical width of the product, see PRODUCTS for the real one
  LENGTH FLOAT | typical length of the product, see PRODUCTS for the real one
  HEIGHT FLOAT | typical height of the product, see PRODUCTS for the real one
  WEIGHT FLOAT | typical weight of the product, see PRODUCTS for the real one
  REMARKS TEXT nullable | ex: fragile
  CREATED_AT TIMESTAMP
  UPDATED_AT TIMESTAMP
  DELETED_AT TIMESTAMP nullable index

C##INVENTORY.PRODUCT_VERSIONS
  ID BIGINT pk
  PRODUCT_ID BIGINT fk C##INVENTORY.PRODUCTS.ID
  SKU VARCHAR(12) unique | internal id
  EAN VARCHAR(13) unique | european id
  NAME VARCHAR unique | ex: "Pixel 8 Pro Menthe 128 Go"
  SPECS JSON | specificities of this version, ex: `{color: "Menthe", storage: 128}`
  WIDTH FLOAT
  LENGTH FLOAT
  HEIGHT FLOAT
  WEIGHT FLOAT
  REMARKS TEXT nullable
  CREATED_AT TIMESTAMP
  UPDATED_AT TIMESTAMP
  DELETED_AT TIMESTAMP nullable index

C##INVENTORY.PHYSICAL_PRODUCTS
  ID BIGINT pk
  PRODUCT_VERSION_ID BIGINT fk C##INVENTORY.PRODUCT_VERSIONS.ID
  SNID VARCHAR(12) unique | serial number of this product
  EXPIRATION TIMESTAMP nullable | when Product has an expiration date, null otherwise
  REMARKS TEXT nullable
  STORED BIGINT nullable fk C##INVENTORY.SHELF_POSITIONS.ID
  CREATED_AT TIMESTAMP
  UPDATED_AT TIMESTAMP
  DELETED_AT TIMESTAMP nullable index

C##INVENTORY.SUPPLIERS
  ID BIGINT pk
  NAME VARCHAR index
  LEVEL INT | the lower, the more priority is given to this supplier
  CURRENCY global_currency(EUR, USD)
  CREATED_AT TIMESTAMP
  UPDATED_AT TIMESTAMP
  DELETED_AT TIMESTAMP nullable index

C##INVENTORY.SUPPLIER_PRICES
  SUPPLIER_ID BIGINT pk fk C##INVENTORY.SUPPLIERS.ID
  PRODUCT_VERSION_ID BIGINT pk fk C##INVENTORY.PRODUCT_VERSIONS.ID
  PRICE DOUBLE
  CREATED_AT TIMESTAMP
  UPDATED_AT TIMESTAMP
  DELETED_AT TIMESTAMP nullable index

C##INVENTORY.SUPPLIER_EMPLOYEES
  SUPPLIER_ID BIGINT pk fk C##INVENTORY.SUPPLIERS.ID
  EMPLOYEE_ID BIGINT pk fk C##INVENTORY.Employees.ID
  ROLE supplier_role(delivery, sale)
  START TIMESTAMP nullable
  END TIMESTAMP nullable
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.PURCHASE_ORDERS
  ID BIGINT pk
  SUPPLIER_ID BIGINT fk C##INVENTORY.SUPPLIERS.ID
  PRICE DOUBLE | total price, computed from items price x quantity
  CURRENCY global_currency(EUR, USD)
  DETAILS TEXT nullable | additional text for the supplier
  NOTES TEXT nullable | internal text for employees
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  SENT_AT TIMESTAMP nullable | can't be updated once sent
  SENT_BY BIGINT nullable fk identity.Users.id
  PAID_AT TIMESTAMP nullable
  DELIVERED_AT TIMESTAMP nullable
  VALIDATED_AT TIMESTAMP nullable
  VALIDATED_BY BIGINT nullable fk identity.Users.id

C##INVENTORY.PURCHASE_ORDER_ITEMS
  PURCHASE_ORDER_ID BIGINT pk fk C##INVENTORY.PURCHASE_ORDERS.ID
  PRODUCT_VERSION_ID BIGINT pk fk C##INVENTORY.PRODUCT_VERSIONS.ID
  QUANTITY INT
  PRICE DOUBLE
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id

C##INVENTORY.DELIVERIES
  ID BIGINT pk
  REASON delivery_reason(supplier_delivery, customer_return, other)
  ACCEPTED BOOLEAN
  PURCHASE_ORDER_ID BIGINT nullable fk C##INVENTORY.PURCHASE_ORDERS.ID
  WAREHOUSE_ID BIGINT fk C##INVENTORY.WAREHOUSE_EMPLOYEES.WAREHOUSE_ID
  WAREHOUSE_EMPLOYEE_ID BIGINT fk C##INVENTORY.WAREHOUSE_EMPLOYEES.EMPLOYEE_ID
  SUPPLIER_ID BIGINT fk C##INVENTORY.SUPPLIER_EMPLOYEES.SUPPLIER_ID
  SUPPLIER_EMPLOYEE_ID BIGINT fk C##INVENTORY.SUPPLIER_EMPLOYEES.EMPLOYEE_ID
  DELIVERED_AT TIMESTAMP

C##INVENTORY.DELIVERY_ITEMS
  DELIVERY_ID BIGINT pk fk C##INVENTORY.DELIVERIES.ID
  PHYSICAL_PRODUCT_ID BIGINT pk fk C##INVENTORY.PHYSICAL_PRODUCTS.ID

C##INVENTORY.PICKUPS
  ID BIGINT pk
  REASON pickup_reason(customer_delivery, supplier_return, other)
  ACCEPTED BOOLEAN
  WAREHOUSE_ID BIGINT fk C##INVENTORY.WAREHOUSE_EMPLOYEES.WAREHOUSE_ID
  WAREHOUSE_EMPLOYEE_ID BIGINT fk C##INVENTORY.WAREHOUSE_EMPLOYEES.EMPLOYEE_ID
  SUPPLIER_ID BIGINT fk C##INVENTORY.SUPPLIER_EMPLOYEES.SUPPLIER_ID
  SUPPLIER_EMPLOYEE_ID BIGINT fk C##INVENTORY.SUPPLIER_EMPLOYEES.EMPLOYEE_ID
  DELIVERED_AT TIMESTAMP

C##INVENTORY.PICKUP_ITEMS
  PICKUP_ID BIGINT pk fk C##INVENTORY.PICKUPS.ID
  PHYSICAL_PRODUCT_ID BIGINT pk fk C##INVENTORY.PHYSICAL_PRODUCTS.ID

C##INVENTORY.INVENTORIES
  ID BIGINT pk
  NAME VARCHAR
  WAREHOUSE_ID BIGINT fk C##INVENTORY.WAREHOUSES.ID
  HALL_ID BIGINT nullable fk C##INVENTORY.HALLS.ID
  AISLE_ID BIGINT nullable fk C##INVENTORY.AISLES.ID
  PLANNED TIMESTAMP nullable
  FINISHED TIMESTAMP nullable
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id

C##INVENTORY.INVENTORY_MEMBERS
  INVENTORY_ID BIGINT pk fk C##INVENTORY.INVENTORIES.ID
  WAREHOUSE_ID BIGINT pk fk C##INVENTORY.WAREHOUSE_EMPLOYEES.WAREHOUSE_ID
  EMPLOYEE_ID BIGINT pk fk C##INVENTORY.WAREHOUSE_EMPLOYEES.EMPLOYEE_ID

C##INVENTORY.INVENTORY_OBSERVATIONS
  ID BIGINT pk
  INVENTORY_ID BIGINT nullable fk C##INVENTORY.INVENTORIES.ID
  PHYSICAL_PRODUCT_ID BIGINT fk C##INVENTORY.PHYSICAL_PRODUCTS.ID
  STATUS INVENTORY_STATUS(missing, broken, degraded)
  MESSAGE TEXT nullable
  CREATED_AT TIMESTAMP
  CREATED_BY BIGINT fk identity.Users.id
  UPDATED_AT TIMESTAMP
  UPDATED_BY BIGINT fk identity.Users.id
  DELETED_AT TIMESTAMP nullable index
  DELETED_BY BIGINT nullable fk identity.Users.id

# Catalog

catalog.categories
  id bigint pk
  parent bigint nullable fk catalog.categories.id
  depth int | easily accessible information of number of parents
  slug varchar unique
  name varchar
  description text nullable
  description_html text nullable
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.products
  id bigint pk fk C##INVENTORY.PRODUCTS.ID
  slug varchar unique
  name varchar
  category_id bigint fk catalog.categories.id
  description text nullable | TODO: handle i18n
  description_html text nullable
  versions json | ex: `[{key: "color", label: "Couleur", values: [{name: "Bleu Azur", value: "#95bbe2"}]}, {key: "storage", name: "Taille", values: [{name: "128GB", value: 128}]}]`
  attributes json | ex: `[{key: "Marque", value: "Google"}]`
  stock int | informative stock, may not be accurate
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.product_versions
  id bigint pk fk C##INVENTORY.PRODUCT_VERSIONS.ID
  product_id bigint fk catalog.products.id
  name varchar
  specs json | ex: `{color: "Bleu Azur", storage: 128}`
  price double
  stock int | informative stock, may not be accurate
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.product_cross_sell_options
  product_id bigint pk fk catalog.products.id
  product_version_id bigint pk fk catalog.product_versions.id
  label varchar
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.product_alternatives
  product_id bigint pk fk catalog.products.id
  alternative_product_id bigint pk fk catalog.products.id
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.assets
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

catalog.category_assets
  category_id bigint pk fk catalog.categories.id
  asset_id bigint pk fk catalog.assets.id
  placement category_asset_placement(banner, icon)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.product_assets
  product_id bigint pk fk catalog.products.id
  asset_id bigint pk fk catalog.assets.id
  placement category_asset_placement(banner, icon)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.product_version_assets
  product_version_id bigint pk fk catalog.product_versions.id
  asset_id bigint pk fk catalog.assets.id
  placement category_asset_placement(banner, icon)
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index

catalog.product_reviews
  id bigint pk
  product_id bigint fk catalog.products.id
  product_version_id bigint nullable fk catalog.product_versions.id
  invoice_id bigint nullable fk billing.Invoices.InvoiceId
  physical_product_id bigint nullable fk C##INVENTORY.PHYSICAL_PRODUCTS.ID
  rating int
  review text nullable
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

catalog.product_review_assets
  product_review_id bigint pk fk catalog.product_reviews.id
  asset_id bigint pk fk catalog.assets.id
  created_at timestamp
  created_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

catalog.product_review_feedbacks
  product_review_id bigint pk fk catalog.product_reviews.id
  kind feedback_kind(like, report)
  created_at timestamp
  created_by bigint pk fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

# Shopping

shopping.carts
  id bigint pk
  owner_kind cart_owner(identity.Devices, identity.Users) | Devices are used for anonymous carts, otherwise it's Users
  owner_id bigint
  expire_at timestamp
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp nullable index
fk shopping.carts.owner_id -> identity.Devices.id
fk shopping.carts.owner_id -> identity.Users.id

shopping.cart_items
  cart_id bigint pk fk shopping.carts.id
  product_version_id bigint pk fk catalog.product_versions.id
  quantity int
  price double | at the time the product was added to the card, prevent price changes after a product has been added to a cart
  created_at timestamp
  created_by bigint nullable fk identity.Users.id
  updated_at timestamp
  updated_by bigint nullable fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

shopping.wishlists
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

shopping.wishlist_items
  wishlist_id bigint pk fk shopping.wishlists.id
  product_id bigint pk fk catalog.products.id
  specs json nullable | if the user saved specific configuration
  created_at timestamp
  created_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

shopping.wishlist_members
  wishlist_id bigint pk fk shopping.wishlists.id
  user_id bigint pk fk identity.Users.id
  rights wishlist_rights(edit, comment, view)
  created_at timestamp
  created_by bigint fk identity.Users.id
  updated_at timestamp
  updated_by bigint fk identity.Users.id
  deleted_at timestamp nullable index
  deleted_by bigint nullable fk identity.Users.id

# Billing

billing.CustomerAddresses
  CustomerAddressesId bigint pk
  Name varchar
  Street varchar
  City varchar
  State varchar
  ZipCode varchar
  Country bigint fk referential.Countries.CountryId
  Complements text nullable
  CreatedAt timestamp
  CreatedBy bigint fk identity.Users.id
  DeletedAt timestamp nullable index
  DeletedBy bigint nullable fk identity.Users.id

billing.Customers
  CustomerId bigint pk
  Name varchar
  BillingAddress bigint nullable fk billing.CustomerAddresses.CustomerAddressesId
  Siret varchar nullable
  TVA varchar nullable
  CreatedAt timestamp
  CreatedBy bigint fk identity.Users.id
  UpdatedAt timestamp
  UpdatedBy bigint fk identity.Users.id
  DeletedAt timestamp nullable index
  DeletedBy bigint nullable fk identity.Users.id

billing.CustomerMembers
  CustomerId bigint pk fk billing.Customers.CustomerId
  UserId bigint pk fk identity.Users.id
  CanEdit boolean
  CanInvite boolean
  CanBuy boolean
  BudgetAllowance int nullable
  CreatedAt timestamp
  CreatedBy bigint fk identity.Users.id
  UpdatedAt timestamp
  UpdatedBy bigint fk identity.Users.id
  DeletedAt timestamp nullable index
  DeletedBy bigint nullable fk identity.Users.id

billing.CustomerPaymentMethods
  CustomerPaymentMethodId bigint pk
  CustomerId bigint fk billing.Customers.CustomerId
  Name varchar
  Kind payment_kind(card, paypal)
  Details json
  CreatedAt timestamp
  CreatedBy bigint fk identity.Users.id
  UpdatedAt timestamp
  UpdatedBy bigint fk identity.Users.id
  DeletedAt timestamp nullable index
  DeletedBy bigint nullable fk identity.Users.id

billing.Invoices
  InvoiceId bigint pk
  Reference varchar unique
  CartId bigint nullable fk shopping.carts.id
  CustomerId bigint fk billing.Customers.CustomerId
  BillingAddress bigint fk billing.CustomerAddresses.CustomerAddressesId
  TotalPrice double
  Currency global_currency(EUR, USD)
  PaidAt timestamp nullable
  CreatedAt timestamp
  CreatedBy bigint nullable fk identity.Users.id

billing.InvoiceLines
  InvoiceId bigint pk fk billing.Invoices.InvoiceId
  Index int pk
  ProductVersionId bigint nullable fk catalog.product_versions.id
  Description text nullable
  Price double
  Quantity int

billing.Payments
  PaymentId bigint pk
  InvoiceId bigint fk billing.Invoices.InvoiceId
  PaymentMethodId bigint nullable fk billing.CustomerPaymentMethods.CustomerPaymentMethodId
  Amount double
  Currency global_currency(EUR, USD)
  CreatedAt timestamp

# Shipping

shipping.Carriers
  id bigint unique=pk
  registration varchar
  cargoWidth float
  cargoLength float
  cargoHeight float
  cargoWeight float
  createdAt timestamp
  createdBy bigint nullable fk identity.Users.id
  updatedAt timestamp
  updatedBy bigint nullable fk identity.Users.id
  deletedAt timestamp nullable index
  deletedBy bigint nullable fk identity.Users.id

shipping.Shipments
  id bigint unique=pk
  carrierId bigint nullable fk shipping.Carriers.id
  createdAt timestamp
  collectedAt timestamp nullable
  collectedBy bigint nullable fk identity.Users.id
  packagedAt timestamp nullable
  packagedBy bigint nullable fk identity.Users.id
  loadedAt timestamp nullable
  loadedBy bigint nullable fk identity.Users.id
  deliveredAt timestamp nullable
  deliveredBy bigint nullable fk identity.Users.id

shipping.ShipmentItems
  shipmentId bigint unique=pk fk shipping.Shipments.id
  physicalProductId bigint unique=pk fk C##INVENTORY.PHYSICAL_PRODUCTS.ID
  invoiceId bigint fk billing.InvoiceLines.InvoiceId
  invoiceLine int fk billing.InvoiceLines.Index
  deliveredAt timestamp nullable
  deliveredTo bigint nullable fk identity.Users.id

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
  owner_kind social_account_owner_kind(People, Organizations) nullable
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
  id uuid unique=pk | UUIDv7 to be time ordered
  name string index | in form of `$context__$object__$action`
  source event_source(website, app, admin, job) | the name of the system which emitted this event
  details json nullable | any additional info for the event
  entities json nullable | {[kind: string]: {id: string, name: string}[]}
  createdAt timestamp
fk analytics.Events.entities:user:id -> identity.Users.id
fk analytics.Events.entities:cart:id -> shopping.carts.id
fk analytics.Events.entities:invoice:id -> billing.Invoices.InvoiceId

analytics.Entities
  kind string unique=pk
  id string unique=pk
  name string
  properties json
  createdAt timestamp
  updatedAt timestamp
fk analytics.Entities.id -> identity.Users.id # when kind=user
fk analytics.Entities.id -> shopping.carts.id # when kind=cart
fk analytics.Entities.id -> billing.Invoices.InvoiceId # when kind=invoice
