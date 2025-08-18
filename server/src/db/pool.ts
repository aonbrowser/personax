import { ENV } from '../config/env.js';
import pg from 'pg';
export const pool = new pg.Pool({ connectionString: ENV.DATABASE_URL });
