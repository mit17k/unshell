# syntax=docker/dockerfile:1.7
FROM node:24-slim AS build
WORKDIR /app

ENV PNPM_HOME=/pnpm PATH="/pnpm:$PATH"
RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/unshell-api/package.json apps/unshell-api/
RUN --mount=type=cache,target=/pnpm/store pnpm install --frozen-lockfile

COPY . .
RUN pnpm --filter unshell-api build

FROM gcr.io/distroless/nodejs24-debian12
COPY --from=build /app/apps/unshell-api/dist /srv
EXPOSE 4317
USER nonroot
HEALTHCHECK --interval=30s CMD ["node", "/srv/healthcheck.js"]
CMD ["/srv/index.js"]
