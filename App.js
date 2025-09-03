import express from 'express'
import Hello from "./Hello.js"
import AssignmentRoutes from "./Kanbas/Assignments/routes.js";
import CourseRoutes from "./Kanbas/Courses/routes.js";
import ModuleRoutes from "./Kanbas/Modules/routes.js";
import UserRoutes from "./Users/routes.js";
import Lab5 from "./Lab5/index.js";
import cors from "cors";
import mongoose from "mongoose";
import "dotenv/config";

const CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING || "mongodb://127.0.0.1:27017/kanbas";
mongoose.connect(CONNECTION_STRING);

const app = express();
app.use(cors());
app.use(express.json());
UserRoutes(app);
AssignmentRoutes(app);
ModuleRoutes(app);
CourseRoutes(app);
Lab5(app);
Hello(app);
app.listen(process.env.PORT || 4000)
