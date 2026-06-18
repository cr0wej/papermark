FROM node:24-alpine AS base
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json* ./
COPY prisma ./prisma
RUN npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG NEXT_PUBLIC_BASE_URL=http://localhost:3000
ARG NEXTAUTH_URL=http://localhost:3000
ARG NEXT_PUBLIC_APP_BASE_HOST=localhost
ENV NEXT_PUBLIC_BASE_URL=$NEXT_PUBLIC_BASE_URL
ENV NEXTAUTH_URL=$NEXTAUTH_URL
ENV NEXT_PUBLIC_APP_BASE_HOST=$NEXT_PUBLIC_APP_BASE_HOST
ENV NEXT_PUBLIC_WEBHOOK_BASE_HOST=$NEXT_PUBLIC_APP_BASE_HOST
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATABASE_URL=postgresql://placeholder:placeholder@placeholder:5432/placeholder
ENV HANKO_API_KEY=placeholder
ENV NEXT_PUBLIC_HANKO_TENANT_ID=placeholder
ENV NEXT_PUBLIC_HANKO_FRONTEND_SDK_URL=https://cloud.hanko.io
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /app/package.json ./
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma

USER nextjs
EXPOSE 3000
ENV PORT=3000
CMD ["sh", "-c", "npx prisma migrate deploy && npm start"]
