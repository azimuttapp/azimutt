FROM node:18-alpine AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile

FROM node:18-alpine AS builder
ARG APP_ENV
WORKDIR /app
COPY . .
COPY .env.$APP_ENV .env
COPY --from=deps /app/node_modules ./node_modules
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /usr/app
ARG APP_ENV
COPY --from=builder /app/build ./build
COPY package.json ./
COPY .env.$APP_ENV .env
RUN npm install -g pnpm
RUN pnpm install --prod
USER node
ENV NODE_ENV="production"
CMD ["npm", "start"]
