import mongoose from "mongoose";
import { envConfig } from "./envConfig";

export const connectDB = async () => {
  try {
    await mongoose.connect(envConfig.mongo.uri, {
      dbName: envConfig.mongo.dbName,
    });
    console.log("Connected to MongoDB");
  } catch (error) {
    console.error("MongoDB connection error:", error);
    process.exit(1);
  }
};
