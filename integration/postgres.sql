DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS order_lines;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS carts;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE users
(
    id    uuid PRIMARY KEY,
    name  varchar NOT NULL,
    email varchar NOT NULL UNIQUE
);

CREATE TABLE categories
(
    id     uuid PRIMARY KEY,
    parent uuid    REFERENCES categories (id),
    slug   varchar NOT NULL UNIQUE,
    name   varchar NOT NULL
);


CREATE TABLE products
(
    id          uuid PRIMARY KEY,
    category_id uuid    NOT NULL REFERENCES categories (id),
    name        varchar NOT NULL
);


CREATE TABLE carts
(
    id         uuid PRIMARY KEY,
    created_by uuid      NOT NULL REFERENCES users (id),
    created_at timestamp NOT NULL,
    updated_at timestamp NOT NULL
);
COMMENT ON TABLE carts IS 'temporary saves what users want to buy';

CREATE TABLE cart_items
(
    cart_id    uuid REFERENCES carts (id),
    product_id uuid REFERENCES products (id),
    price      decimal   NOT NULL,
    quantity   int       NOT NULL CHECK (quantity > 0),
    created_at timestamp NOT NULL,
    updated_at timestamp NOT NULL,
    PRIMARY KEY (cart_id, product_id)
);
COMMENT ON COLUMN cart_items.price IS 'unitary price';
COMMENT ON COLUMN cart_items.quantity IS 'should be checked with stock at buy time';


CREATE TABLE orders
(
    id         uuid PRIMARY KEY,
    created_by uuid      NOT NULL REFERENCES users (id),
    created_at timestamp NOT NULL
);

CREATE TABLE order_lines
(
    order_id   uuid    NOT NULL REFERENCES orders (id),
    product_id uuid    NOT NULL REFERENCES products (id),
    price      decimal NOT NULL,
    quantity   int     NOT NULL CHECK (quantity > 0)
);
COMMENT ON COLUMN order_lines.price IS 'unitary price';
COMMENT ON COLUMN order_lines.quantity IS 'should be checked with stock at buy time';

CREATE TABLE events
(
    id         uuid PRIMARY KEY,
    name       varchar   NOT NULL,
    item_type  varchar   NOT NULL,
    item_id    uuid      NOT NULL,
    details    json      NOT NULL,
    created_by uuid      NOT NULL,
    created_at timestamp NOT NULL
);


INSERT INTO users (id, name, email)
VALUES ('e7a47f0f-a2b1-44fa-aa86-c9f4dba6fa73', 'Loïc', 'loic@azimutt.app'),
       ('54e48db0-8740-46be-b1dc-301832fe6a5d', 'Samir', 'samir@azimutt.app'),
       ('add7502f-47fe-4870-9b9f-0c0c73e65b8b', 'Azimutt admin', 'admin@azimutt.app'),
       ('fa551c9e-d9b7-42a3-96d5-af6723f1c467', 'Azimutt contact', 'contact@azimutt.app'),
       ('0b48b4b3-ae00-4623-bec6-e66ae791414c', 'Claude', 'claude@example.com'),
       ('5301f6c8-4259-4122-bb4b-e2378065f88c', 'Lise', 'lise@example.com');

