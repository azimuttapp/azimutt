import {openFile} from "./utils";

export async function newAml(): Promise<void> {
    await openFile('aml', `#
# Sample AML
# learn more at https://azimutt.app/aml
#

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
`)
}
