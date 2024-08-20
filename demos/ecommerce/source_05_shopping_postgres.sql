-- drop everything
DROP SCHEMA IF EXISTS shopping CASCADE;
CREATE SCHEMA shopping;


-- create the database
CREATE TABLE shopping.carts (
    id         BIGINT PRIMARY KEY,
    owner_kind VARCHAR(255),
    owner_id   BIGINT,
    expire_at  TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);
CREATE INDEX idx_carts_deleted_at ON shopping.carts (deleted_at);
COMMENT ON COLUMN shopping.carts.owner_kind IS 'Devices are used for anonymous carts, otherwise it''s Users';

CREATE TABLE shopping.cart_items (
    cart_id            BIGINT REFERENCES shopping.carts (id),
    product_version_id BIGINT,
    quantity           INT,
    price              DOUBLE PRECISION,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by         BIGINT,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by         BIGINT,
    deleted_at         TIMESTAMP,
    deleted_by         BIGINT,
    PRIMARY KEY (cart_id, product_version_id)
);
CREATE INDEX idx_cart_items_deleted_at ON shopping.cart_items (deleted_at);
COMMENT ON COLUMN shopping.cart_items.price IS 'at the time the product was added to the card, prevent price changes after a product has been added to a cart';

CREATE TABLE shopping.wishlists (
    id          BIGINT PRIMARY KEY,
    name        VARCHAR(255),
    description TEXT,
    public      BOOLEAN,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by  BIGINT,
    deleted_at  TIMESTAMP,
    deleted_by  BIGINT
);
CREATE INDEX idx_wishlists_deleted_at ON shopping.wishlists (deleted_at);

CREATE TABLE shopping.wishlist_items (
    wishlist_id BIGINT REFERENCES shopping.wishlists (id),
    product_id  BIGINT,
    specs       JSON,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT,
    deleted_at  TIMESTAMP,
    deleted_by  BIGINT,
    PRIMARY KEY (wishlist_id, product_id)
);
CREATE INDEX idx_wishlist_items_deleted_at ON shopping.wishlist_items (deleted_at);
COMMENT ON COLUMN shopping.wishlist_items.specs IS 'if the user saved specific configuration';

CREATE TABLE shopping.wishlist_members (
    wishlist_id BIGINT REFERENCES shopping.wishlists (id),
    user_id     BIGINT,
    rights      VARCHAR(50),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by  BIGINT,
    deleted_at  TIMESTAMP,
    deleted_by  BIGINT,
    PRIMARY KEY (wishlist_id, user_id)
);
CREATE INDEX idx_wishlist_members_deleted_at ON shopping.wishlist_members (deleted_at);


-- insert some data
INSERT INTO shopping.carts (id, owner_kind, owner_id, expire_at)
VALUES (1, 'identity.Users', 1, CURRENT_TIMESTAMP + INTERVAL '1 day'),
       (2, 'identity.Devices', 1, CURRENT_TIMESTAMP + INTERVAL '1 day');

INSERT INTO shopping.cart_items (cart_id, product_version_id, quantity, price, created_by, updated_by)
VALUES (1, 1, 2, 899.99, 1, 1),
       (2, 2, 1, 1099.99, 2, 2);

INSERT INTO shopping.wishlists (id, name, description, public, created_by, updated_by)
VALUES (1, 'John''s Wishlist', 'John''s favorite products', TRUE, 1, 1),
       (2, 'Jane''s Wishlist', 'Jane''s favorite products', FALSE, 2, 2);

INSERT INTO shopping.wishlist_items (wishlist_id, product_id, specs, created_by)
VALUES (1, 1, '{"color": "Menthe", "storage": 128}', 1),
       (2, 2, '{"color": "Noir", "storage": 256}', 2);

INSERT INTO shopping.wishlist_members (wishlist_id, user_id, rights, created_by, updated_by)
VALUES (1, 1, 'edit', 1, 1),
       (2, 2, 'view', 2, 2);