INSERT INTO categories (id, parent, slug, name)
VALUES ('50c33d85-559a-44ea-b745-fad5aad7d062', null, 'electronics', 'Electronics'),
       ('e62c89f7-6278-49ba-9c3c-2a2f60bbf3b4', '50c33d85-559a-44ea-b745-fad5aad7d062', 'accessories-supplies', 'Accessories & Supplies'),
       ('0084e8e3-a12c-4ea5-b004-ec3e8b4573db', 'e62c89f7-6278-49ba-9c3c-2a2f60bbf3b4', 'camera-photo-accessories', 'Camera & Photo Accessories'),
       ('8098c34d-2931-4510-9d2f-779d0fe69266', 'e62c89f7-6278-49ba-9c3c-2a2f60bbf3b4', 'cell-phone-accessories', 'Cell Phone Accessories'),
       ('fc5d586d-6f6d-4afc-936f-1564ea6788f9', 'e62c89f7-6278-49ba-9c3c-2a2f60bbf3b4', 'telephone-accessories', 'Telephone Accessories'),
       ('91f2ca95-1137-4c81-89fb-f62379c552ec', 'e62c89f7-6278-49ba-9c3c-2a2f60bbf3b4', 'cables', 'Cables'),
       ('e4bb31df-18f7-4272-8f10-ca519c15cc51', 'e62c89f7-6278-49ba-9c3c-2a2f60bbf3b4', 'microphones', 'Microphones'),
       ('cae0b67b-08f4-48b9-bd97-093673550fe7', null, 'computers', 'Computers'),
       ('3283049d-9740-4e39-b2e9-d8f0ecaf63f3', 'cae0b67b-08f4-48b9-bd97-093673550fe7', 'data-storage', 'Data Storage'),
       ('f47b15e8-2ae5-41f4-9338-c472caa5584b', '3283049d-9740-4e39-b2e9-d8f0ecaf63f3', 'external-hard-drives', 'External Hard Drives'),
       ('db3b50fa-1076-48a6-b7c6-b17e464f1751', '3283049d-9740-4e39-b2e9-d8f0ecaf63f3', 'usb-flash-drives', 'USB Flash Drives'),
       ('c5a7b1f3-2933-45ef-8345-4755417959aa', null, 'arts-crafts', 'Arts & Crafts'),
       ('03a9dc3f-b15a-4e94-baa1-43c76863f38f', 'c5a7b1f3-2933-45ef-8345-4755417959aa', 'floral-arranging', 'Floral Arranging'),
       ('dfd8acea-baa9-471b-8a41-412fdc2865a4', 'c5a7b1f3-2933-45ef-8345-4755417959aa', 'woodcrafts', 'Woodcrafts'),
       ('1899869f-ae62-4978-965b-61eb22da9895', null, 'software', 'Software'),
       ('b58366b6-b571-4cbc-86dc-4e8be14a082f', '1899869f-ae62-4978-965b-61eb22da9895', 'utilities', 'Utilities'),
       ('47804682-deeb-45a1-82ef-fa49792246bd', 'b58366b6-b571-4cbc-86dc-4e8be14a082f', 'internet-utilities', 'Internet Utilities'),
       ('73835bef-b948-42de-aaf8-ab10ca469b45', '1899869f-ae62-4978-965b-61eb22da9895', 'photography-graphic-design', 'Photography & Graphic Design'),
       ('c68aab30-6052-47da-bece-3e4fac896099', null, 'video-games', 'Video Games');

INSERT INTO products (id, category_id, name)
VALUES ('407ae0e1-eee2-4513-a753-7bb557694af9', '73835bef-b948-42de-aaf8-ab10ca469b45', 'Adobe Photoshop Elements 2023'),
       ('55334065-0cf8-4016-afc4-ce120ec8afc1', '73835bef-b948-42de-aaf8-ab10ca469b45', 'Clip Studio Paint Pro'),
       ('34e0a39a-1bc1-4ec5-99bd-d340ed8d4550', '73835bef-b948-42de-aaf8-ab10ca469b45', 'Corel PaintShop Pro 2023 Ultimate'),
       ('dbfad459-bf8e-4d97-917c-6e4e74277509', '73835bef-b948-42de-aaf8-ab10ca469b45', 'Nero Standard 2018'),
       ('81ec90c8-48e0-4fd9-888b-5824300a98e7', '73835bef-b948-42de-aaf8-ab10ca469b45', 'Adobe Premiere Elements 2023');

INSERT INTO events (id, name, item_type, item_id, details, created_by, created_at)
VALUES ('730a110f-9dc1-41c3-a48a-c8442e36fd16', 'user_created', 'User', 'add7502f-47fe-4870-9b9f-0c0c73e65b8b', '{"name": "Admin"}', 'add7502f-47fe-4870-9b9f-0c0c73e65b8b', '2023-09-01 12:12:12-07'),
       ('1d5619fe-a2a8-4c07-9243-b6f0c27ab64f', 'user_created', 'User', 'e7a47f0f-a2b1-44fa-aa86-c9f4dba6fa73', '{"name": "Loïc"}', 'e7a47f0f-a2b1-44fa-aa86-c9f4dba6fa73', '2023-09-01 18:05:25-07'),
       ('8e555622-44d6-41f0-90f8-38e22c43ea66', 'category_created', 'Category', '1899869f-ae62-4978-965b-61eb22da9895', '{}', 'e7a47f0f-a2b1-44fa-aa86-c9f4dba6fa73', '2023-09-01 19:21:42-07'),
       ('d0f4e0de-4b6b-42ac-941b-7c3bc563a828', 'product_created', 'Product', '407ae0e1-eee2-4513-a753-7bb557694af9', '{"source": "web"}', 'e7a47f0f-a2b1-44fa-aa86-c9f4dba6fa73', '2023-09-01 19:32:58-07');
