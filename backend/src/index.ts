import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import productsRouter from './routes/products';
import { envConfig } from './config/envConfig';
import { connectDB } from './config/db';

const app = express();

app.use(cors());
app.use(express.json());

// Request logger middleware
app.use((req, _res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

mongoose.set('strictQuery', false);

async function start(): Promise<void> {
  // Register routes first
  app.use('/api/products', productsRouter);
  app.get('/api/health', (_req, res) => res.json({ ok: true }));

  // Connect to database
  await connectDB();

  // Start server
  app.listen(envConfig.port, () => {
    console.log(`Backend listening on port ${envConfig.port}`);
  });
}

start().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

