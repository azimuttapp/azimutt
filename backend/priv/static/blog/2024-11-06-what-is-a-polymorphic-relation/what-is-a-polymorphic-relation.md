---
title: What is a polymorphic relation?
banner: "{{base_link}}/polymorphic-relation-banner.jpg"
excerpt: Learn about polymorphic relations. They dynamically define the referenced table, allowing more flexibility and genericity in your database design. It holds some tradeoffs we will discuss here with examples.
category: database design
keywords: polymorphic relation, database design, database polymorphism, polymorphic associations
author: loic
---

Database design is always a tradeoff game. Knowing common database design patterns, their pros and cons will help you make better choices.

![Polymorphic relations banner]({{base_link}}/polymorphic-relation-banner.jpg)

In this post you will learn how to introduce polymorphism in your database using dynamic relations and when to use it or not to design your database in the best way:

- [Dynamic relations design alternatives](#dynamic-relations-design-alternatives)
  - [Duplicate repositories](#solution-1-duplicate-repositories)
  - [Dedicated relation tables](#solution-2-dedicated-relation-tables)
  - [Multiple relations](#solution-3-multiple-relations)
  - [Polymorphic relation](#solution-4-polymorphic-relation)
- [When to use a polymorphic relation?](#when-to-use-a-polymorphic-relation)
- [Polymorphic relation use cases](#polymorphic-relation-use-cases)
- [Polymorphic relation support](#polymorphic-relation-support)
- [Conclusion](#conclusion)

**Polymorphic relations**, sometimes called polymorphic associations, are a way to create a relation with a dynamically referenced table. Wait, what? Let's dive in.

Usual relations are defined by a column in a table referencing another table.
On GitHub, as an example, `users` can create `repositories`. We can then create two tables:

```aml
users
  id uuid pk
  name varchar

repositories
  id uuid pk
  name varchar
  owner uuid -> users(id)
```

[![ERD diagram of a simple database relation between two entities]({{base_link}}/simple-database-relation.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Arepositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner%20uuid%20-%3E%20users(id)%0A)

Easy. Now, let's introduce `organizations`. They can also own `repositories`. But how to design that?

## Dynamic relations design alternatives

- [Duplicate repositories](#solution-1-duplicate-repositories)
- [Dedicated relation tables](#solution-2-dedicated-relation-tables)
- [Multiple relations](#solution-3-multiple-relations)
- [Polymorphic relation](#solution-4-polymorphic-relation)


### Solution 1: Duplicate repositories

A first solution could be to duplicate the `repositories` table for each owning entity:

```aml
users
  id uuid pk
  name varchar

user_repositories
  id uuid pk
  name varchar
  owner uuid -> users(id)

organizations
  id uuid pk
  name varchar

organization_repositories
  id uuid pk
  name varchar
  owner uuid -> organizations(id)
```

[![ERD diagram of a duplicated entities]({{base_link}}/duplicated-entities.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Auser_repositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner%20uuid%20-%3E%20users(id)%0A%0Aorganizations%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aorganization_repositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner%20uuid%20-%3E%20organizations(id)%0A)

It works. Now, imagine you have more and more kind of repository owners. It will be painful to create new repositories tables for each one.  
Worse, if you want to add, change or update a column on `repositories`, you will have to do it for each one.
Keeping them all consistent as they represent the same entity will be a challenge.  
Even worse, you have two tables and thus two primary keys instead of one, allowing the same `id`, breaking the domain intention to one repository entity linked to either a user or an organization.  
Worst of all, if you have entities related to repositories, for example, projects or issues, you will have to also duplicate them in order to have the relation to the correct table 😱

[![ERD diagram of a duplicated entities with their hierarchy]({{base_link}}/duplicated-entities-with-hierarchy.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Auser_repositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner%20uuid%20-%3E%20users(id)%0A%0Auser_projects%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20repository%20uuid%20-%3E%20user_repositories(id)%0A%0Auser_issues%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20repository%20uuid%20-%3E%20user_repositories(id)%0A%0Aorganizations%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aorganization_repositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner%20uuid%20-%3E%20organizations(id)%0A%0Aorganization_projects%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20repository%20uuid%20-%3E%20organization_repositories(id)%0A%0Aorganization_issues%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20repository%20uuid%20-%3E%20organization_repositories(id)%0A)

Duplicating the whole hierarchy is not manageable.

### Solution 2: Dedicated relation tables

A better way could be to extract the relation from the repository and only duplicate the relation, not the whole repository:

```aml
users
  id uuid pk
  name varchar

organizations
  id uuid pk
  name varchar

repositories
  id uuid pk
  name varchar

user_repositories
  user_id uuid -> users(id)
  repository_id uuid unique -> repositories(id)

organization_repositories
  organization_id uuid -> organizations(id)
  repository_id uuid unique -> repositories(id)
```

[![ERD diagram of duplicated relations with dedicated tables]({{base_link}}/duplicated-relations-using-dedicated-tables.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aorganizations%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Arepositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Auser_repositories%0A%20%20user_id%20uuid%20-%3E%20users(id)%0A%20%20repository_id%20uuid%20unique%20-%3E%20repositories(id)%0A%0Aorganization_repositories%0A%20%20organization_id%20uuid%20-%3E%20organizations(id)%0A%20%20repository_id%20uuid%20unique%20-%3E%20repositories(id)%0A)

This one is way better: no duplication for repository attributes, and other tables can easily reference a repository, whichever the owner kind 🎉

Still we have to create one relation table for each kind of owner, allowing a repository to be owned by all kind of owner, a user and an organization in this case 🙃  
Finding a repository owner is complex as it requires to query all the relation tables:

```sql
SELECT * FROM (
  (SELECT 'User' AS kind, u.id, u.name
   FROM user_repositories r
     JOIN users u ON r.user_id = u.id
   WHERE r.repository_id = '0192cd29-e5b8-79f9-b36b-0d1a83ce454c')
  UNION ALL
  (SELECT 'Organization' AS kind, o.id, o.name
   FROM organization_repositories r
     JOIN organizations o ON r.organization_id = o.id
   WHERE r.repository_id = '0192cd29-e5b8-79f9-b36b-0d1a83ce454c')
) owners;
```


### Solution 3: Multiple relations

What if we keep the relations inside the `repositories` table, having one per owner kind ? In this case, one and only one should be filled for each repository:

```aml
users
  id uuid pk
  name varchar

organizations
  id uuid pk
  name varchar

repositories
  id uuid pk
  name varchar
  owner_user_id uuid nullable -> users(id)
  owner_organization_id uuid nullable -> organizations(id)
```

[![ERD diagram of multiple relations in the same entity]({{base_link}}/multiple-relations-on-the-same-entity.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aorganizations%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Arepositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner_user_id%20uuid%20nullable%20-%3E%20users(id)%0A%20%20owner_organization_id%20uuid%20nullable%20-%3E%20organizations(id)%0A)

This is probably the best solution so far, it keeps referential integrity and avoid duplication.

The main issues being:

- we should be careful to have one and only one relation filled (ex: `CHECK ((CASE WHEN owner_user_id IS NULL THEN 0 ELSE 1 END + CASE WHEN owner_organization_id IS NULL THEN 0 ELSE 1 END) = 1)`)
- having many kind of owners would be impractical with a lot of mostly empty columns
- adding a new owner kind require a schema update which could be painful depending on your situation


### Solution 4: Polymorphic relation

Now it's time to introduce polymorphic relations: instead of having a column referencing another table and a foreign key enforcing that, a polymorphic relation uses two column:

- one to define the referenced table
- one to store the referencing value

Here is our new database schema:

```aml
users
  id uuid pk
  name varchar

organizations
  id uuid pk
  name varchar

repositories
  id uuid pk
  name varchar
  owner_kind varchar index check(`owner_kind IN ('users', 'organizations')`)
  owner_id uuid index
```

[![ERD diagram of polymorphic relations]({{base_link}}/polymorphic-relation-diagram.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aorganizations%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Arepositories%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%20%20owner_kind%20varchar%20index%20check(%60owner_kind%20IN%20(%27users%27%2C%20%27organizations%27)%60)%0A%20%20owner_id%20uuid%20index%0A%0Arel%20repositories(owner_id)%20-owner_kind%3Dusers%3E%20users(id)%0Arel%20repositories(owner_id)%20-owner_kind%3Dorganizations%3E%20organizations(id)%0A)

As you can see, it's very similar to our initial situation with just the `users` and `repositories`, with just one additional column telling if the relation is toward the `users` table or the `organizations` one.

In [AML](/aml), you can define [polymorphic relations](/docs/aml/relations#polymorphic-relation) with the kind column inside the arrow:

```aml
rel repositories(owner_id) -owner_kind=users> users(id)
rel repositories(owner_id) -owner_kind=organizations> organizations(id)
```


## When to use a polymorphic relation?

As we have seen, [duplicating entities](#solution-1-duplicate-repositories) and [dedicated relation tables](#solution-2-dedicated-relation-tables) are not very good and are not recommended.
Depending on your situation, [multiple relations](#solution-3-multiple-relations) or a [polymorphic relation](#solution-4-polymorphic-relation) can be fine.

**Polymorphic relation** strengths are they allow a large choice number without increasing the schema or querying complexity.
They are also able to allow new relation kind without a schema change.
On the bad side they require the same column type and can't rely on foreign keys, leaving the referential integrity checks to the application.
Also, many tools won't see them making your daily life a bit harder (but not Azimutt 😅).

**Multiple relations** strengths are they keep the referential integrity checks with foreign keys, and they allow target entities with different types (int, bigint, uuid...).
On the other side, they require a schema change to add a new relation and can be painful with a large number of choices.
Also, you will have to make sure to have one and only one filled value.

<p class="lead">If you have a large number of relations, or you need them dynamically, use Polymorphic relations. Otherwise, Multiple relations will keep your schema clearer and safer.</p>


## Polymorphic relation use cases

Polymorphic relations can be used in many situations, they are mostly split in two main buckets:

- **Generic entities** that can be attached to many/any other entities
  - Comments (or Reviews, Ratings, Likes, Notifications...) attached to entities like Posts, Talks, Videos, Products, Courses...
  - Assets (or Files, Pictures, Documents...) attached to entities like Users, Companies, Articles...
- **Relations** with several business alternatives
  - ownership or rights, for several kind of owners and even owned items
  - user events attached to any system entity

For example, I designed a flexible authorization system allowing access to a resource based on the presence of a polymorphic record:

```aml
accesses
  id uuid pk
  owner_kind varchar index check(`owner_kind IN ('users', 'teams', 'organizations')`)
  owner_id uuid index
  resource_kind varchar index check(`resource_kind IN ('posts', 'pages', 'datasource')`)
  resource_id uuid index
  level varchar check(`level IN ('read', 'write')`)
  expire_at timestamp nullable
```

[![Complex ERD diagram of polymorphic relations for access control in database]({{base_link}}/polymorphic-relations-for-database-access-control.jpg)](/create?aml=users%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Ateams%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aorganizations%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aposts%0A%20%20id%20uuid%20pk%0A%20%20title%20varchar%0A%0Apages%0A%20%20id%20uuid%20pk%0A%20%20title%20varchar%0A%0Adatasources%0A%20%20id%20uuid%20pk%0A%20%20name%20varchar%0A%0Aaccesses%0A%20%20id%20uuid%20pk%0A%20%20owner_kind%20varchar%20index%20check(%60owner_kind%20IN%20(%27users%27%2C%20%27teams%27%2C%20%27organizations%27)%60)%0A%20%20owner_id%20uuid%20index%0A%20%20resource_kind%20varchar%20index%20check(%60resource_kind%20IN%20(%27posts%27%2C%20%27pages%27%2C%20%27datasource%27)%60)%0A%20%20resource_id%20uuid%20index%0A%20%20level%20varchar%20check(%60level%20IN%20(%27read%27%2C%20%27write%27)%60)%0A%20%20expire_at%20timestamp%20nullable%0A%0Arel%20accesses(owner_id)%20-owner_kind%3Dorganizations%3E%20organizations(id)%0Arel%20accesses(owner_id)%20-owner_kind%3Dteams%3E%20teams(id)%0Arel%20accesses(owner_id)%20-owner_kind%3Dusers%3E%20users(id)%0A%0Arel%20accesses(resource_id)%20-resource_kind%3Dposts%3E%20posts(id)%0Arel%20accesses(resource_id)%20-resource_kind%3Dpages%3E%20pages(id)%0Arel%20accesses(resource_id)%20-resource_kind%3Ddatasources%3E%20datasources(id)%0A)

Checking valid access is just a simple query:

```sql
SELECT level
FROM accesses
WHERE (owner_kind = 'users' AND owner_id = '0192c543-1dce-76b2-a165-d722218c96f2')
  AND (resource_kind = 'posts' AND resource_id = '0192c543-aabb-7748-bd76-3942b197537d')
  AND (expire_at IS NULL OR expire_at > now());
```

Also, getting all the allowed posts for a user is quite easy:

```sql
SELECT p.id, p.title, a.level
FROM accesses a
  JOIN posts p ON a.resource_kind = 'posts' AND a.resource_id = p.id
WHERE (a.owner_kind = 'users' AND a.owner_id = '0192c543-1dce-76b2-a165-d722218c96f2')
  AND (a.expire_at IS NULL OR a.expire_at > now());
```

And those queries are quite performant with indexes on `(owner_kind, owner_id)` and `(resource_kind, resource_id)`.

## Polymorphic relation support

As this is just a way to organize and query your data, there is no specific requirements from any language or database to use them.

Yet, they may be more or less easy to use. It's relatively common in certain communities and almost unknown in others 😅

Some libraries supporting it natively:

1. [Active Record](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations) (Ruby on Rails):

```ruby
class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Employee < ApplicationRecord
  has_many :pictures, as: :imageable
end

class Product < ApplicationRecord
  has_many :pictures, as: :imageable
end
```

2. [Eloquent](https://laravel.com/docs/11.x/eloquent-relationships#polymorphic-relationships) (Laravel, PHP):

```php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Comment extends Model {
    public function commentable(): MorphTo {
        return $this->morphTo();
    }
}

class Post extends Model {
    public function comments(): MorphMany {
        return $this->morphMany(Comment::class, 'commentable');
    }
}

class Video extends Model {
    public function comments(): MorphMany {
        return $this->morphMany(Comment::class, 'commentable');
    }
}
```

3. [Sequelize](https://sequelize.org/docs/v7/associations/polymorphic-associations) (Node.js):

```ts
class Comment extends Model<InferAttributes<Comment>, InferCreationAttributes<Comment>> {
  declare id: number;

  @Attributes(DataTypes.STRING)
  @NotNull
  declare content: string;

  @Attributes(DataTypes.STRING)
  @NotNull
  declare targetModel: 'article' | 'video';

  @Attributes(DataTypes.INTEGER)
  @NotNull
  declare targetId: number;

  /** Defined by {@link Article#comments} */
  declare article?: NonAttribute<Article>;

  /** Defined by {@link Video#comments} */
  declare video?: NonAttribute<Video>;

  get target(): NonAttribute<Article | Video | undefined> {
    if (this.targetModel === 'article') {
      return this.article;
    } else {
      return this.video;
    }
  }
}
```

## Conclusion

Polymorphic relations are really powerful to introduce some relation flexibility in relational database design, especially for generic entities.
Yet, they should be used carefully as you loose integrity constraints, and it can backfire hard down the road.
Use them wisely 😉

## About Azimutt

[Azimutt](https://azimutt.app) is a SaaS making working with databases much easier.
It's best in class database design and exploration tool, with backed documentation and collaboration.  
If you have issues or friction with your databases, give it a try or [contact us](mailto:contact@azimutt.app), we are always happy to help.

Cheers !
