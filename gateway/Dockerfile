FROM node:18-slim AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install

FROM node:18-slim AS builder
ARG APP_ENV
WORKDIR /app
COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN npm run build

FROM node:18-slim AS runner
WORKDIR /usr/app
ARG APP_ENV
COPY --from=builder /app/out ./
COPY package.json package-lock.json ./
RUN npm install --prod
USER node
ENV NODE_ENV="production"
CMD ["node", "start.js"]
