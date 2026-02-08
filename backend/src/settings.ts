const settings = {
    CORS_ORIGIN: process.env.CORS_ORIGIN ? (process.env.CORS_ORIGIN === 'true' ? true : process.env.CORS_ORIGIN) : true,
    PORT: process.env.PORT ? Number(process.env.PORT) : 3000,
    JWT_SECRET: process.env.JWT_SECRET || 'changeme',
    JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'changeme',
    ADMIN_EMAIL: process.env.ADMIN_EMAIL || "admin@poketibia.local",
    ADMIN_PASSWORD: process.env.ADMIN_PASSWORD || "ChangeMe!123",
    ADMIN_NAME: process.env.ADMIN_NAME || "Super Admin",
    UPLOAD_MODE: process.env.UPLOAD_MODE || "", // or "s3"
    FILES_UPLOAD_DIR: process.env.FILES_UPLOAD_DIR || "uploads",
    S3_BUCKET: process.env.S3_BUCKET || "uploads",
    S3_SECRET_KEY: process.env.S3_ACCESS_KEY_SECRET || "minioadmin",
    S3_ACCESS_KEY: process.env.S3_ACCESS_KEY || "minioadmin",
    S3_ENDPOINT: process.env.S3_ENDPOINT || "http://localhost:9000",
    REDIS_HOST: process.env.REDIS_HOST || 'localhost',
    REDIS_PORT: process.env.REDIS_PORT ? Number(process.env.REDIS_PORT) : 6379,
}

export default settings;