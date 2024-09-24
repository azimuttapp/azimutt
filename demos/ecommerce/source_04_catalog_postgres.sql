-- drop then create the database
DROP SCHEMA IF EXISTS catalog CASCADE;
CREATE SCHEMA catalog;


-- database schema
CREATE TABLE catalog.categories (
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
COMMENT ON COLUMN catalog.categories.depth IS 'easily accessible information of number of parents';

CREATE TABLE catalog.products (
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
COMMENT ON COLUMN catalog.products.description IS 'TODO: handle i18n';
COMMENT ON COLUMN catalog.products.versions IS 'ex: `[{key: "color", label: "Couleur", values: [{name: "Bleu Azur", value: "#95bbe2"}]}, {key: "storage", name: "Taille", values: [{name: "128GB", value: 128}]}]`';
COMMENT ON COLUMN catalog.products.attributes IS 'ex: `[{key: "Marque", value: "Google"}]`';
COMMENT ON COLUMN catalog.products.stock IS 'informative stock, may not be accurate';

CREATE TABLE catalog.product_versions (
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
COMMENT ON COLUMN catalog.product_versions.specs IS 'ex: `{color: "Bleu Azur", storage: 128}`';
COMMENT ON COLUMN catalog.product_versions.stock IS 'informative stock, may not be accurate';

CREATE TABLE catalog.product_cross_sell_options (
    product_id         BIGINT REFERENCES catalog.products (id),
    product_version_id BIGINT REFERENCES catalog.product_versions (id),
    label              VARCHAR(255),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMP,
    PRIMARY KEY (product_id, product_version_id)
);
CREATE INDEX idx_product_cross_sell_options_deleted_at ON catalog.product_cross_sell_options (deleted_at);

CREATE TABLE catalog.product_alternatives (
    product_id             BIGINT REFERENCES catalog.products (id),
    alternative_product_id BIGINT REFERENCES catalog.products (id),
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at             TIMESTAMP,
    PRIMARY KEY (product_id, alternative_product_id)
);
CREATE INDEX idx_product_alternatives_deleted_at ON catalog.product_alternatives (deleted_at);

CREATE TABLE catalog.assets (
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

CREATE TABLE catalog.category_assets (
    category_id BIGINT REFERENCES catalog.categories (id),
    asset_id    BIGINT REFERENCES catalog.assets (id),
    placement   VARCHAR(50),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP,
    PRIMARY KEY (category_id, asset_id)
);
CREATE INDEX idx_category_assets_deleted_at ON catalog.category_assets (deleted_at);

CREATE TABLE catalog.product_assets (
    product_id BIGINT REFERENCES catalog.products (id),
    asset_id   BIGINT REFERENCES catalog.assets (id),
    placement  VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    PRIMARY KEY (product_id, asset_id)
);
CREATE INDEX idx_product_assets_deleted_at ON catalog.product_assets (deleted_at);

CREATE TABLE catalog.product_version_assets (
    product_version_id BIGINT REFERENCES catalog.product_versions (id),
    asset_id           BIGINT REFERENCES catalog.assets (id),
    placement          VARCHAR(50),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMP,
    PRIMARY KEY (product_version_id, asset_id)
);
CREATE INDEX idx_product_version_assets_deleted_at ON catalog.product_version_assets (deleted_at);

CREATE TABLE catalog.product_reviews (
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

CREATE TABLE catalog.product_review_assets (
    product_review_id BIGINT REFERENCES catalog.product_reviews (id),
    asset_id          BIGINT REFERENCES catalog.assets (id),
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        BIGINT,
    deleted_at        TIMESTAMP,
    deleted_by        BIGINT,
    PRIMARY KEY (product_review_id, asset_id)
);
CREATE INDEX idx_product_review_assets_deleted_at ON catalog.product_review_assets (deleted_at);

CREATE TABLE catalog.product_review_feedbacks (
    product_review_id BIGINT REFERENCES catalog.product_reviews (id),
    kind              VARCHAR(50),
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by        BIGINT,
    deleted_at        TIMESTAMP,
    deleted_by        BIGINT,
    PRIMARY KEY (product_review_id, created_by, kind)
);
CREATE INDEX idx_product_review_feedbacks_deleted_at ON catalog.product_review_feedbacks (deleted_at);


-- database data
INSERT INTO catalog.categories (id, parent, depth, slug, name, description, description_html)
VALUES (1, NULL, 0, 'electronics', 'Electronics', 'All electronic items', '<p>All electronic items</p>'),
       (2, 1, 1, 'phones', 'Phones', 'All kinds of phones', '<p>All kinds of phones</p>'),
       (3, 2, 2, 'smartphones', 'SmartPhones', 'Most advanced phones', '<p>Most advanced phones</p>'),
       (4, 1, 1, 'accessories', 'Accessories', 'Useful accessories', '<p>Useful accessories</p>');

INSERT INTO catalog.products (id, slug, name, category_id, description, description_html, versions, attributes, stock)
VALUES (1, 'pixel-8', 'Pixel 8', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[{"key": "color", "label": "Color", "values": [{"name": "Obsidian", "value": "#202020"}, {"name": "Hazel", "value": "#8B8D8B"}, {"name": "Rose", "value": "#F1DDD2"}, {"name": "Mint", "value": "#DDF2E5"}]}, {"key": "storage", "label": "Storage", "values": [{"name": "128 GB", "value": 128}, {"name": "256 GB", "value": 256}]}]', '[{"key": "Brand", "value": "Google"}, {"key": "Screen size", "value": "6,2\""}, {"key": "RAM", "value": "8 Go"}, {"key": "Weight", "value": "187 g"}]', 11),
       (2, 'pixel-8-pro', 'Pixel 8 Pro', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[]', '[]', 9),
       (3, 'pixel-8a', 'Pixel 8a', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[]', '[]', 0),
       (4, 'pixel-9', 'Pixel 9', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[]', '[]', 0),
       (5, 'pixel-9-pro', 'Pixel 9 Pro', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[]', '[]', 0),
       (6, 'pixel-9-pro-xl', 'Pixel 9 Pro XL', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[]', '[]', 0),
       (7, 'pixel-9-pro-fold', 'Pixel 9 Pro Fold', 3, 'A high-end smartphone by Google', '<p>A high-end smartphone by Google</p>','[]', '[]', 0),
       (8, 'pixel-8-case', 'Pixel 8 Case', 4, 'Protect your phone with class!', '<p>Protect your phone with class!</p>','[]', '[]', 5),
       (9, 'pixel-8-casemate-signature', 'Pixel 8 Case Signature', 4, 'Protect your phone with class!', '<p>Protect your phone with class!</p>','[]', '[]', 3);

INSERT INTO catalog.product_versions (id, product_id, name, specs, price, stock)
VALUES (1, 1, 'Pixel 8 Obsidian 128 Go', '{"color": "Obsidian", "storage": 128}', 599, 2),
       (2, 1, 'Pixel 8 Obsidian 256 Go', '{"color": "Obsidian", "storage": 256}', 659, 1),
       (3, 1, 'Pixel 8 Hazel 128 Go', '{"color": "Hazel", "storage": 128}', 599, 2),
       (4, 1, 'Pixel 8 Hazel 256 Go', '{"color": "Hazel", "storage": 256}', 659, 0),
       (5, 1, 'Pixel 8 Rose 128 Go', '{"color": "Rose", "storage": 128}', 599, 2),
       (6, 1, 'Pixel 8 Rose 256 Go', '{"color": "Rose", "storage": 256}', 659, 0),
       (7, 1, 'Pixel 8 Mint 128 Go', '{"color": "Mint", "storage": 128}', 599, 2),
       (8, 2, 'Pixel 8 Pro Obsidian 128 Go', '{"color": "Obsidian", "storage": 128}', 899, 3),
       (9, 2, 'Pixel 8 Pro Obsidian 256 Go', '{"color": "Obsidian", "storage": 256}', 959, 1),
       (10, 2, 'Pixel 8 Pro Obsidian 512 Go', '{"color": "Obsidian", "storage": 512}', 1099, 1),
       (11, 2, 'Pixel 8 Pro Bay 128 Go', '{"color": "Bay", "storage": 128}', 899, 1),
       (12, 2, 'Pixel 8 Pro Bay 256 Go', '{"color": "Bay", "storage": 256}', 959, 1),
       (13, 2, 'Pixel 8 Pro Porcelain 128 Go', '{"color": "Porcelain", "storage": 128}', 899, 1),
       (14, 2, 'Pixel 8 Pro Porcelain 256 Go', '{"color": "Porcelain", "storage": 256}', 959, 1),
       (15, 8, 'Pixel 8 Case Hazel', '{"color": "Hazel"}', 35, 2),
       (16, 8, 'Pixel 8 Case Coral', '{"color": "Coral"}', 35, 2),
       (17, 8, 'Pixel 8 Case Mint', '{"color": "Mint"}', 35, 0),
       (18, 8, 'Pixel 8 Case Rose', '{"color": "Rose"}', 35, 0),
       (19, 8, 'Pixel 8 Case Charcoal', '{"color": "Charcoal"}', 35, 0),
       (20, 9, 'Pixel 8 Case Signature Clear', '{}', 30, 2);

INSERT INTO catalog.product_cross_sell_options (product_id, product_version_id, label)
VALUES (1, 15, 'Protect your phone'),
       (1, 20, 'Protect your phone');

INSERT INTO catalog.product_alternatives (product_id, alternative_product_id)
VALUES (1, 2),
       (1, 3),
       (1, 4),
       (2, 1),
       (2, 3),
       (2, 4),
       (3, 1),
       (3, 2),
       (3, 4),
       (4, 1),
       (4, 5),
       (4, 6),
       (4, 7),
       (5, 1),
       (5, 4),
       (5, 6),
       (5, 7),
       (6, 1),
       (6, 4),
       (6, 5),
       (6, 7),
       (7, 1),
       (7, 4),
       (7, 5),
       (7, 6);

INSERT INTO catalog.assets (id, kind, format, size, path, alt, width, height, weight)
VALUES (1, 'picture', '16:9', 'high', '/images/categories/electronics/banner.png', 'Electronics banner', 1600, 900, 500),
       (2, 'picture', '16:9', 'high', '/images/categories/electronics/phones/banner.png', 'Phones banner', 1600, 900, 500),
       (3, 'picture', '16:9', 'high', '/images/categories/electronics/phones/smartphones/banner.png', 'SmartPhones banner', 1600, 900, 500),
       (4, 'picture', '16:9', 'high', '/images/categories/electronics/accessories/banner.png', 'Accessories banner', 1600, 900, 500),
       (5, 'picture', '1:1', 'high', '/images/categories/electronics/icon.png', 'Electronics icon', 150, 150, 345),
       (6, 'picture', '3:4', 'high', '/images/products/pixel-8/obsidian/shot.png', 'Pixel 8 Obsidian shot', 360, 480, 474),
       (7, 'picture', '3:4', 'high', '/images/products/pixel-8/hazel/shot.png', 'Pixel 8 Hazel shot', 360, 480, 474),
       (8, 'picture', '3:4', 'high', '/images/products/pixel-8/rose/shot.png', 'Pixel 8 Rose shot', 360, 480, 474),
       (9, 'picture', '3:4', 'high', '/images/products/pixel-8/mint/shot.png', 'Pixel 8 Mint shot', 360, 480, 474),
       (10, 'picture', '3:4', 'high', '/images/products/pixel-8-pro/obsidian/shot.png', 'Pixel 8 Pro Obsidian shot', 360, 480, 474),
       (11, 'picture', '3:4', 'high', '/images/products/pixel-8-pro/bay/shot.png', 'Pixel 8 Pro Bay shot', 360, 480, 474),
       (12, 'picture', '3:4', 'high', '/images/products/pixel-8-pro/porcelain/shot.png', 'Pixel 8 Pro Porcelain shot', 360, 480, 474),
       (13, 'picture', '3:4', 'high', '/images/products/pixel-8a/shot.png', 'Pixel 8a shot', 360, 480, 474),
       (14, 'picture', '3:4', 'high', '/images/products/pixel-9/shot.png', 'Pixel 9 shot', 360, 480, 474),
       (15, 'picture', '3:4', 'high', '/images/products/pixel-9-pro/shot.png', 'Pixel 9 Pro shot', 360, 480, 474),
       (16, 'picture', '3:4', 'high', '/images/products/pixel-9-pro-xl/shot.png', 'Pixel 9 Pro XL shot', 360, 480, 474),
       (17, 'picture', '3:4', 'high', '/images/products/pixel-9-pro-fold/shot.png', 'Pixel 9 Pro Fold shot', 360, 480, 474),
       (18, 'picture', '3:4', 'high', '/images/products/pixel-8-case/hazel/shot.png', 'Pixel 8 Case Hazel shot', 360, 480, 474),
       (19, 'picture', '3:4', 'high', '/images/products/pixel-8-case/coral/shot.png', 'Pixel 8 Case Coral shot', 360, 480, 474),
       (20, 'picture', '3:4', 'high', '/images/products/pixel-8-case/mint/shot.png', 'Pixel 8 Case Mint shot', 360, 480, 474),
       (21, 'picture', '3:4', 'high', '/images/products/pixel-8-case/rose/shot.png', 'Pixel 8 Case Rose shot', 360, 480, 474),
       (22, 'picture', '3:4', 'high', '/images/products/pixel-8-case/charcoal/shot.png', 'Pixel 8 Case Charcoal shot', 360, 480, 474),
       (23, 'picture', '3:4', 'high', '/images/products/pixel-8-casemate-signature/shot.png', 'Pixel 8 Case Signature shot', 360, 480, 474),
       (24, 'picture', '16:9', 'high', '/uploads/users/102/2024-08-24/9ab74d.jpg', 'User upload', 1280, 720, 12845);

INSERT INTO catalog.category_assets (category_id, asset_id, placement)
VALUES (1, 1, 'banner'),
       (2, 2, 'banner'),
       (3, 3, 'banner'),
       (4, 4, 'banner'),
       (1, 5, 'icon');

INSERT INTO catalog.product_assets (product_id, asset_id, placement)
VALUES (1, 6, 'main'),
       (2, 10, 'main'),
       (3, 13, 'main'),
       (4, 14, 'main'),
       (5, 15, 'main'),
       (6, 16, 'main'),
       (7, 17, 'main'),
       (8, 18, 'main'),
       (9, 23, 'main');

INSERT INTO catalog.product_version_assets (product_version_id, asset_id, placement)
VALUES (1, 6, 'main'),
       (2, 6, 'main'),
       (3, 7, 'main'),
       (4, 7, 'main'),
       (5, 8, 'main'),
       (6, 8, 'main'),
       (7, 9, 'main'),
       (8, 10, 'main'),
       (9, 10, 'main'),
       (10, 10, 'main'),
       (11, 11, 'main'),
       (12, 11, 'main'),
       (13, 12, 'main'),
       (14, 12, 'main'),
       (15, 18, 'main'),
       (16, 19, 'main'),
       (17, 20, 'main'),
       (18, 21, 'main'),
       (19, 22, 'main'),
       (20, 23, 'main');

INSERT INTO catalog.product_reviews (id, product_id, product_version_id, invoice_id, physical_product_id, rating, review, created_by, updated_by)
VALUES (1, 1, 1, 1, 1, 5, 'Amazing phone!', 102, 102),
       (2, 2, 2, 1, 4, 4, 'Great, but too expensive.', 103, 103);

INSERT INTO catalog.product_review_assets (product_review_id, asset_id, created_by)
VALUES (1, 24, 102);

INSERT INTO catalog.product_review_feedbacks (product_review_id, kind, created_by)
VALUES (1, 'like', 104),
       (2, 'report', 105);
