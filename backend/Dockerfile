# Multi-stage build para otimizar a imagem final
FROM node:22-alpine AS builder

WORKDIR /app

# Copiar package.json e package-lock.json
COPY package*.json ./

# Instalar todas as dependências (incluindo devDependencies)
RUN npm ci

# Copiar código fonte
COPY . .

# Gerar Prisma client antes do build (Prisma está em devDependencies)
RUN npm exec prisma generate || true

# Fazer build da aplicação
RUN npm run build

# Estágio final - imagem de produção
FROM node:22-alpine AS production

WORKDIR /app

# Copiar apenas package.json e package-lock.json
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm ci --only=production && npm cache clean --force

# Copiar arquivos compilados do estágio anterior
COPY --from=builder /app/dist ./dist

# Copiar Prisma client gerado pelo builder para a imagem de produção
# Isso garante que @prisma/client encontre os artefatos gerados em runtime
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma/client ./node_modules/@prisma/client

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs
RUN adduser -S pokegentrade -u 1001

# Mudar propriedade dos arquivos para o usuário pokegentrade
RUN chown -R pokegentrade:nodejs /app
USER pokegentrade

# Expor porta
EXPOSE 3000

# Variáveis de ambiente
ENV NODE_ENV=production
ENV PORT=3000

# Prisma client already generated in builder stage. Do not run `prisma generate` or `prisma db push` during production image build.

# Comando para iniciar a aplicação
CMD ["npm", "run", "start"]