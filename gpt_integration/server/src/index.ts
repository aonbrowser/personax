import { app } from './routes/index.js';
import { ENV } from './config/env.js';
app.listen(ENV.PORT, ()=> console.log('listening on', ENV.PORT));
