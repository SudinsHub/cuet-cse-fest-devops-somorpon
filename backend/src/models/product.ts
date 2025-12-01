import mongoose from "mongoose";
import { Product } from "../types";

export type ProductDocument = mongoose.Document & Product;

const ProductSchema = new mongoose.Schema<ProductDocument>(
  {
    name: { type: String, required: true, trim: true },
    price: { type: Number, required: true, min: 0 },
  },
  { timestamps: true }
);

export const ProductModel = mongoose.model<ProductDocument>(
  "Product",
  ProductSchema
);
