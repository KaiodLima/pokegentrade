# Multi-stage build para otimizar a imagem final
FROM node:22-alpine AS builder

WORKDIR /app

# Copiar package.json e package-lock.json
COPY package*.json ./

# Instalar todas as dependências (incluindo devDependencies)
RUN npm ci

# Copiar código fonte
COPY . .

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

# Talvez gerar o banco
RUN npm exec prisma generate
RUN npm exec prisma db push

# Comando para iniciar a aplicação
CMD ["npm", "run", "start"]