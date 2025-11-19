import mongoose from "mongoose";

const courseSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    number: { type: String, required: true },
    startDate: String,
    endDate: String,
    department: String,
    credits: Number,
    description: String,
    image: String,
  },
  { collection: "courses" }
);

export default courseSchema;
