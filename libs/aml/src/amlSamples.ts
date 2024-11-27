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
`},
    ecommerce: {name: 'E-commerce', content: 'TODO'},
    exhaustive: {name: 'All features', content: 'TODO'},
}
