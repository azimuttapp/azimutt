-- drop everything
DROP SCHEMA IF EXISTS catalog CASCADE;
CREATE SCHEMA catalog;


-- create the database
CREATE TABLE catalog.categories
(
    id               BIGINT PRIMARY KEY,
    parent           BIGINT REFERENCES catalog.categories (id),
    depth            INT,
    slug             VARCHAR(255) UNIQUE,
    name             VARCHAR(255),
    description      TEXT,
    description_html TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at       TIMESTAMP
);

CREATE INDEX idx_categories_deleted_at ON catalog.categories (deleted_at);

CREATE TABLE catalog.products
(
    id               BIGINT PRIMARY KEY,
    slug             VARCHAR(255) UNIQUE,
    name             VARCHAR(255),
    category_id      BIGINT REFERENCES catalog.categories (id),
    description      TEXT,
    description_html TEXT,
    versions         JSON,
    attributes       JSON,
    stock            INT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at       TIMESTAMP
);

CREATE INDEX idx_products_deleted_at ON catalog.products (deleted_at);

CREATE TABLE catalog.product_versions
(
    id         BIGINT PRIMARY KEY,
    product_id BIGINT REFERENCES catalog.products (id),
    name       VARCHAR(255),
    specs      JSON,
    price      DOUBLE PRECISION,
    stock      INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_product_versions_deleted_at ON catalog.product_versions (deleted_at);

CREATE TABLE catalog.product_cross_sell_options
(
    product_id         BIGINT REFERENCES catalog.products (id),
    product_version_id BIGINT REFERENCES catalog.product_versions (id),
    label              VARCHAR(255),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMP,
    PRIMARY KEY (product_id, product_version_id)
);

CREATE INDEX idx_product_cross_sell_options_deleted_at ON catalog.product_cross_sell_options (deleted_at);

CREATE TABLE catalog.product_alternatives
(
    product_id             BIGINT REFERENCES catalog.products (id),
    alternative_product_id BIGINT REFERENCES catalog.products (id),
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at             TIMESTAMP,
    PRIMARY KEY (product_id, alternative_product_id)
);

CREATE INDEX idx_product_alternatives_deleted_at ON catalog.product_alternatives (deleted_at);

CREATE TABLE catalog.assets
(
    id         BIGINT PRIMARY KEY,
    kind       VARCHAR(50),
    format     VARCHAR(10),
    size       VARCHAR(10),
    path       VARCHAR(255),
    alt        VARCHAR(255),
    width      INT,
    height     INT,
    weight     INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_assets_deleted_at ON catalog.assets (deleted_at);

CREATE TABLE catalog.category_assets
(
    category_id BIGINT REFERENCES catalog.categories (id),
    asset_id    BIGINT REFERENCES catalog.assets (id),
    placement   VARCHAR(50),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP,
    PRIMARY KEY (category_id, asset_id)
);

CREATE INDEX idx_category_assets_deleted_at ON catalog.category_assets (deleted_at);

CREATE TABLE catalog.product_assets
(
    product_id BIGINT REFERENCES catalog.products (id),
    asset_id   BIGINT REFERENCES catalog.assets (id),
    placement  VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    PRIMARY KEY (product_id, asset_id)
);

CREATE INDEX idx_product_assets_deleted_at ON catalog.product_assets (deleted_at);

CREATE TABLE catalog.product_version_assets
(
    product_version_id BIGINT REFERENCES catalog.product_versions (id),
    asset_id           BIGINT REFERENCES catalog.assets (id),
    placement          VARCHAR(50),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMP,
    PRIMARY KEY (product_version_id, asset_id)
);

CREATE INDEX idx_product_version_assets_deleted_at ON catalog.product_version_assets (deleted_at);

CREATE TABLE catalog.product_reviews
(
    id                  BIGINT PRIMARY KEY,
    product_id          BIGINT REFERENCES catalog.products (id),
    product_version_id  BIGINT REFERENCES catalog.product_versions (id),
    invoice_id          BIGINT,
    physical_product_id BIGINT,
    rating              INT,
    review              TEXT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT,
    deleted_at          TIMESTAMP,
    deleted_by          BIGINT
);

CREATE INDEX idx_product_reviews_deleted_at ON catalog.product_reviews (deleted_at);

CREATE TABLE catalog.product_review_assets
(
    product_review_id BIGINT REFERENCES catalog.product_reviews (id),
    asset_id          BIGINT REFERENCES catalog.assets (id),
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        BIGINT,
    deleted_at        TIMESTAMP,
    deleted_by        BIGINT,
    PRIMARY KEY (product_review_id, asset_id)
);

CREATE INDEX idx_product_review_assets_deleted_at ON catalog.product_review_assets (deleted_at);

CREATE TABLE catalog.product_review_feedbacks
(
    product_review_id BIGINT REFERENCES catalog.product_reviews (id),
    kind              VARCHAR(50),
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        BIGINT,
    deleted_at        TIMESTAMP,
    deleted_by        BIGINT,
    PRIMARY KEY (product_review_id, created_by, kind)
);

CREATE INDEX idx_product_review_feedbacks_deleted_at ON catalog.product_review_feedbacks (deleted_at);


-- insert some data
INSERT INTO catalog.categories (id, parent, depth, slug, name, description, description_html)
VALUES (1, NULL, 0, 'electronics', 'Electronics', 'All electronic items', '<p>All electronic items</p>'),
       (2, 1, 1, 'phones', 'Phones', 'All kinds of phones', '<p>All kinds of phones</p>');

INSERT INTO catalog.products (id, slug, name, category_id, description, description_html, versions, attributes, stock)
VALUES (1, 'pixel-8-pro', 'Pixel 8 Pro', 2, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[{"key": "color", "label": "Couleur", "values": [{"name": "Bleu Azur", "value": "#95bbe2"}]}, {"key": "storage", "label": "Taille", "values": [{"name": "128GB", "value": 128}]}]', '[{"key": "Marque", "value": "Google"}]', 100),
       (2, 'iphone-14', 'iPhone 14', 2, 'The latest iPhone by Apple', '<p>The latest iPhone by Apple</p>', '[{"key": "color", "label": "Couleur", "values": [{"name": "Noir", "value": "#000000"}]}, {"key": "storage", "label": "Taille", "values": [{"name": "256GB", "value": 256}]}]', '[{"key": "Marque", "value": "Apple"}]', 50);

INSERT INTO catalog.product_versions (id, product_id, name, specs, price, stock)
VALUES (1, 1, 'Pixel 8 Pro Menthe 128 Go', '{"color": "Menthe", "storage": 128}', 899.99, 50),
       (2, 2, 'iPhone 14 Noir 256 Go', '{"color": "Noir", "storage": 256}', 1099.99, 25);

INSERT INTO catalog.product_cross_sell_options (product_id, product_version_id, label)
VALUES (1, 2, 'Buy with iPhone 14 case'),
       (2, 1, 'Buy with Pixel 8 Pro case');

INSERT INTO catalog.product_alternatives (product_id, alternative_product_id)
VALUES (1, 2),
       (2, 1);

INSERT INTO catalog.assets (id, kind, format, size, path, alt, width, height, weight)
VALUES (1, 'picture', '1:1', 'high', '/images/pixel-8-pro.png', 'Pixel 8 Pro Image', 1024, 1024, 500),
       (2, 'picture', '1:1', 'high', '/images/iphone-14.png', 'iPhone 14 Image', 1024, 1024, 500);

INSERT INTO catalog.category_assets (category_id, asset_id, placement)
VALUES (1, 1, 'banner'),
       (2, 2, 'icon');

INSERT INTO catalog.product_assets (product_id, asset_id, placement)
VALUES (1, 1, 'banner'),
       (2, 2, 'icon');

INSERT INTO catalog.product_version_assets (product_version_id, asset_id, placement)
VALUES (1, 1, 'banner'),
       (2, 2, 'icon');

INSERT INTO catalog.product_reviews (id, product_id, product_version_id, rating, review, created_by, updated_by)
VALUES (1, 1, 1, 5, 'Amazing phone!', 1, 1),
       (2, 2, 2, 4, 'Great, but too expensive.', 2, 2);

INSERT INTO catalog.product_review_assets (product_review_id, asset_id, created_by)
VALUES (1, 1, 1),
       (2, 2, 2);

INSERT INTO catalog.product_review_feedbacks (product_review_id, kind, created_by)
VALUES (1, 'like', 1),
       (2, 'report', 2);
